import Foundation
import SwiftData

@Model
final class Concept {
    // MARK: - Attributes
    @Attribute(.unique) var conceptId: String
    var arabicSynset: String
    var englishSynset: String?
    var gloss: String?
    var example: String?
    var dataSourceId: Int
    
    // MARK: - Relationships
    var parent: Concept?
    
    @Relationship(deleteRule: .nullify, inverse: \Concept.parent)
    var children: [Concept] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Lemma.concepts)
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
    
    /// Synset terms split into array
    var arabicTerms: [String] {
        arabicSynset.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var englishTerms: [String] {
        englishSynset?.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
    }
    
    /// Whether this is a well-designed concept (dataSourceId = 200)
    var isWellDesigned: Bool {
        dataSourceId == 200
    }
}
