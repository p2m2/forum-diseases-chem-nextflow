include { app_forumScripts ; workflow_forumScripts } from './forum-source-repository'
include { start_virtuoso ; test_virtuoso_request ; stop_virtuoso } from './forum-computation-virtuoso'

workflow test_upload_vocab() {

    app = app_forumScripts()
    w = workflow_forumScripts()

    listScripts = Channel.fromList([
            "${params.rdfoutdir}/upload.sh"
        ])
        
    listScripts.view()

    start_virtuoso(listScripts) 

    readyToCompute = start_virtuoso.out[0]
    dockerCompose  = start_virtuoso.out[1]
    data           = start_virtuoso.out[2]

    //test_virtuoso_request(readyToCompute.out[0])
    //readyToClose = test_virtuoso_request.out[0]

    stop_virtuoso(readyToCompute,workflow, dockerCompose, data)

}
