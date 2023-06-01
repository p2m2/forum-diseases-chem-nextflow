include { app_forumScripts } from './forum-source-repository'


process download_Human1_1_7 {
    conda 'wget'
    maxRetries 3

    output:
        path 'Human-GEM.xml'

    """
    wget https://github.com/SysBioChalmers/Human-GEM/raw/main/model/Human-GEM.xml
    """
} 

process config_Human1_1_7 {
    publishDir params.configdir

    input:
        path human1_1_7_sbml
    
    output:
        path 'config_Human1_1.7.ini'

    """
    tee -a config_Human1_1.7.ini << END
    [SBML]
    path = ${human1_1_7_sbml}
    version = Human1/1.7
    [DEFAULT]
    upload_file = upload_Human1_1.7.sh
    [RDF]
    path = GEM/HumanGEM/1.7/HumanGEM.ttl
    [META]
    path = app/build/data/table_info_2021.csv
    [VOID]
    description = Human-GEM: The generic genome-scale metabolic model of Homo sapiens
    title = HumanGEM v1.7
    source = https://github.com/SysBioChalmers/Human-GEM/tree/v1.7.0
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
        tuple path(config_Human1_1_7), path(app), path(human1_1_7_sbml)
    output:
        path "GEM"
        path "Id_mapping/Intra/SBML"
        path "upload_Human1_1.7.sh"

    """
    python3 -u $app/build/import_SBML.py --config="$config_Human1_1_7" --out="." > import_SBML_Human.log
    """
}

workflow forum_SBML_Human() {
    sbml = download_Human1_1_7()
    config_Human1_1_7(sbml).combine(app_forumScripts()).combine(sbml) | build_importSBML 
}