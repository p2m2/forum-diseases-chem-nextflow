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
    publishDir params.rdfoutdir, pattern: "PubChem_Compound"
    publishDir params.rdfoutdir, pattern: "PubChem_Descriptor"
    publishDir params.rdfoutdir, pattern: "PubChem_InchiKey"
    publishDir params.rdfoutdir, pattern: "PubChem_Reference"
    publishDir params.rdfoutdir, pattern: "PubChem_Synonym"
    publishDir params.rdfoutdir, pattern: "upload_PubChem_minimal.sh"
    publishDir params.logdir, pattern: "*.log"
    
    input:
        tuple path(import_PubChem_min), path(app)
    output:
        path "PubChem_*"
        path "upload_PubChem_minimal.sh"
        path "*.log"
        //path "$rdfoutdir/PubChem_Compound/compound/*" //get date-version of pubchem

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_PubChem.py --config="$import_PubChem_min" --out="." --log="."
    """
}

process pubchemVersion {
    input:
        path pubChemCompoundDir
    output: stdout
    """
    ls ${pubChemCompoundDir}/compound/
    """
}

workflow forum_PubChemMin() {
    config_import_PubChemMin().combine(app_forumScripts()) | build_import_PubChemMin 
}