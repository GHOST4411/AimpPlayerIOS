import SwiftUI

/// Paleta de colores y estilos fieles a AIMP Móvil (Android)
enum AimpTheme {
    // Colores de fondo
    static let background = Color(hex: "121212")
    static let surface = Color(hex: "1C1C1E")
    static let cardBackground = Color(hex: "252528")
    
    // Color característico de AIMP: Naranja Ámbar vibrante
    static let primary = Color(hex: "FF8F00")
    static let primaryLight = Color(hex: "FFA726")
    static let primaryDark = Color(hex: "E65100")
    
    // Textos
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0A5")
    static let textMuted = Color(hex: "68686E")
    
    // Controles y divisores
    static let divider = Color(hex: "2C2C2E")
    static let sliderTrack = Color(hex: "3A3A3C")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
