include { config_import_MeSH ; build_importMesh } from './forum-MeSH'
include { config_import_MetaNetX ; build_import_MetaNetX } from './forum-MetaNetX'

params.repogit = 'https://github.com/eMetaboHUB/Forum-DiseasesChem.git'
params.rdfoutdir= 'virtuoso'
params.logdir= 'log'


params.vocabularydir='virtuoso/vocabulary'

process download_forumScripts {
    output:
        path('app')
        path('workflow')
        path('config')

    """ 
    git clone ${params.repogit} forum-git -b nextflow
    mv forum-git/app .
    mv forum-git/workflow .
    mv forum-git/config .
    """
}

process create_virtuosoDir {
    output:
        path "${params.rdfoutdir}"
    
    """
        mkdir -p ${params.rdfoutdir}
    """
}

process create_logDir {
    output:
        path "${params.logdir}"
    
    """
        mkdir -p ${params.logdir}
    """
}

process create_vocabularyDirectory() {
    """
    mkdir -p ${params.vocabularydir}
    """
}
    

process download_chebi_vocabulary {
    conda 'wget'
    output:
        path 'chebi.owl'

    """
    wget -nc -O - https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz | gunzip > chebi.owl 
    """
}

process download_mesh_vocabulary {
    conda 'wget'
    output:
        path 'vocabulary_1.0.0.ttl'

    """
    wget https://nlmpubs.nlm.nih.gov/projects/mesh/rdf/2021/vocabulary_1.0.0.ttl
    """
}

process download_cito_vocabulary {
    conda 'wget'
    output:
        path 'cito.ttl'

    """
    wget http://purl.org/spar/cito.ttl 
    """
}

process download_fabio_vocabulary {
    conda 'wget'
    output:
        path 'fabio.ttl'

    """
    wget http://purl.org/spar/fabio.ttl
    """
}

workflow {
    directories=download_forumScripts()
    appDir=directories[0]
    workflowDir=directories[1]
    conigDir=directories[2]

    rdfoutdir=create_virtuosoDir()
    logdir=create_logDir()

    /*
    create_vocabularyDirectory()
    download_chebi_vocabulary()
    download_mesh_vocabulary()
    download_cito_vocabulary()
    download_fabio_vocabulary()
    */


    build_importMesh(rdfoutdir,logdir,config_import_MeSH(),appDir).view()
    build_import_MetaNetX(rdfoutdir,logdir,config_import_MetaNetX(),appDir).view()


}