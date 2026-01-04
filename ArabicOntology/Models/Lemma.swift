import Foundation
import SwiftData

/// Canonical lemma entry imported from Qabas.
/// Lemmas are the primary headwords used for search and linkage.
@Model
final class Lemma {
    // MARK: - Attributes
    /// Stable lemma identifier from Qabas.
    @Attribute(.unique) var lemmaId: String
    /// Headword text for the lemma.
    var lemma: String
    
    /// Register classification from Qabas.
    /// Note: This is register, not dialect. Values map to MSA for dialect queries.
    /// Actual dialect association for forms comes from corpus provenance.
    var language: String
    
    /// High-level POS category from Qabas.
    var posCategory: String
    /// Detailed POS tag from Qabas.
    var pos: String
    
    // Morphological features
    /// Augmentation class from Qabas.
    var augmentation: String?
    /// Number value from Qabas.
    var number: String?
    /// Person value from Qabas.
    var person: String?
    /// Gender value from Qabas.
    var gender: String?
    /// Voice value from Qabas.
    var voice: String?
    /// Transitivity value from Qabas.
    var transitivity: String?
    /// True when the lemma does not inflect.
    var uninflected: Bool
    
    // MARK: - Relationships
    /// Root assigned from Qabas, when provided.
    var rootRef: Root?
    /// Dialect bucket (Qabas register values map to MSA).
    var dialect: Dialect?
    /// Concepts linked via normalized synset matching.
    var concepts: [Concept] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Form.lemma)
    /// Corpus forms that realize this lemma as a dialectal headword.
    var forms: [Form] = []
    
    @Relationship(deleteRule: .cascade, inverse: \GlossIndexEntry.lemma)
    /// English gloss index entries pointing to this lemma.
    var glossEntries: [GlossIndexEntry] = []
    
    /// Symmetric correspondence with other lemmas across dialects.
    var correspondences: [Lemma] = []
    
    // MARK: - Initialization
    init(
        lemmaId: String,
        lemma: String,
        language: String,
        posCategory: String,
        pos: String,
        augmentation: String? = nil,
        number: String? = nil,
        person: String? = nil,
        gender: String? = nil,
        voice: String? = nil,
        transitivity: String? = nil,
        uninflected: Bool = false
    ) {
        self.lemmaId = lemmaId
        self.lemma = lemma
        self.language = language
        self.posCategory = posCategory
        self.pos = pos
        self.augmentation = augmentation
        self.number = number
        self.person = person
        self.gender = gender
        self.voice = voice
        self.transitivity = transitivity
        self.uninflected = uninflected
    }
    
    // MARK: - Computed Properties
    
    /// Whether this lemma is tagged as MSA register.
    var isMSA: Bool {
        language == "فصحى حديثة"
    }
    
    /// Whether this lemma is tagged as colloquial register.
    var isDialect: Bool {
        language == "عامية"
    }
    
    /// Whether this lemma is tagged as a foreign loanword.
    var isForeign: Bool {
        language == "أجنبية"
    }
    
    /// POS category in English for UI display.
    var posCategoryEnglish: String {
        switch posCategory {
        case "اسم": return "Noun"
        case "فعل": return "Verb"
        case "كلمة وظيفية": return "Function Word"
        default: return posCategory
        }
    }
}
