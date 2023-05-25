include { app_forumScripts } from './forum-source-repository'
include { pubchemVersion ; forum_PubChemMin } from './forum-PubChem-min'

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
    reference_uri_prefix = http://rdf.ncbi.nlm.nih.gov/pubchem/reference/PMID
    compound_path = PubChem_Compound/compound/${pubchemVersion}
    reference_path = PubChem_Reference/reference/${pubchemVersion}
    END
    """
}

process build_import_PMIDCID {
    debug true
    conda 'forum-conda-env.yml'
    
    publishDir params.rdfoutdir, pattern: "PMID_CID"
    publishDir params.rdfoutdir, pattern: "PMID_CID_endpoints"
    publishDir params.rdfoutdir, pattern: "uploadXXXXX.sh"
    publishDir params.logdir, pattern: "*.log"

    input:
        tuple path(import_PMID_CID), path(app), path(pubChemCompound), path(pubChemReference)
    output:
        path "PMID_CID"
        path "PMID_CID_endpoints"
        path "uploadXXXXX.sh"
        path "*.log"

    """
    pip install eutils --quiet
    python3 -u $app/build/import_PMID_CID.py --config="$import_PMID_CID" --out="." --log="."
    """
}

workflow forum_PMID_CID() {
      
    compound=file("${params.rdfoutdir}/PubChem_Compound")
    reference=file("${params.rdfoutdir}/PubChem_Reference")

    config_import_PMIDCID(
        pubchemVersion(compound)
        .combine(app_forumScripts()) 
        .combine(Channel.of(compound)) 
        .combine(Channel.of(reference))
        ) 
        | build_import_PMIDCID
     
}