import Foundation
import SwiftData

/// A single attested word form from a corpus dataset row.
/// Forms are the link between dialectal surface tokens and lemmas.
@Model
final class Form {
    // MARK: - Attributes
    /// Stable deduplication key (dialectCode:sentenceId:wordPosition).
    @Attribute(.unique) var formKey: String
    /// Normalized form token (Token column, or CODA for Syrian/Nabra).
    var token: String
    /// Original token before normalization, when provided.
    var rawToken: String?
    /// English gloss text, when provided.
    var gloss: String?
    /// Part-of-speech tag from the corpus.
    var pos: String?
    /// Prefix analysis string from the corpus.
    var prefixes: String?
    /// Stem after affix removal.
    var stem: String?
    /// Suffix analysis string from the corpus.
    var suffixes: String?
    /// Position within the sentence (as reported by the corpus).
    var wordPosition: Int
    
    // Grammatical features
    /// Person feature code (for example, "1", "2", "3").
    var personFeature: String?
    /// Gender feature code (for example, "m", "f").
    var genderFeature: String?
    /// Number feature code (for example, "s", "d", "p").
    var numberFeature: String?
    
    // Nabra-specific
    /// Syrian subdialect label (Nabra only).
    var subdialect: String?
    
    // MARK: - Relationships
    
    /// Dialect lemma this form realizes (DA lemma).
    var lemma: Lemma?
    
    /// MSA lemma this form corresponds to, when linked.
    var msaLemma: Lemma?
    
    /// Dialect this form is attested in.
    var dialect: Dialect?
    
    /// Sentence containing this form.
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
    
    /// Compact person/gender/number feature string.
    var features: String {
        [personFeature, genderFeature, numberFeature]
            .compactMap { $0 }
            .joined(separator: ".")
    }
    
    /// Gender label in English, when recognized.
    var genderEnglish: String? {
        switch genderFeature {
        case "m": return "masculine"
        case "f": return "feminine"
        default: return nil
        }
    }
    
    /// Number label in English, when recognized.
    var numberEnglish: String? {
        switch numberFeature {
        case "s": return "singular"
        case "d": return "dual"
        case "p": return "plural"
        default: return nil
        }
    }
}
