

process config_import_MetaNetX {

    output:
        path 'import_MetaNetX.ini'

    """
    tee -a import_MetaNetX.ini << END
    [DEFAULT]
    upload_file = upload_MetaNetX.sh
    log_file = dl_metanetx.log
    [METANETX]
    version = 4.3
    url = https://www.metanetx.org/ftp/{version}/metanetx.ttl.gz
    END
    """
}

process build_import_MetaNetX {
    conda 'forum-conda-env.yml'
    input:
        path rdfoutdir
        path logdir
        path import_MetaNetX
        path app
    output:
        path "$rdfoutdir/MetaNetX"

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_MetaNetX.py --config="$import_MetaNetX" --out="$rdfoutdir" --log="$logdir"
    """
}