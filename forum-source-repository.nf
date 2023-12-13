
process app_forumScripts {
    conda 'forum-conda-env.yml'
    publishDir params.localForumSources, pattern: 'app'
    // force the update of app directory. useful to debug the workflow
    //cache false
    output:
        path 'app'

    """ 
    git clone ${params.repogit} repo -b nextflow
    mv repo/app .
    """
}

process workflow_forumScripts {
    conda 'forum-conda-env.yml'
    cache false
    publishDir params.localForumSources, pattern: 'workflow'
    // force the update of workflow directory. useful to debug the workflow
    output:
        path 'workflow'

    """
    git clone ${params.repogit} repo -b nextflow
    mv repo/workflow .
    """
}
