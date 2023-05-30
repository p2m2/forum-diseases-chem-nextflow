
process app_forumScripts {
    publishDir params.localForumSources, pattern: 'app'
    cache false
    output:
        path "app"

    """ 
    git clone ${params.repogit} repo -b nextflow
    mv repo/app .
    """
}
