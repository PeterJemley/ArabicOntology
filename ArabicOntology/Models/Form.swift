import Foundation
import SwiftData

@Model
final class Form {
    // MARK: - Attributes
    @Attribute(.unique) var formKey: String   // Stable key for de-dup across imports
    var token: String                         // Normalized form (Token or CODA)
    var rawToken: String?                     // Original form before normalization
    var gloss: String?                        // English rendering
    var pos: String?                          // POS tag
    var prefixes: String?                     // Prefix analysis
    var stem: String?                         // Stem after affix removal
    var suffixes: String?                     // Suffix analysis
    var wordPosition: Int                     // Position in sentence
    
    // Grammatical features
    var personFeature: String?                // "1", "2", "3"
    var genderFeature: String?                // "m", "f"
    var numberFeature: String?                // "s", "d", "p"
    
    // Nabra-specific
    var subdialect: String?                   // Syrian subdialect (Nabra only)
    
    // MARK: - Relationships
    
    /// The dialect lemma this form realizes
    var lemma: Lemma?
    
    /// The MSA lemma this form corresponds to
    var msaLemma: Lemma?
    
    /// The dialect this form is attested in
    var dialect: Dialect?
    
    /// The sentence containing this form
    var sentence: Sentence?
    
    // MARK: - Initialization
    init(
        formKey: String,
        token: String,
        rawToken: String? = nil,
        gloss: String? = nil,
        pos: String? = nil,
        prefixes: String? = nil,
        stem: String? = nil,
        suffixes: String? = nil,
        wordPosition: Int = 0,
        personFeature: String? = nil,
        genderFeature: String? = nil,
        numberFeature: String? = nil,
        subdialect: String? = nil
    ) {
        self.formKey = formKey
        self.token = token
        self.rawToken = rawToken
        self.gloss = gloss
        self.pos = pos
        self.prefixes = prefixes
        self.stem = stem
        self.suffixes = suffixes
        self.wordPosition = wordPosition
        self.personFeature = personFeature
        self.genderFeature = genderFeature
        self.numberFeature = numberFeature
        self.subdialect = subdialect
    }
    
    // MARK: - Computed Properties
    
    /// Full grammatical feature string
    var features: String {
        [personFeature, genderFeature, numberFeature]
            .compactMap { $0 }
            .joined(separator: ".")
    }
    
    /// Gender in English
    var genderEnglish: String? {
        switch genderFeature {
        case "m": return "masculine"
        case "f": return "feminine"
        default: return nil
        }
    }
    
    /// Number in English
    var numberEnglish: String? {
        switch numberFeature {
        case "s": return "singular"
        case "d": return "dual"
        case "p": return "plural"
        default: return nil
        }
    }
}
