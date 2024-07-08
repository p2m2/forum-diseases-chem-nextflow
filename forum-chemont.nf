include { app_forumScripts } from './forum-source-repository'
include { pubchemVersion } from './forum-PubChem-min'

process build_import_Chemont {
    debug false
    memory '20 GB'
    cpus 1

    conda 'forum-conda-env.yml'
    storeDir params.rdfoutdir

    input:
        val pubchemDescriptorExist
        path app 
        path(pubChemDescriptorPath

    output:
        path "ClassyFire"
        path "upload_Chemont.sh"
    """
    curl -L https://github.com/lihaoyi/ammonite/releases/download/3.0.0-M2/2.13-3.0.0-M2-bootstrap > amm && chmod +x amm
    amm buildChemontForum.sc . ${params.forumRelease} \$(find ${pubChemDescriptorPath} -name *canSMILES_value_*.ttl*)
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

    build_import_Chemont(waitPubChem(descriptor), app_forumScripts(), descriptor)
    
}
