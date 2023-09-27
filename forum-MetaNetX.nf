include { app_forumScripts } from './forum-source-repository'


process metaNetXVersion {
    output:
        stdout emit: value
    maxRetries 3
    
    script:
    """
    wget -q -nc -O - https://www.metanetx.org/ftp/ | awk 'match(\$0, />([0-9].[0-9])\\/</) {print substr(\$0, RSTART+1, RLENGTH-3)}' | sort -n | tail -n1
    """
}

process config_import_MetaNetX {
    //memory '40 GB'
    publishDir params.configdir
    input:
        val version
    output:
        path 'import_MetaNetX.ini'

    """
    tee -a import_MetaNetX.ini << END
    [DEFAULT]
    upload_file = upload_MetaNetX.sh
    log_file = dl_metanetx.log
    [METANETX]
    version = ${version}
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
        val version
    output:
        path 'import_MetaNetX_mapping.ini'

    """
    tee -a import_MetaNetX_mapping.ini << END
    [DEFAULT]
    upload_file = upload_MetaNetX_mapping.sh
    [METANETX]
    version = ${version}
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
    metanetxVersion=metaNetXVersion()
    config_import_MetaNetX(metanetxVersion.value).combine(app) | build_import_MetaNetX
    waitMetaNetX(build_import_MetaNetX.out[0])
    config_import_MetaNetX_mapping(waitMetaNetX.out,metanetxVersion.value).combine(app).combine(build_import_MetaNetX.out[0]) | build_import_MetaNetX_mapping
}
