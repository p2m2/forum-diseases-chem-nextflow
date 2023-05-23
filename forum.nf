params.repogit = 'https://github.com/eMetaboHUB/Forum-DiseasesChem.git'
params.rdfoutdir= 'virtuoso'
params.logdir= 'log'
params.testDev = 'true'

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


/* ---------------------- */
/* Config builder */
/* --------------------------*/

process config_import_MeSH {

    output:
        path 'import_MeSH.ini'

    """
    tee -a import_MeSH.ini << END
    [DEFAULT]
    upload_file = upload_MeSH.sh
    log_file = dl_MeSH.log
    [MESH]
    version = latest
    ftp = ftp.nlm.nih.gov
    ftp_path_void = /online/mesh/rdf/void_1.0.0.ttl
    ftp_path_mesh = /online/mesh/rdf/mesh.nt
    END
    """
}


process config_import_MetaNetX {

    output:
        path 'import_MetaNetX.ini'

    """
    tee -a import_MetaNetX.ini << END
    [DEFAULT]
    upload_file = upload_MetaNetX.sh
    log_file = dl_metanetx.log
    [METANETX]
    version = 4.3
    url = https://www.metanetx.org/ftp/{version}/metanetx.ttl.gz
    END
    """
}

/* ------------------------- */
/* Builder                   */
/* --------------------------*/

process build_importMesh {
    conda 'forum-conda-env.yml'
    input:
        path rdfoutdir
        path logdir
        path import_MeSH
        path app
    output:
        path "$rdfoutdir/MeSH"

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_MeSH.py --config="$import_MeSH" --out="$rdfoutdir" --log="$logdir"
    """
}

process build_import_MetaNetX {
    conda 'forum-conda-env.yml'
    input:
        path rdfoutdir
        path logdir
        path import_MetaNetX
        path app
    output:
        path "$rdfoutdir/Me/*"

    """
    export TESTDEV=${params.testDev}
    python3 -u $app/build/import_MetaNetX.py --config="$import_MetaNetX" --out="$rdfoutdir" --log="$logdir"
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


    build_importMesh(rdfoutdir,logdir,config_import_MeSH(),appDir)
    build_import_MetaNetX(rdfoutdir,logdir,config_import_MetaNetX(),appDir)


}