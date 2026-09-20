import SwiftUI

/// Barbechero tokens (docs/design-system.md): warm paper, one warm ink
/// carried by alpha, a single terracotta accent, hairline rules.
struct Palette {
    let paper: Color
    let paperDeep: Color
    let paperEdge: Color
    let ink: Color
    let accent: Color

    var muted: Color { ink.opacity(0.55) }
    var faint: Color { ink.opacity(0.45) }
    var rule: Color { ink.opacity(0.25) }
    var ruleStrong: Color { ink }

    static let light = Palette(
        paper: Color(red: 0xF7 / 255, green: 0xF5 / 255, blue: 0xEE / 255),
        paperDeep: Color(red: 0xEF / 255, green: 0xEA / 255, blue: 0xE0 / 255),
        paperEdge: Color(red: 0xE6 / 255, green: 0xDF / 255, blue: 0xD0 / 255),
        ink: Color(red: 0x21 / 255, green: 0x1D / 255, blue: 0x17 / 255),
        accent: Color(red: 0x9D / 255, green: 0x50 / 255, blue: 0x35 / 255)
    )

    /// The manual defines no dark scheme; this keeps its relationships —
    /// warm ground, paper-colored ink, the accent lifted for contrast.
    static let dark = Palette(
        paper: Color(red: 0x1B / 255, green: 0x18 / 255, blue: 0x13 / 255),
        paperDeep: Color(red: 0x26 / 255, green: 0x20 / 255, blue: 0x19 / 255),
        paperEdge: Color(red: 0x2E / 255, green: 0x28 / 255, blue: 0x20 / 255),
        ink: Color(red: 0xF4 / 255, green: 0xF0 / 255, blue: 0xE6 / 255),
        accent: Color(red: 0xCB / 255, green: 0x7A / 255, blue: 0x5D / 255)
    )

    static func forScheme(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }
}

extension Font {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .semibold: return .custom("Spectral-SemiBold", size: size)
        case .light: return .custom("Spectral-Light", size: size)
        default: return .custom("Spectral-Regular", size: size)
        }
    }

    static var serifItalic: (CGFloat) -> Font = { .custom("Spectral-Italic", size: $0) }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        weight == .medium
            ? .custom("IBMPlexMono-Medium", size: size)
            : .custom("IBMPlexMono-Regular", size: size)
    }
}
