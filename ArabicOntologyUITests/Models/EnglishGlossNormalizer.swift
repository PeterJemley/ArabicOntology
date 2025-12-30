import Foundation

struct EnglishGlossNormalizer {
    static func tokens(from text: String) -> [String] {
        let lowercased = text.lowercased()
        var scalars = String.UnicodeScalarView()
        scalars.reserveCapacity(lowercased.unicodeScalars.count)
        
        for scalar in lowercased.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                scalars.append(scalar)
            } else {
                scalars.append(" ")
            }
        }
        
        let cleaned = String(scalars)
        return cleaned
            .split { $0 == " " || $0 == "\t" || $0 == "\n" }
            .map(String.init)
    }
}
