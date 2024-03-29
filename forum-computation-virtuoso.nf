include { app_forumScripts ; workflow_forumScripts } from './forum-source-repository'

ncpu            = params.ncpuVirtuoso
memReq          = params.memReqVirtuoso

/* 
    Seulement 1 instance sur la machine.
    => Pas d'execution multiple sur la meme machine 
*/
process run_virtuoso {
//    debug true
    memory memReq
    input:
        val ready
        path workflowDir
        val listScriptSh
    output:
        path "docker-compose.yml"
        path "data"
        val true

    /* -s <dir> dir should not be a symbolink link => ${params.rdfoutdir} is an absolute path */
    """
    echo "script to load:$listScriptSh"
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c start ${listScriptSh}
    """
}

process test_virtuoso_request {
    conda 'curl'
    input:
        val ready
    output:
        val true // finished!

    """
    curl -H "Accept: application/json" -G http://localhost:9980/sparql --data-urlencode query='select distinct ?type where { ?thing a ?type } limit 1'
    """
}

process disabled_checkpoint {
//    debug true
    input:
        val ready
        path workflowDir
        path dockerCompose
        path data
    
    output:
        val true 

    """
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c fix
    """
}

process computation {
    conda 'forum-conda-env.yml'
    cpus ncpu
    memory memReq
    storeDir params.rdfoutdir
    storeDir params.outdir

    input:
        val ready
        path appDir
        path workflowDir
        val resource
        val uploadFile
        val nameComputation
        path configComputation
        path configEnrichmentAnalysis
    output:
        path resource
        path uploadFile

    """
    $workflowDir/w_computation.sh \
        -v ${params.forumRelease} \
        -m $configComputation \
        -t $configEnrichmentAnalysis \
        -u $nameComputation \
        -d ${params.outdir} \
        -s ${params.rdfoutdir} \
        -l ${params.logdir}
    """
}


process shutdown_virtuoso {
    debug true
    input:
        val ready
        path workflowDir
        path dockerCompose
        path data

    """
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c stop
    $workflowDir/w_virtuoso.sh -d . -s ${params.rdfoutdir} -c clean
    """
}

process waitProdDir {
    debug true
    input:
        val scriptsToWait
    output: 
        val true

    """
    echo "==== Waiting for $scriptsToWait ===="
    
    while [ ! -e ${scriptsToWait} ]
    do 
        sleep 1
    done

    echo "= $scriptsToWait Ok = "
    """
}

workflow start_virtuoso() {
    take:
        listScripts
    main:
        app = app_forumScripts()
        workflow = workflow_forumScripts()
        
        listScripts.view { "script path : $it "}
        
       // initValue = listScripts.map { a -> a.split("/").last() }
        namesScripts = 
            listScripts
                .map { a -> a.split("/").last() }
                .reduce { a,b -> 
                    a + " " + b
                    }
    
        gatherResults = waitProdDir(listScripts).collect()
        
        namesScripts.view { "name script : $it "}

        // 1 run virtuoso

        run_virtuoso(gatherResults,workflow,namesScripts)
        
        dockerCompose = run_virtuoso.out[0]
        data = run_virtuoso.out[1]
        ready = run_virtuoso.out[2]

        // 2 disable checkpoint to improve performance
        readyToRequestVirtuoso = 
            disabled_checkpoint(ready,workflow,dockerCompose,data)

        // 3 test : request virtuoso
        test_virtuoso_request(readyToRequestVirtuoso)

    emit:
        test_virtuoso_request.out
        dockerCompose
        data
}

workflow stop_virtuoso() {
    take:
        readyToCloseVirtuoso
        workflow
        dockerCompose
        data

    main:
        app = app_forumScripts()
        workflow = workflow_forumScripts()
        shutdown_virtuoso(readyToCloseVirtuoso, workflow,dockerCompose,data)
}

workflow.onError {

    println "Oops... Pipeline execution stopped with the following message: ${workflow.errorMessage}"
    def proc = "docker rm -f forum_virtuoso_9980".execute()
    proc.waitFor()
    println proc.text
}
