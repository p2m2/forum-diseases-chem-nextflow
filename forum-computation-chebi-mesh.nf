include { app_forumScripts ; workflow_forumScripts } from './forum-source-repository'
include { start_virtuoso ;  computation ; stop_virtuoso } from './forum-computation-virtuoso'
include { pubchemVersion } from './forum-PubChem-min'
include { meSHVersion } from './forum-MeSH'

ncpu            = 12
memReq          = '80 GB'
uploadFile      = "upload_CHEBI_MESH_EA.sh"
resource        = "EnrichmentAnalysis/CHEBI_MESH"
nameComputation = "CHEBI_MESH"

process waitChEBI {
    output: 
        val true
    
    """
    echo "==== Waiting for upload.sh ===="
    while [ ! -e ${params.rdfoutdir}/upload.sh  ]
    do 
        sleep 1
    done
    """
}

/* val ready : waiting for results of waitPubChem process */
process chebiVersion {
    input:
        val ready
    output: stdout
    
    shell:
    """
    cat ${params.rdfoutdir}/upload.sh |  grep ChEBI | head -n1 | grep -Po '\\d+-\\d+-\\d+' 
    """
}

process config_computation {
    publishDir "${params.configdir}/computation/$nameComputation/"
    input:
        val meshVersion
        val pubchemVersion
        val chebiVersion
    output:
        path 'config.ini'

    """
    tee -a config.ini << END
    [DEFAULT]
    split = False
    file_size = 30000
    request_file = chebi_with_onto_mesh_used_thesaurus
    [VIRTUOSO]
    url = http://localhost:9980/sparql/
    graph_from = https://forum.semantic-metabolomics.org/PMID_CID/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PMID_CID_endpoints/${params.forumRelease}
                https://forum.semantic-metabolomics.org/PubChem/reference/${pubchemVersion.trim()}
                https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
                https://forum.semantic-metabolomics.org/PubChem/compound/${pubchemVersion.trim()}
                https://forum.semantic-metabolomics.org/ChEBI/${chebiVersion.trim()}
    [X_Y]
    name = $nameComputation
    Request_name = count_distinct_pmids_by_ChEBI_MESH
    Size_Request_name = count_number_of_ChEBI
    limit_pack_ids = 25
    limit_selected_ids = 1000000
    n_processes = $ncpu
    out_dir = $nameComputation
    [X]
    name = CHEBI
    Request_name = count_distinct_pmids_by_ChEBI
    Size_Request_name = count_number_of_ChEBI
    limit_pack_ids = 25
    limit_selected_ids = 26
    n_processes = $ncpu
    out_dir = CHEBI_PMID
    [Y]
    name = MESH
    Request_name = count_distinct_pmids_by_MESH
    Size_Request_name = count_number_of_MESH
    limit_pack_ids = 250
    limit_selected_ids = 251
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
        val chebiVersion
    output:
        path 'config_CHEBI_MESH.ini'
    

    """
    tee -a config_CHEBI_MESH.ini << END
    [DEFAULT]
    upload_file = $uploadFile
    ftp = ftp.semantic-metabolomics.org:/
    [METADATA]
    ressource = $resource
    targets = https://forum.semantic-metabolomics.org/MeSHRDF/${meshVersion.trim()}
            https://forum.semantic-metabolomics.org/ChEBI/${chebiVersion.trim()}
    [PARSER]
    chunk_size = 1000000
    threshold = 0.000001
    column = q.value
    [NAMESPACE]
    ns = http://purl.obolibrary.org/obo/CHEBI_
        http://id.nlm.nih.gov/mesh/
        http://www.w3.org/2004/02/skos/core#
    name = chebi
        mesh
        skos
    [SUBJECTS]
    name = CHEBI
    namespace = chebi
    prefix = 
    [PREDICATES]
    name = related
    namespace = skos 
    [OBJECTS]
    name = MESH
    namespace = mesh
    prefix =
    [OUT]
    file_prefix = triples_assos_CHEBI_MESH
    END
    """
}

workflow computation_chebi_mesh() {

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
    waitChEBI()
    chebiVersion = chebiVersion(waitChEBI.out)

    readyToClose = computation(
        readyToCompute,
        app,
        workflow,
        resource,
        uploadFile,
        nameComputation,
        config_computation(meshVersion,pubchemVersion,chebiVersion),
        config_enrichment_analysis(meshVersion,chebiVersion))

    stop_virtuoso(computation.out[0],workflow, dockerCompose, data)
}

/* Testing method with virtuoso already online on the server */
workflow computation_chebi_mesh_test() {
    
    app = app_forumScripts()
    workflow = workflow_forumScripts()

    readyToCompute = Channel.from(true)

    pubchemVersion=pubchemVersion(readyToCompute)
    meshVersion = meSHVersion(readyToCompute)
    waitChEBI()
    chebiVersion = chebiVersion(waitChEBI.out)

    readyToClose = computation(
        readyToCompute,
        app,
        workflow,
        resource,
        uploadFile,
        nameComputation,
        config_computation(meshVersion,pubchemVersion,chebiVersion),
        config_enrichment_analysis(meshVersion,chebiVersion))
}