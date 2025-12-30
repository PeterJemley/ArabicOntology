import Foundation
import SwiftData

@Model
final class Sentence {
    // MARK: - Attributes
    @Attribute(.unique) var sentenceId: String
    var text: String
    
    // MARK: - Relationships
    var dialect: Dialect?
    
    @Relationship(deleteRule: .cascade, inverse: \Form.sentence)
    var forms: [Form] = []
    
    // MARK: - Initialization
    init(sentenceId: String, text: String) {
        self.sentenceId = sentenceId
        self.text = text
    }
    
    // MARK: - Computed Properties
    
    /// Number of tokens in this sentence
    var tokenCount: Int {
        forms.count
    }
    
    /// Forms sorted by position
    var orderedForms: [Form] {
        forms.sorted { $0.wordPosition < $1.wordPosition }
    }
}
