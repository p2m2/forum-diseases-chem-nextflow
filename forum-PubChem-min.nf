include { app_forumScripts } from './forum-source-repository'

process config_import_PubChemMin {
    publishDir params.configdir
    output:
        path 'import_PubChem_min.ini'

    """
    tee -a import_PubChem_min.ini << END
    [DEFAULT]
    upload_file = upload_PubChem_minimal.sh
    log_file = dl_PubChem_minimal.log
    [PUBCHEM]
    dir_ftp = ["/pubchem/RDF/compound/general", "/pubchem/RDF/descriptor/compound", "/pubchem/RDF/reference", "/pubchem/RDF/inchikey", "/pubchem/RDF/synonym"]
    name = ["compound", "descriptor", "reference", "inchikey", "synonym"]
    out_dir = ["PubChem_Compound", "PubChem_Descriptor", "PubChem_Reference", "PubChem_InchiKey", "PubChem_Synonym"]
    mask = ["*_type*.ttl.gz", false, "*.ttl.gz", false, false]
    version = ["latest", "latest", "latest", "latest", "latest"]
    ftp = ftp.ncbi.nlm.nih.gov
    ftp_path_void = /pubchem/RDF/void.ttl
    END
    """
}

process build_import_PubChemMin {
    debug false
    conda 'forum-conda-env.yml'
    
    storeDir params.rdfoutdir

    maxRetries 3
    /*
    publishDir params.rdfoutdir, pattern: "PubChem_Compound" ,overwrite: true, failOnError: true
    publishDir params.rdfoutdir, pattern: "PubChem_Descriptor" ,overwrite: true, failOnError: true
    publishDir params.rdfoutdir, pattern: "PubChem_InchiKey" ,overwrite: true, failOnError: true
    publishDir params.rdfoutdir, pattern: "PubChem_Reference" ,overwrite: true, failOnError: true
    publishDir params.rdfoutdir, pattern: "PubChem_Synonym" ,overwrite: true, failOnError: true
    publishDir params.rdfoutdir, pattern: "upload_PubChem_minimal.sh" ,overwrite: true, failOnError: true
    */
    input:
        tuple path(import_PubChem_min), path(app)
    output:
        path "PubChem_Compound"
        path "PubChem_Descriptor"
        path "PubChem_InchiKey"
        path "PubChem_Reference"
        path "PubChem_Synonym"
        path "upload_PubChem_minimal.sh"
       
    """
    python3 -u $app/build/import_PubChem.py --config="$import_PubChem_min" --out="." --log="."
    """
}

process config_import_PubChem_mapping {
    publishDir params.configdir
    
    input:
        val ready
        val pubChemVersion
    output:
        path 'import_PubChem_mapping.ini'

    """
    tee -a import_PubChem_mapping.ini << END
    [DEFAULT]
    upload_file = upload_PubChem_mapping.sh
    [PUBCHEM]
    version = ${pubChemVersion.trim()}
    path_to_dir = PubChem_Compound/compound
    mask = *_type*.ttl.gz
    [META]
    path = app/build/data/table_info_2021.csv
    END
    """
}


process build_import_PubChem_mapping {
    debug false
    conda 'forum-conda-env.yml'
    memory '40 GB'
    storeDir params.rdfoutdir
    /*
    publishDir "${params.rdfoutdir}/Id_mapping/Inter/", pattern: "PubChem" , failOnError: true
    publishDir "${params.rdfoutdir}/Id_mapping/Intra/", pattern: "PubChem" , failOnError: true
    publishDir params.rdfoutdir, pattern: "upload_PubChem_mapping.sh" ,overwrite: true, failOnError: true
    */
    input:
        tuple path(import_PubChem_mapping), path(app), path(pubChemCoumpoundPath), path(pubChemDescriptor), path(pubChemInchiKey), path(pubChemReference), path(pubChemSynonym)
    output:
        path "Id_mapping/Inter/PubChem"
        path "Id_mapping/Intra/PubChem"
        path "upload_PubChem_mapping.sh"

    """
    python3 -u $app/build/import_PubChem_mapping.py --config="$import_PubChem_mapping" --out="." > pubchem_mapping.log
    """
}


process waitPubChem {
    output: 
        val true
    
    """
    echo "==== Waiting for upload_PubChem_minimal.sh ===="
    while [ ! -e ${params.rdfoutdir}/upload_PubChem_minimal.sh  ]
    do 
        sleep 1
    done
    """
}

/* val ready : waiting for results of waitPubChem process */
process pubchemVersion {
    input:
        val ready
    output: stdout
    """
    ls ${params.rdfoutdir}/PubChem_Compound/compound/ | tr -d '\r' 
    """
}

workflow forum_PubChemMin() {
    app=app_forumScripts()
    
    config_import_PubChemMin().combine(app) 
        | build_import_PubChemMin

    compondPath = build_import_PubChemMin.out[0]
    descPath = build_import_PubChemMin.out[1]
    inchiPath = build_import_PubChemMin.out[2]
    referencePath = build_import_PubChemMin.out[3]
    synonymPath = build_import_PubChemMin.out[4]

    waitPubChem()

    config_import_PubChem_mapping(waitPubChem.out,pubchemVersion(waitPubChem.out))
        .combine(app)
        .combine(compondPath).combine(descPath).combine(inchiPath).combine(referencePath).combine(synonymPath) 
        | build_import_PubChem_mapping


}