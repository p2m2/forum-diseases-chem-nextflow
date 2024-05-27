include { app_forumScripts } from './forum-source-repository'


process download_Human {
    conda 'wget'
    maxRetries 3

    output:
        path 'Human-GEM.xml'

    """
    wget https://raw.githubusercontent.com/SysBioChalmers/Human-GEM/${params.HumanGEMVersion}/model/Human-GEM.xml
    """
} 

process config_Human {
    publishDir params.configdir

    input:
        path human_sbml
    
    output:
        path "config_Human_${params.HumanGEMVersion}.ini"

    """
    tee -a config_Human_${params.HumanGEMVersion}.ini << END
    [SBML]
    path = ${human_sbml}
    version = Human_${params.HumanGEMVersion}
    [DEFAULT]
    upload_file = upload_Human_${params.HumanGEMVersion}.sh
    [RDF]
    path = GEM/HumanGEM/${params.HumanGEMVersion}/HumanGEM.ttl
    [META]
    path = app/build/data/table_info_2021.csv
    [VOID]
    description = Human-GEM: The generic genome-scale metabolic model of Homo sapiens
    title = HumanGEM ${params.HumanGEMVersion}
    source = https://github.com/SysBioChalmers/Human-GEM/tree/${params.HumanGEMVersion}
    seeAlso = http:doi.org/10.1126/scisignal.aaz1482
    END
    """
}

process build_importSBML {
    conda 'forum-conda-env.yml'
    
    storeDir params.rdfoutdir
        /*
    publishDir params.rdfoutdir, pattern: "GEM"
    publishDir "${params.rdfoutdir}/Id_mapping/Intra/", pattern: "Id_mapping/Intra/SBML"
    publishDir params.rdfoutdir, pattern: "upload_Human1_1.7.sh"
    */
    input:
        tuple path(config_Human), path(app), path(human_sbml)
    output:
        path "GEM"
        path "Id_mapping/Intra/SBML"
        path "upload_Human_${params.HumanGEMVersion}.sh"

    """
    python3 -u $app/build/import_SBML.py --config="$config_Human" --out="." > import_SBML_Human.log
    """
}

workflow forum_SBML_Human() {
    sbml = download_Human()
    config_Human(sbml).combine(app_forumScripts()).combine(sbml) | build_importSBML 
}