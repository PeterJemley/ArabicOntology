import Foundation
import SwiftData

/// Consonantal root from Qabas (space-delimited consonants).
@Model
final class Root {
    // MARK: - Attributes
    /// Root string with consonants separated by spaces.
    @Attribute(.unique) var root: String
    
    // MARK: - Relationships
    /// Lemmas that share this root.
    @Relationship(deleteRule: .nullify, inverse: \Lemma.rootRef)
    var lemmas: [Lemma] = []
    
    // MARK: - Initialization
    init(root: String) {
        self.root = root
    }
    
    // MARK: - Computed Properties
    
    /// Root consonants split on spaces.
    var consonants: [String] {
        root.split(separator: " ").map(String.init)
    }
    
    /// Number of consonants (typically 3 or 4).
    var consonantCount: Int {
        consonants.count
    }
}
