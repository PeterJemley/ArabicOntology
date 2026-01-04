import Foundation
import SwiftData

/// Ontology concept (synset) imported from Concepts.csv.
/// The synset fields are pipe-delimited term lists that support lookup and
/// linking to lemmas.
@Model
final class Concept {
    // MARK: - Attributes
    /// Stable concept identifier referenced in Concepts.csv and Relations.csv.
    @Attribute(.unique) var conceptId: String
    /// Pipe-delimited Arabic synset terms (e.g., "term1|term2").
    var arabicSynset: String
    /// Optional pipe-delimited English synset terms.
    var englishSynset: String?
    /// Optional English gloss/definition text.
    var gloss: String?
    /// Optional example sentence or usage.
    var example: String?
    /// Source/curation indicator carried through from the source dataset.
    var dataSourceId: Int
    
    // MARK: - Relationships
    /// Parent concept (null for root-level concepts).
    var parent: Concept?
    
    @Relationship(deleteRule: .nullify, inverse: \Concept.parent)
    /// Child concepts (inverse of parent).
    var children: [Concept] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Lemma.concepts)
    /// Lemmas linked to this concept via normalized term matching.
    var lemmas: [Lemma] = []
    
    // MARK: - Initialization
    init(
        conceptId: String,
        arabicSynset: String,
        englishSynset: String? = nil,
        gloss: String? = nil,
        example: String? = nil,
        dataSourceId: Int = 0
    ) {
        self.conceptId = conceptId
        self.arabicSynset = arabicSynset
        self.englishSynset = englishSynset
        self.gloss = gloss
        self.example = example
        self.dataSourceId = dataSourceId
    }
    
    // MARK: - Computed Properties
    
    /// Arabic synset terms split on "|" with whitespace trimmed.
    var arabicTerms: [String] {
        arabicSynset.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    /// English synset terms split on "|" with whitespace trimmed.
    var englishTerms: [String] {
        englishSynset?.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
    }
    
    /// Data quality flag for curated concepts.
    var isWellDesigned: Bool {
        dataSourceId == 200
    }
}
