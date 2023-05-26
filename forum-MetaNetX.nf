include { app_forumScripts } from './forum-source-repository'


process config_import_MetaNetX {
    memory '40 GB'
    publishDir params.configdir

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
    
    publishDir params.rdfoutdir, pattern: "MetaNetX"
    publishDir params.rdfoutdir, pattern: "upload_MetaNetX.sh"
    publishDir params.logdir, pattern: "*.log"

    input:
        tuple path(import_MetaNetX), path(app)

    output:
        path "MetaNetX"
        path "upload_MetaNetX.sh"
        path "*.log"

    """
    python3 -u $app/build/import_MetaNetX.py --config="$import_MetaNetX" --out="." --log="."
    """
}

workflow forum_MetaNetX() {
    config_import_MetaNetX().combine(app_forumScripts()) | build_import_MetaNetX 
}