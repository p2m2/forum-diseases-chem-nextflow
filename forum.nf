include { forum_vocabularies } from './forum-vocabularies.nf'
include { forum_mesh } from './forum-MeSH'
include { forum_MetaNetX } from './forum-MetaNetX'
include { forum_PubChemMin } from './forum-PubChem-min'
include { forum_PMID_CID } from './forum-PMID-CID'


workflow {
    forum_vocabularies |
    forum_mesh |
    forum_MetaNetX |
    forum_PubChemMin |
    forum_PMID_CID 
}