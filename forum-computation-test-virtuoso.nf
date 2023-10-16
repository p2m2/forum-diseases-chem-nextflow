include { start_virtuoso ; stop_virtuoso } from './forum-computation-virtuoso'

process test_virtuoso_request {
    debug true
    input:
        val ready
    output:
        val true // finnished!

    """
    curl -H "Accept: application/json" -G http://localhost:9980/sparql --data-urlencode query='select distinct ?type where { ?thing a ?type } limit 1'
    """
}

workflow test_upload_vocab() {

    app = app_forumScripts()

    listScripts = Channel.fromList([
            "${params.rdfoutdir}/upload.sh"
        ])
        
    listScripts.view()

    start_virtuoso(listScripts) 

    readyToCompute = start_virtuoso.out[0]
    dockerCompose  = start_virtuoso.out[1]
    data           = start_virtuoso.out[2]

    test_virtuoso_request(readyToCompute.out[0])
    readyToClose = test_virtuoso_request.out[0]

    stop_virtuoso(readyToClose,workflow, dockerCompose, data)

}
