include { app_forumScripts ; workflow_forumScripts } from './forum-source-repository'
include { start_virtuoso ;  computation ; stop_virtuoso } from './forum-computation-virtuoso'
include { pubchemVersion } from './forum-PubChem-min'
include { meSHVersion } from './forum-MeSH'

ncpu            = 2
memReq          = '40 GB'
uploadFile      = "upload_MESH_MESH_EA.sh"
resource        = "EnrichmentAnalysis/MESH_MESH"
nameComputation = "MESH_MESH"

process config_computation {
    publishDir "${params.configdir}/computation/$nameComputation/"
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
    request_file = mesh_to_mesh
    [VIRTUOSO]
    url = http://localhost:9980/sparql/
    graph_from = https://forum.semantic-metabolomics.org/PMID_CID_endpoints/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PubChem/reference/${pubchemVersion.trim()}
                https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
    [X_Y]
    name = MESH_MESH
    Request_name = count_distinct_pmids_by_MESH_MESH
    Size_Request_name = count_number_of_MESH
    limit_pack_ids = 10
    limit_selected_ids = 1000000
    n_processes = $ncpu
    out_dir = MESH_MESH
    [X]
    name = MESH1
    Request_name = count_distinct_pmids_by_MESH
    Size_Request_name = count_number_of_MESH
    limit_pack_ids = 50
    limit_selected_ids = 51
    n_processes = $ncpu
    out_dir = MESH1
    [Y]
    name = MESH2
    Request_name = count_distinct_pmids_by_MESH
    Size_Request_name = count_number_of_MESH
    limit_pack_ids = 50
    limit_selected_ids = 51
    n_processes = $ncpu
    out_dir = MESH2
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
    output:
        path 'config_MESH_MESH.ini'
    

    """
    tee -a config_MESH_MESH.ini << END
    [DEFAULT]
    upload_file = $uploadFile
    ftp = ftp.semantic-metabolomics.org:/
    [METADATA]
    ressource = $resource
    targets = https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
            https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
    [PARSER]
    chunk_size = 1000000
    threshold = 0.000001
    column = q.value
    [NAMESPACE]
    ns = http://id.nlm.nih.gov/mesh/
        http://www.w3.org/2004/02/skos/core#
    name = mesh
        skos
    [SUBJECTS]
    name = MESH1
    namespace = mesh
    prefix = 
    [PREDICATES]
    name = related
    namespace = skos 
    [OBJECTS]
    name = MESH2
    namespace = mesh
    prefix =
    [OUT]
    file_prefix = triples_assos_MESH_MESH
    END
    """
}

workflow computation_mesh_mesh() {

    app = app_forumScripts()
    workflow = workflow_forumScripts()


    listScripts = Channel.fromList([
        "${params.rdfoutdir}/upload.sh",
        "${params.rdfoutdir}/upload_PMID_CID.sh",
        "${params.rdfoutdir}/upload_MeSH.sh",
        "${params.rdfoutdir}/upload_PubChem_minimal.sh"
    ])
    
    listScripts.view()

    start_virtuoso(listScripts) 

    readyToCompute = start_virtuoso.out[0]
    dockerCompose  = start_virtuoso.out[1]
    data           = start_virtuoso.out[2]
    
    pubchemVersion=pubchemVersion(readyToCompute)
    meshVersion = meSHVersion(readyToCompute)

    readyToClose = computation(
        readyToCompute,
        app,
        workflow,
        resource,
        uploadFile,
        nameComputation,
        config_computation(meshVersion,pubchemVersion),
        config_enrichment_analysis(meshVersion))

    stop_virtuoso(computation.out[0],workflow, dockerCompose, data)
}