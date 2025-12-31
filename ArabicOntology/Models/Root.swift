import Foundation
import SwiftData

@Model
final class Root {
    // MARK: - Attributes
    @Attribute(.unique) var root: String  // e.g., "ك ت ب"
    
    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Lemma.rootRef)
    var lemmas: [Lemma] = []
    
    // MARK: - Initialization
    init(root: String) {
        self.root = root
    }
    
    // MARK: - Computed Properties
    
    /// Root consonants as array
    var consonants: [String] {
        root.split(separator: " ").map(String.init)
    }
    
    /// Number of consonants (typically 3 or 4)
    var consonantCount: Int {
        consonants.count
    }
}
