import Foundation
import SwiftData

/// Sentence record imported from a corpus sentence file.
@Model
final class Sentence {
    // MARK: - Attributes
    /// Unique identifier (dialectCode:sentenceId) to avoid cross-corpus collisions.
    @Attribute(.unique) var sentenceId: String
    /// Raw sentence text from the corpus.
    var text: String
    
    // MARK: - Relationships
    /// Dialect associated with the sentence source.
    var dialect: Dialect?
    
    @Relationship(deleteRule: .cascade, inverse: \Form.sentence)
    /// Forms (tokens) belonging to this sentence.
    var forms: [Form] = []
    
    // MARK: - Initialization
    init(sentenceId: String, text: String) {
        self.sentenceId = sentenceId
        self.text = text
    }
    
    // MARK: - Computed Properties
    
    /// Number of tokens in this sentence.
    var tokenCount: Int {
        forms.count
    }
    
    /// Forms sorted by word position for display.
    var orderedForms: [Form] {
        forms.sorted { $0.wordPosition < $1.wordPosition }
    }
}
