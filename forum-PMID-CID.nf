include { app_forumScripts } from './forum-source-repository'
include { pubchemVersion ; waitPubChem } from './forum-PubChem-min'

process config_import_PMIDCID {
    publishDir params.configdir

    input:
        val pubchemVersion

    output:
        path 'import_PMID_CID.ini'

    """
    tee -a import_PMID_CID.ini << END
    [DEFAULT]
    upload_file = upload_PMID_CID.sh
    log_file = log_PMID_CID.log
    [ELINK]
    version = ${params.forumRelease}
    run_as_test = ${params.entrez.run_as_test}
    pack_size = ${params.entrez.pack_size}
    api_key = ${params.entrez.apikey}
    timeout = ${params.entrez.timeout }
    max_triples_by_files = ${params.entrez.max_triples_by_files}
    reference_uri_prefix = http://rdf.ncbi.nlm.nih.gov/pubchem/reference
    compound_path = PubChem_Compound/compound/${pubchemVersion.trim()}
    reference_path = PubChem_Reference/reference/${pubchemVersion.trim()}
    END
    """
}

process build_import_PMIDCID {
    debug true
    memory '40 GB'
    conda 'forum-conda-env.yml'

    storeDir params.rdfoutdir
    
    /*
    publishDir params.rdfoutdir, pattern: "PMID_CID"
    publishDir params.rdfoutdir, pattern: "PMID_CID_endpoints"
    publishDir params.rdfoutdir, pattern: "upload_PMID_CID.sh"
    */
    /*
        pubChemCompound and pubChemReference must be as input to reach turtle files by the import_PMID_CID.py process
    */
    input:
        tuple path(import_PMID_CID), path(app), path(pubChemCompound), path(pubChemReference)
    output:
        path "PMID_CID"
        path "PMID_CID_endpoints"
        path "upload_PMID_CID.sh"

    """
    pip install eutils --quiet
    python3 -u $app/build/import_PMID_CID.py --config="$import_PMID_CID" --out="." --log="."
    """
}

/* Use state-dependency pattern : https://github.com/nextflow-io/patterns/blob/master/docs/state-dependency.md */

workflow forum_PMID_CID() {
    
    /* dependencies */

    compound = Channel.fromPath("${params.rdfoutdir}/PubChem_Compound")
    reference = Channel.fromPath("${params.rdfoutdir}/PubChem_Reference")
    
    waitPubChem()

    config_import_PMIDCID(
        pubchemVersion(waitPubChem.out))
        .combine(app_forumScripts())
        .combine(compound) 
        .combine(reference) 
        | build_import_PMIDCID
        
}