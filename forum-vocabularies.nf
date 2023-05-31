
vocabularydir="${params.rdfoutdir}/vocabulary"

process download_chebi_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3
    output:
        path 'chebi.owl'

    """
    wget -nc -O - https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl.gz | gunzip > chebi.owl 
    """
}

process chebiVersion {
    conda 'wget'
    output: stdout
    maxRetries 3
    script:

    '''
    html=$(wget -q -nc -O - https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/ | grep chebi.owl.gz)
    pattern="[0-9][0-9A-Za-z\\-]+"
    if [[ $html =~ $pattern ]]; then echo ${BASH_REMATCH[0]} ; else exit 2; fi
    '''
}

process download_mesh_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'vocabulary_1.0.0.ttl'

    """
    wget https://nlmpubs.nlm.nih.gov/projects/mesh/rdf/${params.meshVersion}/vocabulary_1.0.0.ttl
    """
}

process download_cito_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'cito.ttl'

    """
    wget http://purl.org/spar/cito.ttl 
    """
}

process download_fabio_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'fabio.ttl'

    """
    wget http://purl.org/spar/fabio.ttl
    """
}

process download_dublincore_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'dublin_core_terms.nt'

    """
    wget https://www.dublincore.org/specifications/dublin-core/dcmi-terms/dublin_core_terms.nt
    """
}

process download_cheminf_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'cheminf.owl'

    """
    wget http://purl.obolibrary.org/obo/cheminf.owl
    """
}

process download_skos_vocabulary {
    conda 'wget'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'skos.rdf'

    """
    wget https://www.w3.org/2009/08/skos-reference/skos.rdf
    """
}

process download_ChemOnt2_1_vocabulary {
    conda 'wget openjdk'
    storeDir "${vocabularydir}"
    maxRetries 3

    output:
        path 'ChemOnt_2_1.ttl'

    """
    # obo need to be transform to rdf
    # download robo : conversion tool
    wget https://github.com/ontodev/robot/releases/download/v1.9.2/robot.jar
    ## download
    wget -nc -O - http://classyfire.wishartlab.com/system/downloads/1_0/chemont/ChemOnt_2_1.obo.zip | zcat > ChemOnt_2_1.obo
    ## conversion obo ->ttl
    java -jar robot.jar convert -i ChemOnt_2_1.obo --format ttl -o ChemOnt_2_1.ttl
    """
}


process chemontVersion {
    conda 'wget'
    output: 
        stdout
    maxRetries 3

    script:

    '''
    html=$(wget -q -nc -O - http://classyfire.wishartlab.com/downloads | grep "20")
    pattern="<td>([0-9][0-9][0-9][0-9]-[0-9\\-]+)</td>"
    if [[ $html =~ $pattern ]]; then echo ${BASH_REMATCH[1]} ; else exit 2; fi
    '''
}


