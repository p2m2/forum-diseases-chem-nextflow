
process config_import_MeSH {

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
    ftp_path_void = /online/mesh/rdf/void_1.0.0.ttl
    ftp_path_mesh = /online/mesh/rdf/mesh.nt
    END
    """
}

process build_importMesh {
    conda 'forum-conda-env.yml'
    input:
        path rdfoutdir
        path logdir
        path import_MeSH
        path app
    output:
        path "$rdfoutdir/MeSH"

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_MeSH.py --config="$import_MeSH" --out="$rdfoutdir" --log="$logdir"
    """
}