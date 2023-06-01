include { app_forumScripts } from './forum-source-repository'

process config_import_MeSH {
    publishDir params.configdir

    output:
        path 'import_MeSH.ini'

    """
    tee -a import_MeSH.ini << END
    [DEFAULT]
    upload_file = upload_MeSH.sh
    log_file = dl_MeSH.log
    [MESH]
    version = latest
    ftp = ftp.nlm.nih.gov
    ftp_path_void =  void_1.0.0.ttl
    ftp_path_mesh = /online/mesh/rdf/mesh.nt
    END
    """
}

process build_importMesh {
    conda 'forum-conda-env.yml'
    storeDir params.rdfoutdir
    /*
    publishDir params.rdfoutdir, pattern: "MeSH"
    publishDir params.rdfoutdir, pattern: "upload_MeSH.sh"
    publishDir params.logdir, pattern: "*.log"
    */

    input:
        tuple path(import_MeSH), path(app)
    output:
        path "MeSH"
        path "upload_MeSH.sh"

    """
    python3 -u $app/build/import_MeSH.py --config="$import_MeSH" --out="." --log="."
    """
}

process waitMeSH {
    output: 
        val true
    
    """
    echo "==== Waiting for upload_MeSH.sh ===="
    while [ ! -e ${params.rdfoutdir}/upload_MeSH.sh ]
    do 
        sleep 1
    done
    """
}

process meSHVersion {
    input:
        val ready
    output: stdout
    """
    ls ${params.rdfoutdir}/MeSH/ | tr -d '\r' 
    """
}

workflow forum_mesh() {
    config_import_MeSH().combine(app_forumScripts()) | build_importMesh 
}