import Foundation
import SwiftData

@Model
final class Dialect {
    // MARK: - Attributes
    @Attribute(.unique) var code: String      // e.g., "lebanese", "msa"
    var name: String                          // e.g., "Lebanese", "Modern Standard Arabic"
    var region: String                        // e.g., "Levant", "Standard"
    var corpusSource: String                  // e.g., "Baladi", "Qabas"
    
    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Lemma.dialect)
    var lemmas: [Lemma] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Form.dialect)
    var forms: [Form] = []
    
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
