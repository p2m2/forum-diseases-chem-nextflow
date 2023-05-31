include { app_forumScripts } from './forum-source-repository'


process config_import_MetaNetX {
    //memory '40 GB'
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
    storeDir params.rdfoutdir
    /*
    publishDir params.rdfoutdir, pattern: "MetaNetX"
    publishDir params.rdfoutdir, pattern: "upload_MetaNetX.sh"
    */

    input:
        tuple path(import_MetaNetX), path(app)

    output:
        path "MetaNetX"
        path "upload_MetaNetX.sh"

    """
    python3 -u $app/build/import_MetaNetX.py --config="$import_MetaNetX" --out="." --log="."
    """
}

process config_import_MetaNetX_mapping {
    publishDir params.configdir
    input:
        val ready
    output:
        path 'import_MetaNetX_mapping.ini'

    """
    tee -a import_MetaNetX_mapping.ini << END
    [DEFAULT]
    upload_file = upload_MetaNetX_mapping.sh
    [METANETX]
    version = 4.3
    file_name = metanetx.ttl.gz
    [META]
    path = app/build/data/table_info_2021.csv
    END
    """
}

process build_import_MetaNetX_mapping {
    storeDir params.rdfoutdir
    conda 'forum-conda-env.yml'
    memory '40 GB'
    
    //publishDir "${params.rdfoutdir}/Id_mapping/Inter/", pattern: "MetaNetX"
    //publishDir "${params.rdfoutdir}/Id_mapping/Intra/", pattern: "MetaNetX"
    //publishDir params.rdfoutdir, pattern: "upload_MetaNetX_mapping.sh"
    

    input:
        tuple path(import_MetaNetX_mapping), path(app), path(metaNetX)

    output:
        path "Id_mapping/Inter/MetaNetX"
        path "Id_mapping/Intra/MetaNetX"
        path "upload_MetaNetX_mapping.sh"

    """
    python3 -u $app/build/import_MetaNetX_mapping.py --config="$import_MetaNetX_mapping" --out="." > metanetx_mapping.log
    """
}

process waitMetaNetX {
    input:
        path metaNetX
    output: 
        val true
    
    """
    echo "==== Waiting for $metaNetX ===="
    while [ ! -e ${metaNetX} ] ; do sleep 1; done
    """
}

workflow forum_MetaNetX() {
    app=app_forumScripts()
    config_import_MetaNetX().combine(app) | build_import_MetaNetX
    waitMetaNetX(build_import_MetaNetX.out[0])
    config_import_MetaNetX_mapping(waitMetaNetX.out).combine(app).combine(build_import_MetaNetX.out[0]) | build_import_MetaNetX_mapping
}