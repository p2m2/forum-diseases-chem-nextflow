include { app_forumScripts ; workflow_forumScripts } from './forum-source-repository'
include { start_virtuoso ;  computation ; stop_virtuoso } from './forum-computation-virtuoso'
include { pubchemVersion } from './forum-PubChem-min'
include { meSHVersion } from './forum-MeSH'

ncpu            = 12
memReq          = '80 GB'
uploadFile      = "upload_CID_MESH_EA.sh"
resource        = "EnrichmentAnalysis/CID_MESH"
nameComputation = "CID_MESH"

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
    request_file = cid_mesh_used_thesaurus
    [VIRTUOSO]
    url = http://localhost:9980/sparql/
    graph_from = https://forum.semantic-metabolomics.org/PMID_CID/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PMID_CID_endpoints/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PubChem/reference/${pubchemVersion.trim()}
                https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
    [X_Y]
    name = $nameComputation
    Request_name = count_distinct_pmids_by_CID_MESH
    Size_Request_name = count_number_of_CID
    limit_pack_ids = 500
    limit_selected_ids = 1000000
    n_processes = $ncpu
    out_dir = $nameComputation
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
    upload_file = $uploadFile
    ftp = ftp.semantic-metabolomics.org:/
    [METADATA]
    ressource = ${resource}
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



workflow computation_cid_mesh() {

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
        config_enrichment_analysis(meshVersion,pubchemVersion))

    stop_virtuoso(computation.out[0],workflow, dockerCompose, data)
}
