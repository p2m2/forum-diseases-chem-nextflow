
process app_forumScripts {
    publishDir params.localForumSources, pattern: 'app'
    output:
        path "app"

    """ 
    git clone ${params.repogit} repo -b nextflow
    mv repo/app .
    """
}
