import AppKit
import SwiftUI

enum AppFontScale {
    static let global: CGFloat = 1.6
    static let headword: CGFloat = 1.2

    static func font(_ style: Font.TextStyle, scale: CGFloat = global, weight: Font.Weight? = nil) -> Font {
        let baseSize = NSFont.preferredFont(forTextStyle: nsTextStyle(for: style)).pointSize
        if let weight {
            return .system(size: baseSize * scale, weight: weight)
        }
        return .system(size: baseSize * scale)
    }

    private static func nsTextStyle(for style: Font.TextStyle) -> NSFont.TextStyle {
        switch style {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title1
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline:
            return .headline
        case .subheadline:
            return .subheadline
        case .body:
            return .body
        case .callout:
            return .callout
        case .caption:
            return .caption1
        case .caption2:
            return .caption2
        case .footnote:
            return .footnote
        @unknown default:
            return .body
        }
    }
}
