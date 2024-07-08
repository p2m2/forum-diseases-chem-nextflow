include { app_forumScripts } from './forum-source-repository'
include { pubchemVersion } from './forum-PubChem-min'

/*
process config_import_Chemont {
    publishDir params.configdir

    input:
        val pubchemVersion

    output:
        path 'import_Chemont.ini'

    """
    tee -a import_Chemont.ini << END
    [DEFAULT]
    upload_file = upload_Chemont.sh
    log_dir = Chemont
    [CHEMONT]
    version = ${params.forumRelease}
    n_processes = ${params.chemont.nbprocess}
    [PMID_CID]
    mask = *.ttl.gz
    path = PMID_CID/${params.forumRelease}
    [INCHIKEY]
    mask = pc_inchikey2compound_*.ttl.gz
    path = PubChem_InchiKey/inchikey/${pubchemVersion.trim()}
    END
    """
}



process build_import_Chemont {
    debug false
    memory '20 GB'
    cpus 8

    conda 'forum-conda-env.yml'
    storeDir params.rdfoutdir

    input:
        tuple path(import_Chemont), path(app), path(pubChemInchikeyPath), path(pmidCidPath)
    output:
        path "ClassyFire"
        path "upload_Chemont.sh"

    """
    pip install eutils --quiet
    python3 -u $app/build/import_Chemont.py --config="$import_Chemont" --out="." --log="." > chemont_import.log
    """
}
*/

process build_import_Chemont {
    debug false
    memory '20 GB'
    cpus 1

    conda 'forum-conda-env.yml'
    storeDir params.rdfoutdir

    input:
        path(app), path(pubChemDescriptorPath)
    output:
        path "ClassyFire"
        path "upload_Chemont.sh"
    """
    curl -L https://github.com/lihaoyi/ammonite/releases/download/3.0.0-M2/2.13-3.0.0-M2-bootstrap > amm && chmod +x amm
    amm buildChemontForum.sc . ${params.forumRelease} $(find ${pubChemDescriptorPath} -name *canSMILES_value_*.ttl*)
    """
}

process waitPubChem {
    input:
        path pubChemDescriptorDir
    output: 
        val true
    
    """
    echo "==== Waiting for $pubChemInchikeyDir ===="
    while [ ! -e ${pubChemDescriptorDir} ] ; do sleep 1; done
    """
}

workflow forum_Chemont() {
    
    descriptor = Channel.fromPath("${params.rdfoutdir}/PubChem_Descriptor")

    waitPubChem(descriptor,pmidCidReleasePath)
        .combine(app_forumScripts()) 
        .combine(descriptor) | build_import_Chemont
    
}