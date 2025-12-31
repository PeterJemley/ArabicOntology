import Foundation
import SwiftData

@Model
final class GlossIndexEntry {
    @Attribute(.unique) var key: String
    var token: String
    var lemma: Lemma?
    
    init(key: String, token: String, lemma: Lemma?) {
        self.key = key
        self.token = token
        self.lemma = lemma
    }
}
