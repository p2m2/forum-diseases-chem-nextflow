include { forum_vocabularies } from './forum-vocabularies.nf'
include { forum_mesh } from './forum-MeSH'
include { forum_MetaNetX } from './forum-MetaNetX'
include { forum_PubChemMin } from './forum-PubChem-min'
include { forum_PMID_CID } from './forum-PMID-CID'


workflow {
    forum_vocabularies()
    forum_mesh()
    forum_MetaNetX()
    forum_PubChemMin()
    forum_PMID_CID()

    /*
    pubchemVersion = build_import_PubChemMin(rdfoutdir,logdir,config_import_PubChemMin(),appDir)
                        .map(file -> file.baseName)


    versionFORUM = getDate()
    build_import_PMIDCID( rdfoutdir,logdir, config_import_PMIDCID(versionFORUM,pubchemVersion), appDir)
    */
}