
process getDate {
    
    output:
        stdout 
    
    """
    date +"%Y%m%d"
    """
}


process config_import_PMIDCID {
    input:
        val version
        val pubchemVersion

    output:
        path 'import_PMID_CID.ini'

    """
    tee -a import_PMID_CID.ini << END
    [DEFAULT]
    upload_file = upload_PMID_CID.sh
    log_file = log_PMID_CID.log
    [ELINK]
    version = ${version}
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
    conda 'forum-conda-env.yml'
    input:
        path rdfoutdir
        path logdir
        path import_PMID_CID
        path app
    output:
        path "$rdfoutdir/PMID_CID"

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_PMID_CID.py --config="$import_PMID_CID" --out="$rdfoutdir" --log="$logdir"
    """
}