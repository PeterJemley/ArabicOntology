import Foundation

/// Normalizes Arabic text for matching purposes
enum ArabicNormalizer {
    
    // MARK: - Unicode Ranges
    
    /// Arabic diacritics (tashkeel) - U+064B to U+065F, plus U+0670
    private static let diacriticPattern = "[\\u064B-\\u065F\\u0670]"
    
    /// Alef variants: أ إ آ → ا
    private static let alefVariants: [Character: Character] = [
        "\u{0622}": "\u{0627}",  // آ → ا
        "\u{0623}": "\u{0627}",  // أ → ا
        "\u{0625}": "\u{0627}"   // إ → ا
    ]
    
    /// Alef maqsura → yeh: ى → ي
    private static let alefMaqsura: Character = "\u{0649}"
    private static let yeh: Character = "\u{064A}"
    
    // MARK: - Normalization
    
    /// Full normalization for matching: removes diacritics, normalizes alef/yeh
    static func normalize(_ text: String) -> String {
        var result = text
        
        // Remove diacritics
        result = removeDiacritics(result)
        
        // Normalize alef variants
        result = normalizeAlef(result)
        
        // Normalize alef maqsura
        result = normalizeAlefMaqsura(result)
        
        // Trim whitespace
        result = result.trimmingCharacters(in: .whitespaces)
        
        return result
    }
    
    /// Remove tashkeel (diacritical marks)
    static func removeDiacritics(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: diacriticPattern) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }
    
    /// Normalize alef variants to plain alef
    static func normalizeAlef(_ text: String) -> String {
        var result = ""
        for char in text {
            if let normalized = alefVariants[char] {
                result.append(normalized)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    /// Normalize alef maqsura to yeh
    static func normalizeAlefMaqsura(_ text: String) -> String {
        var result = ""
        for char in text {
            if char == alefMaqsura {
                result.append(yeh)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    // MARK: - Matching
    
    /// Check if two strings match after normalization
    static func matches(_ a: String, _ b: String) -> Bool {
        normalize(a) == normalize(b)
    }
    
    /// Check if normalized text contains normalized query
    static func contains(_ text: String, query: String) -> Bool {
        normalize(text).contains(normalize(query))
    }
}
