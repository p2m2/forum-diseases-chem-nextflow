include { app_forumScripts, workflow_forumScripts } from './forum-source-repository'
include { run_virtuoso ;  disabled_checkpoint ; shutdown_virtuoso ; test_virtuoso_request ; waitProdDir } from './forum-virtuoso'
include { pubchemVersion } from './forum-PubChem-min'
include { meSHVersion } from './forum-MeSH'

ncpu = 12
memReq = '80 GB'

process config_computation {
    publishDir "${params.configdir}/computation/CID_MESH/"
    input:
        val meshVersion
        val pubchemVersion

    output:
        path 'config.ini'

    """
    tee -a config.ini << END
    [DEFAULT]
    split = False
    file_size = 100000
    request_file = cid_mesh_used_thesaurus
    [VIRTUOSO]
    url = http://localhost:9980/sparql/
    graph_from = https://forum.semantic-metabolomics.org/PMID_CID/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PMID_CID_endpoints/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PubChem/reference/${pubchemVersion.trim()}
                https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
    [X_Y]
    name = CID_MESH
    Request_name = count_distinct_pmids_by_CID_MESH
    Size_Request_name = count_number_of_CID
    limit_pack_ids = 500
    limit_selected_ids = 1000000
    n_processes = $ncpu
    out_dir = CID_MESH
    [X]
    name = CID
    Request_name = count_distinct_pmids_by_CID
    Size_Request_name = count_number_of_CID
    limit_pack_ids = 1000
    limit_selected_ids = 1001
    n_processes = $ncpu
    out_dir = CID_PMID
    [Y]
    name = MESH
    Request_name = count_distinct_pmids_by_MESH
    Size_Request_name = count_number_of_MESH
    limit_pack_ids = 1000
    limit_selected_ids = 1001
    n_processes = $ncpu
    out_dir = MESH_PMID
    [U]
    name = PMID
    Request_name = count_all_individuals
    Size_Request_name = count_all_pmids
    limit_pack_ids = 100000
    limit_selected_ids = 2
    n_processes = $ncpu
    out_dir = PMID
    END
    """
}


process config_enrichment_analysis {
    publishDir "${params.configdir}/enrichment_analysis/"
    input:
        val meshVersion
        val pubchemVersion

    output:
        path 'config_CID_MESH.ini'
    

    """
    tee -a config_CID_MESH.ini << END
    [DEFAULT]
    upload_file = upload_CID_MESH_EA.sh
    ftp = ftp.semantic-metabolomics.org:/
    [METADATA]
    ressource = EnrichmentAnalysis/CID_MESH
    targets = https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
            https://forum.semantic-metabolomics.org/PubChem/compound/${pubchemVersion.trim()}
    [PARSER]
    chunk_size = 1000000
    threshold = 0.000001
    column = q.value
    [NAMESPACE]
    ns = http://rdf.ncbi.nlm.nih.gov/pubchem/compound/
        http://id.nlm.nih.gov/mesh/
        http://www.w3.org/2004/02/skos/core#
    name = compound
        mesh
        skos
    [SUBJECTS]
    name = CID
    namespace = compound
    prefix = CID
    [PREDICATES]
    name = related
    namespace = skos 
    [OBJECTS]
    name = MESH
    namespace = mesh
    prefix =
    [OUT]
    file_prefix = triples_assos_CID_MESH
    END
    """
}

process computation {
    cpus ncpu
    memory memReq
    storeDir params.rdfoutdir
    input:
        val ready
        path appDir
        path workflowDir
        path configComputation
        path configEnrichmentAnalysis
    output:
        path "EnrichmentAnalysis/CID_MESH"
        path "upload_CID_MESH_EA.sh"

    """
    $workflowDir/w_computation.sh -v ${params.forumRelease} \
        -m $configComputation \
        -t $configEnrichmentAnalysis \
        -u CID_MESH \
        -d  ${params.logdir} \
        -s ${params.rdfoutdir} \
        -l ${params.logdir} > computation_cid_mesh.log
    """
}

workflow forum_computation_cid_mesh() {

    app = app_forumScripts()
    workflow = workflow_forumScripts()


    listScripts = Channel.fromList([
        "${params.rdfoutdir}/upload.sh",
        "${params.rdfoutdir}/upload_PMID_CID.sh",
        "${params.rdfoutdir}/upload_MeSH.sh",
        "${params.rdfoutdir}/upload_PubChem_minimal.sh"
    ])
    
    listScripts.view()

    namesScripts = 
    listScripts
        .reduce { a,b -> 
            a.split("/").last() + " " + b.split("/").last()
            }

    gatherResults = waitProdDir(listScripts).collect()
    run_virtuoso(gatherResults,workflow,namesScripts)

    // 1 run virtuoso
    readyToDisableCheckpoint = run_virtuoso.out[0]
    data = run_virtuoso.out[1]
    docker_compose = run_virtuoso.out[2]
    
    // 2 disable checkpoint to improve performance
    readyToRequestVirtuoso = disabled_checkpoint(readyToDisableCheckpoint,workflow,data,docker_compose)

    // 3 request virtuoso
    readyToCloseVirtuoso = test_virtuoso_request(readyToRequestVirtuoso)

    // 4 computation
    pubchemVersion=pubchemVersion(gatherResults)
    meshVersion = meSHVersion(gatherResults)

    computation(readyToCloseVirtuoso,app,workflow,
    config_computation(meshVersion,pubchemVersion),
    config_enrichment_analysis(meshVersion,pubchemVersion))

    // 5 close virtuoso
    shutdown_virtuoso(readyToCloseVirtuoso, workflow, data, docker_compose) 
}