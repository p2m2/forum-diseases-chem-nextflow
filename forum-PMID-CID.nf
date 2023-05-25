include { app_forumScripts } from './forum-source-repository'

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

/* Use state-dependency pattern : https://github.com/nextflow-io/patterns/blob/master/docs/state-dependency.md */

process waitPubChem {
    input:
        path pubChemCompoundDir
        path pubChemReferenceDir
    output: 
        val true
    
    """
    echo "==== Waiting for $pubChemCompoundDir and $pubChemReferenceDir ===="
    while [ ! -e ${pubChemCompoundDir} ] || [ ! -e ${pubChemReferenceDir} ]; do sleep 1; done
    """
}

/* val ready : waiting for results of waitPubChem process */
process pubchemVersion {
    input:
        val ready
        path pubChemCompoundDir
    output: stdout
    """
    ls ${pubChemCompoundDir}/compound/
    """
}

workflow forum_PMID_CID() {
    
    app=app_forumScripts()

    compound = Channel.fromPath("${params.rdfoutdir}/PubChem_Compound")
    reference = Channel.fromPath("${params.rdfoutdir}/PubChem_Reference")
    
    waitPubChem(compound,reference)

    config_import_PMIDCID(
        pubchemVersion(waitPubChem.out,compound))
        .combine(app) 
        .combine(compound) 
        .combine(reference)
        | build_import_PMIDCID
        
}