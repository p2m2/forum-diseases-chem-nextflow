include { app_forumScripts } from './forum-source-repository'

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
    path = PubChem_InchiKey/inchikey/${pubchemVersion}
    END
    """
}



process build_import_Chemont {
    debug true
    memory '20 GB'
    cpus 8
    executor 'slurm'
    
    conda 'forum-conda-env.yml'
    
    publishDir params.rdfoutdir, pattern: "ClassyFire"
    publishDir params.rdfoutdir, pattern: "upload_Chemont.sh"
    publishDir params.logdir, pattern: "*.log"

    input:
        tuple path(import_Chemont), path(app)
    output:
        path "ClassyFire"
        path "upload_Chemont.sh"
        path "*.log"

    """
    pip install eutils --quiet
    python3 -u $app/build/import_Chemont.py --config="$import_PMID_CID" --out="." --log="."
    """
}


process waitPubChemAndPmidCid {
    input:
        path pubChemInchikeyDir
        path pmidCidPath
    output: 
        val true
    
    """
    echo "==== Waiting for $pubChemInchikeyDir and $pmidCidPath ===="
    while [ ! -e ${pubChemInchikeyDir} ] || [ ! -e ${pmidCidPath} ]; do sleep 1; done
    """
}

/* val ready : waiting for results of waitPubChem process */
process pubchemVersion {
    input:
        val ready
        path pubChemInchikeyDir
    output: stdout
    """
    ls ${pubChemInchikeyDir}/inchikey/
    """
}

workflow forum_Chemont() {
    
    /* dependencies */

    inchikey = Channel.fromPath("${params.rdfoutdir}/PubChem_InchiKey")
    pmidCidPath = Channel.fromPath("${params.rdfoutdir}/PMID_CID/${params.forumRelease}")
    
    waitPubChemAndPmidCid(inchikey,pmidCidPath)

    config_import_Chemont(
        pubchemVersion(waitPubChemAndPmidCid.out,inchikey))
        .combine(app_forumScripts()) 
        | build_import_Chemont
        
}