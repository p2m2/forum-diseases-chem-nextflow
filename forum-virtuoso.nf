include { workflow_forumScripts } from './forum-source-repository'

process run_virtuoso {
    publishDir params.virtuosoPersitenceDir
    input:
        path workflowDir
        path rdfoutdir
        path upload_sh
    output:
        path "${params.virtuosoPersitenceDir}/data"
        path "${params.virtuosoPersitenceDir}/docker-compose.yml"

    """
    $workflowDir/w_virtuoso.sh -d ${params.virtuosoPersitenceDir} -s $rdfoutdir -c start $upload_sh
    """
}

/*
process shutdown_virtuoso {
    input:
        tuple path(workflowDir), path(rdfoutdir)

    """
    $workflowDir/w_virtuoso.sh -d ${params.virtuosoPersitenceDir} -s $rdfoutdir -c stop
    """
}*/

workflow {
    rdfoutdir = Channel.fromPath("${params.rdfoutdir}")
    upload_sh = Channel.fromPath("${params.rdfoutdir}/upload.sh")
    workflow_forumScripts()
    run_virtuoso(workflow_forumScripts.out,rdfoutdir,upload_sh)
   // workflow_forumScripts.out.combine(rdfoutdir) | shutdown_virtuoso
}