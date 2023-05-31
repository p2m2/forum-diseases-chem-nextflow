include { workflow_forumScripts } from './forum-source-repository'

process run_virtuoso {
    debug false
    input:
        path workflowDir
        val listScriptSh
    output:
        val true
        path "data"
        path "docker-compose.yml"

    /* -s <dir> dir should not be a symbolink link => ${params.rdfoutdir} is an absolute path */
    """
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c start ${listScriptSh}
    """
}

process disbled_checkpoint {
    debug true
    input:
        val ready
        path workflowDir
        path data
        path docker_compose
    
    output:
        val true 

    """
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c fix
    """
}


process shutdown_virtuoso {
    input:
        val ready
        path workflowDir
        path data
        path docker_compose

    """
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c stop
    """
}

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


workflow forum_test_virtuoso() {
   
    app = workflow_forumScripts()
    //listScript = Channel.from( "upload.sh upload_MetaNetX.sh")
    // only vocabularies for teting virtuoso 
    listScript = Channel.from( "upload.sh")
    run_virtuoso(app,listScript) 
    
    // 1 run virtuoso
    readyToDisableCheckpoint = run_virtuoso.out[0]
    data = run_virtuoso.out[1]
    docker_compose = run_virtuoso.out[2]
    
    // 2 disable checkpoint to improve performance
    readyToRequestVirtuoso = disbled_checkpoint(readyToDisableCheckpoint,app,data,docker_compose)

    // 3 request virtuoso
    readyToCloseVirtuoso = test_virtuoso_request(readyToRequestVirtuoso)

    // 4 close virtuoso
    shutdown_virtuoso(readyToCloseVirtuoso, app, data, docker_compose)
}