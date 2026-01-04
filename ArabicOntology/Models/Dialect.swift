import Foundation
import SwiftData

/// Dialect or register bucket used to group lemmas, forms, and sentences.
/// Dialects are seeded from a predefined list and referenced by code.
@Model
final class Dialect {
    // MARK: - Attributes
    /// Stable dialect code (for example, "lebanese", "msa").
    @Attribute(.unique) var code: String
    /// Display name used in the UI.
    var name: String
    /// Regional grouping label (for example, "Levant", "Standard").
    var region: String
    /// Source corpus that defines or supplies this dialect.
    var corpusSource: String
    
    // MARK: - Relationships
    /// Lemmas assigned to this dialect (Qabas register values map to MSA).
    @Relationship(deleteRule: .nullify, inverse: \Lemma.dialect)
    var lemmas: [Lemma] = []
    
    /// Corpus forms attested in this dialect.
    @Relationship(deleteRule: .nullify, inverse: \Form.dialect)
    var forms: [Form] = []
    
    /// Sentences originating from this dialect's corpus.
    @Relationship(deleteRule: .nullify, inverse: \Sentence.dialect)
    var sentences: [Sentence] = []
    
    // MARK: - Initialization
    init(code: String, name: String, region: String, corpusSource: String) {
        self.code = code
        self.name = name
        self.region = region
        self.corpusSource = corpusSource
    }
    
    // MARK: - Predefined Dialects
    
    static let predefined: [(code: String, name: String, region: String, corpusSource: String)] = [
        ("msa", "Modern Standard Arabic", "Standard", "Qabas"),
        ("lebanese", "Lebanese", "Levant", "Baladi"),
        ("syrian", "Syrian", "Levant", "Nabra"),
        ("palestinian", "Palestinian", "Levant", "Curras"),
        ("iraqi", "Iraqi", "Mesopotamia", "Lisan-Iraqi"),
        ("libyan", "Libyan", "Maghreb", "Lisan-Libyan"),
        ("sudanese", "Sudanese", "Nile Valley", "Lisan-Sudanese"),
        ("yemeni", "Yemeni", "Arabian Peninsula", "Lisan-Yemeni")
    ]
}
