import Foundation
import SwiftData

@Model
final class Lemma {
    // MARK: - Attributes
    @Attribute(.unique) var lemmaId: String
    var lemma: String                         // The headword, e.g., "كَتَبَ"
    
    /// Register classification from Qabas: "فصحى حديثة" (MSA), "عامية" (colloquial), "أجنبية" (foreign).
    /// Note: This is register, not dialect. All values map to MSA for dialect queries.
    /// Actual dialect association for forms comes from corpus provenance.
    var language: String
    
    var posCategory: String                   // "اسم", "فعل", "كلمة وظيفية"
    var pos: String                           // Detailed POS tag
    
    // Morphological features
    var augmentation: String?                 // "مجرد", "مزيد"
    var number: String?                       // "مفرد", "مثنى", "جمع"
    var person: String?                       // "متكلم", "مخاطب", "غائب"
    var gender: String?                       // "مذكر", "مؤنث"
    var voice: String?                        // "معلوم", "مجهول"
    var transitivity: String?                 // "متعد", "لازم"
    var uninflected: Bool                     // Does not inflect
    
    // MARK: - Relationships
    var rootRef: Root?
    var dialect: Dialect?
    var concepts: [Concept] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Form.lemma)
    var forms: [Form] = []
    
    @Relationship(deleteRule: .cascade, inverse: \GlossIndexEntry.lemma)
    var glossEntries: [GlossIndexEntry] = []
    
    /// Symmetric correspondence with other lemmas across dialects
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
    
    /// Whether this is an MSA lemma
    var isMSA: Bool {
        language == "فصحى حديثة"
    }
    
    /// Whether this is a dialect lemma
    var isDialect: Bool {
        language == "عامية"
    }
    
    /// Whether this is a foreign loanword
    var isForeign: Bool {
        language == "أجنبية"
    }
    
    /// POS category in English
    var posCategoryEnglish: String {
        switch posCategory {
        case "اسم": return "Noun"
        case "فعل": return "Verb"
        case "كلمة وظيفية": return "Function Word"
        default: return posCategory
        }
    }
}
