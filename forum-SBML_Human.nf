include { app_forumScripts } from './forum-source-repository'

process version_Human {
    conda 'curl'
    output:
        stdout emit: value
    maxRetries 3

    """
    curl -s "https://api.github.com/repos/SysBioChalmers/Human-GEM/releases/latest" | grep "tarball_url" | cut -d '"' -f 4 | awk -F'/' '{print \$NF}' | tr -d '\\r'
    """
}

process download_Human {
    conda 'curl'
    maxRetries 3
    input:
        val humanGEMVersion
    output:
        path 'Human-GEM.xml'

    """
    curl -s -O https://raw.githubusercontent.com/SysBioChalmers/Human-GEM/${humanGEMVersion.trim()}/model/Human-GEM.xml
    """
} 

process config_Human {
    publishDir params.configdir

    input:
        tuple val(humanGEMVersion),path(human_sbml)
    
    output:
        path 'config_Human.ini'

    """
    tee -a config_Human.ini << END
    [SBML]
    path = ${human_sbml}
    version = Human_${humanGEMVersion.trim()}
    [DEFAULT]
    upload_file = upload_Human_${humanGEMVersion.trim()}.sh
    [RDF]
    path = GEM/HumanGEM/${humanGEMVersion.trim()}/HumanGEM.ttl
    [META]
    path = app/build/data/table_info_2021.csv
    [VOID]
    description = Human-GEM: The generic genome-scale metabolic model of Homo sapiens
    title = HumanGEM ${humanGEMVersion.trim()}
    source = https://github.com/SysBioChalmers/Human-GEM/tree/${humanGEMVersion.trim()}
    seeAlso = http:doi.org/10.1126/scisignal.aaz1482
    END
    """
}

process build_importSBML {
    conda 'forum-conda-env.yml'
    
    storeDir params.rdfoutdir
    input:
        tuple val(humanGEMVersion),path(config_Human), path(app), path(human_sbml)
    output:
        path "GEM"
        path "Id_mapping/Intra/SBML"
        path "upload_Human_${humanGEMVersion.trim()}.sh"

    """
    python3 -u $app/build/import_SBML.py --config="$config_Human" --out="." > import_SBML_Human.log
    """
}

workflow forum_SBML_Human() {
    version = version_Human()
    sbml = download_Human(version)

    config_human_ini = config_Human(version.combine(sbml))

    version.combine(config_human_ini).combine(app_forumScripts()).combine(sbml) | build_importSBML 
}