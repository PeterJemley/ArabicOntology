import Foundation
import SwiftData

/// Denormalized index entry that maps an English gloss token to a lemma.
/// This enables fast English searches without scanning all forms.
@Model
final class GlossIndexEntry {
    /// Unique key composed of token and lemma ID (token|lemmaId).
    @Attribute(.unique) var key: String
    /// Normalized English token used for lookup.
    var token: String
    /// Target lemma for this token.
    var lemma: Lemma?
    
    init(key: String, token: String, lemma: Lemma?) {
        self.key = key
        self.token = token
        self.lemma = lemma
    }
}