process build_upload_sh {
    storeDir params.rdfoutdir
    
    input:
        path mesh_vocabulary
        path skos
        path fabio
        path dublin_core_terms
        path cito
        path cheminf
        path chebi
        path chemOnt_2_1
        val chebi_version // 2023-02-01
        val chemont_version // 2016-08-27

    output:
        path 'upload.sh'

    """
    tee -a upload.sh << END
    GRANT SELECT ON "DB"."DBA"."SPARQL_SINV_2" TO "SPARQL";
    GRANT EXECUTE ON "DB"."DBA"."SPARQL_SINV_IMP" TO "SPARQL";
    DB.DBA.XML_REMOVE_NS_BY_PREFIX ('obo', 2);
    DB.DBA.XML_REMOVE_NS_BY_PREFIX ('mesh', 2);
    DB.DBA.XML_SET_NS_DECL ('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', 2);
    DB.DBA.XML_SET_NS_DECL ('rdfs', 'http://www.w3.org/2000/01/rdf-schema#', 2);
    DB.DBA.XML_SET_NS_DECL ('xsd', 'http://www.w3.org/2001/XMLSchema#', 2);
    DB.DBA.XML_SET_NS_DECL ('owl', 'http://www.w3.org/2002/07/owl#', 2);
    DB.DBA.XML_SET_NS_DECL ('meshv', 'http://id.nlm.nih.gov/mesh/vocab#', 2);
    DB.DBA.XML_SET_NS_DECL ('mesh', 'http://id.nlm.nih.gov/mesh/', 2);
    DB.DBA.XML_SET_NS_DECL ('voc', 'http://myorg.com/voc/doc#', 2);
    DB.DBA.XML_SET_NS_DECL ('SBMLrdf', 'http://identifiers.org/biomodels.vocabulary#', 2);
    DB.DBA.XML_SET_NS_DECL ('bqbiol', 'http://biomodels.net/biology-qualifiers#', 2);
    DB.DBA.XML_SET_NS_DECL ('chem', 'https://rdf.metanetx.org/chem/', 2);
    DB.DBA.XML_SET_NS_DECL ('mnx', 'https://rdf.metanetx.org/schema/', 2);
    DB.DBA.XML_SET_NS_DECL ('rhea', 'http://rdf.rhea-db.org/', 2);
    DB.DBA.XML_SET_NS_DECL ('keggR', 'https://identifiers.org/kegg.reaction:', 2);
    DB.DBA.XML_SET_NS_DECL ('compound', 'http://rdf.ncbi.nlm.nih.gov/pubchem/compound/', 2);
    DB.DBA.XML_SET_NS_DECL ('substance', 'http://rdf.ncbi.nlm.nih.gov/pubchem/substance/', 2);
    DB.DBA.XML_SET_NS_DECL ('descriptor', 'http://rdf.ncbi.nlm.nih.gov/pubchem/descriptor/', 2);
    DB.DBA.XML_SET_NS_DECL ('synonym', 'http://rdf.ncbi.nlm.nih.gov/pubchem/synonym/', 2);
    DB.DBA.XML_SET_NS_DECL ('inchikey', 'http://rdf.ncbi.nlm.nih.gov/pubchem/inchikey/', 2);
    DB.DBA.XML_SET_NS_DECL ('bioassay', 'http://rdf.ncbi.nlm.nih.gov/pubchem/bioassay/', 2);
    DB.DBA.XML_SET_NS_DECL ('measuregroup', 'http://rdf.ncbi.nlm.nih.gov/pubchem/measuregroup/', 2);
    DB.DBA.XML_SET_NS_DECL ('endpoint', 'http://rdf.ncbi.nlm.nih.gov/pubchem/endpoint/', 2);
    DB.DBA.XML_SET_NS_DECL ('reference', 'http://rdf.ncbi.nlm.nih.gov/pubchem/reference/', 2);
    DB.DBA.XML_SET_NS_DECL ('protein', 'http://rdf.ncbi.nlm.nih.gov/pubchem/protein/', 2);
    DB.DBA.XML_SET_NS_DECL ('conserveddomain', 'http://rdf.ncbi.nlm.nih.gov/pubchem/conserveddomain/', 2);
    DB.DBA.XML_SET_NS_DECL ('gene', 'http://rdf.ncbi.nlm.nih.gov/pubchem/gene/', 2);
    DB.DBA.XML_SET_NS_DECL ('pathway', 'http://rdf.ncbi.nlm.nih.gov/pubchem/pathway/', 2);
    DB.DBA.XML_SET_NS_DECL ('source', 'http://rdf.ncbi.nlm.nih.gov/pubchem/source/', 2);
    DB.DBA.XML_SET_NS_DECL ('concept', 'http://rdf.ncbi.nlm.nih.gov/pubchem/concept/', 2);
    DB.DBA.XML_SET_NS_DECL ('vocab', 'http://rdf.ncbi.nlm.nih.gov/pubchem/vocabulary#', 2);
    DB.DBA.XML_SET_NS_DECL ('obo', 'http://purl.obolibrary.org/obo/', 2);
    DB.DBA.XML_SET_NS_DECL ('sio', 'http://semanticscience.org/resource/', 2);
    DB.DBA.XML_SET_NS_DECL ('skos', 'http://www.w3.org/2004/02/skos/core#', 2);
    DB.DBA.XML_SET_NS_DECL ('bao', 'http://www.bioassayontology.org/bao#', 2);
    DB.DBA.XML_SET_NS_DECL ('bp', 'http://www.biopax.org/release/biopax-level3.owl#', 2);
    DB.DBA.XML_SET_NS_DECL ('ndfrt', 'http://evs.nci.nih.gov/ftp1/NDF-RT/NDF-RT.owl#', 2);
    DB.DBA.XML_SET_NS_DECL ('ncit', 'http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#', 2);
    DB.DBA.XML_SET_NS_DECL ('wikidata', 'http://www.wikidata.org/entity/', 2);
    DB.DBA.XML_SET_NS_DECL ('ops', 'http://www.openphacts.org/units/', 2);
    DB.DBA.XML_SET_NS_DECL ('cito', 'http://purl.org/spar/cito/', 2);
    DB.DBA.XML_SET_NS_DECL ('fabio', 'http://purl.org/spar/fabio/', 2);
    DB.DBA.XML_SET_NS_DECL ('uniprot', 'http://purl.uniprot.org/uniprot/', 2);
    DB.DBA.XML_SET_NS_DECL ('up', 'http://purl.uniprot.org/core/', 2);
    DB.DBA.XML_SET_NS_DECL ('pdbo', 'http://rdf.wwpdb.org/schema/pdbx-v40.owl#', 2);
    DB.DBA.XML_SET_NS_DECL ('pdbr', 'http://rdf.wwpdb.org/pdb/', 2);
    DB.DBA.XML_SET_NS_DECL ('taxonomy', 'http://identifiers.org/taxonomy/', 2);
    DB.DBA.XML_SET_NS_DECL ('reactome', 'http://identifiers.org/reactome/', 2);
    DB.DBA.XML_SET_NS_DECL ('chembl', 'http://rdf.ebi.ac.uk/resource/chembl/molecule/', 2);
    DB.DBA.XML_SET_NS_DECL ('chemblchembl', 'http://linkedchemistry.info/chembl/chemblid/', 2);
    DB.DBA.XML_SET_NS_DECL ('foaf', 'http://xmlns.com/foaf/0.1/', 2);
    DB.DBA.XML_SET_NS_DECL ('void', 'http://rdfs.org/ns/void#', 2);
    DB.DBA.XML_SET_NS_DECL ('dcterms', 'http://purl.org/dc/terms/', 2);
    DB.DBA.XML_SET_NS_DECL ('chemont', 'http://purl.obolibrary.org/obo/CHEMONTID_', 2);
    DB.DBA.XML_SET_NS_DECL ('chebi', 'http://purl.obolibrary.org/obo/CHEBI_', 2);
    delete from DB.DBA.load_list ;
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${mesh_vocabulary.fileName}', 'https://forum.semantic-metabolomics.org/inference-rules');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${skos.fileName}', 'https://forum.semantic-metabolomics.org/inference-rules');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${fabio.fileName}', 'https://forum.semantic-metabolomics.org/inference-rules');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${dublin_core_terms.fileName}', 'https://forum.semantic-metabolomics.org/inference-rules');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${cito.fileName}', 'https://forum.semantic-metabolomics.org/inference-rules');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${cheminf.fileName}', 'https://forum.semantic-metabolomics.org/inference-rules');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${chebi.fileName}', 'https://forum.semantic-metabolomics.org/ChEBI/${chebi_version.trim()}');
    ld_dir_all ('./dumps/${vocabularydir.split("/").last()}/', '${chemOnt_2_1.fileName}', 'https://forum.semantic-metabolomics.org/ChemOnt/${chemont_version.trim()}');
    select * from DB.DBA.load_list;
    rdf_loader_run();
    checkpoint;
    select * from DB.DBA.LOAD_LIST where ll_error IS NOT NULL;
    RDFS_RULE_SET ('schema-inference-rules', 'https://forum.semantic-metabolomics.org/inference-rules');
    RDFS_RULE_SET ('schema-inference-rules', 'https://forum.semantic-metabolomics.org/ChEBI/${chebi_version.trim()}');
    RDFS_RULE_SET ('schema-inference-rules', 'https://forum.semantic-metabolomics.org/ChemOnt/${chemont_version.trim()}');
    checkpoint;
    END
    """
}

workflow forum_vocabularies() {
    chebi = download_chebi_vocabulary()
    mesh = download_mesh_vocabulary()
    cito = download_cito_vocabulary()
    fabio = download_fabio_vocabulary()
    dublincore = download_dublincore_vocabulary()
    cheminf = download_cheminf_vocabulary()
    skos = download_skos_vocabulary()
    chemont = download_ChemOnt2_1_vocabulary()

    build_upload_sh(mesh,skos,fabio,dublincore,cito,cheminf,chebi,chemont,chebiVersion(),chemontVersion())
}
