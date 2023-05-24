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

    publishDir params.rdfoutdir, pattern: "MeSH"
    publishDir params.rdfoutdir, pattern: "upload_MeSH"
    publishDir params.logdir, pattern: "*.log"

    input:
        tuple path(import_MeSH), path(app)
    output:
        path "MeSH"
        path "upload_MeSH.sh"
        path "*.log"

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_MeSH.py --config="$import_MeSH" --out="." --log="."
    """
}

workflow forum_mesh() {
    config_import_MeSH().combine(app_forumScripts()) | build_importMesh 
}