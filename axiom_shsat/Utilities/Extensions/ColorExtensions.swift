import SwiftUI

extension Color {
    // MARK: - Custom App Colors
    
    /// Primary app brand color
    static let appPrimary = Color("AppPrimary", bundle: nil)
    
    /// Secondary app brand color
    static let appSecondary = Color("AppSecondary", bundle: nil)
    
    /// Accent app color
    static let appAccent = Color("AppAccent", bundle: nil)
    
    /// Background app color
    static let appBackground = Color("AppBackground", bundle: nil)
    
    // MARK: - Topic Colors
    
    /// Color for algebra topic
    static let algebraTopic = Color("AlgebraTopic", bundle: nil)
    
    /// Color for geometry topic
    static let geometryTopic = Color("GeometryTopic", bundle: nil)
    
    /// Color for numbers topic
    static let numbersTopic = Color("NumbersTopic", bundle: nil)
    
    /// Color for probability topic
    static let probabilityTopic = Color("ProbabilityTopic", bundle: nil)
    
    /// Color for general topic
    static let generalTopic = Color("GeneralTopic", bundle: nil)
    
    /// Get color for a specific topic
    static func forTopic(_ topic: String) -> Color {
        switch topic.lowercased() {
        case "algebra":
            return algebraTopic
        case "geometry":
            return geometryTopic
        case "numbers":
            return numbersTopic
        case "probability":
            return probabilityTopic
        default:
            return generalTopic
        }
    }
    
    // MARK: - Difficulty Colors
    
    /// Color for easy difficulty
    static let easyDifficulty = Color.green
    
    /// Color for medium difficulty
    static let mediumDifficulty = Color.orange
    
    /// Color for hard difficulty
    static let hardDifficulty = Color.red
    
    /// Get color for a specific difficulty
    static func forDifficulty(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy":
            return easyDifficulty
        case "medium":
            return mediumDifficulty
        case "hard":
            return hardDifficulty
        default:
            return .gray
        }
    }
    
    // MARK: - Performance Colors
    
    /// Color for excellent performance (80-100%)
    static let excellentPerformance = Color.green
    
    /// Color for good performance (60-80%)
    static let goodPerformance = Color.blue
    
    /// Color for average performance (40-60%)
    static let averagePerformance = Color.orange
    
    /// Color for poor performance (0-40%)
    static let poorPerformance = Color.red
    
    /// Get color based on performance percentage
    static func forPerformance(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<40:
            return poorPerformance
        case 40..<60:
            return averagePerformance
        case 60..<80:
            return goodPerformance
        default:
            return excellentPerformance
        }
    }
    
    // MARK: - Semantic Colors
    
    /// Success color
    static let success = Color.green
    
    /// Warning color
    static let warning = Color.orange
    
    /// Error color
    static let error = Color.red
    
    /// Info color
    static let info = Color.blue
    
    // MARK: - Color Creation
    
    /// Create a color from a hex string
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Get hex string representation of a color
    var hexString: String {
        let components = UIColor(self).cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
    
    // MARK: - Color Modifications
    
    /// Lighten a color by a percentage
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return adjust(by: abs(percentage))
    }
    
    /// Darken a color by a percentage
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return adjust(by: -abs(percentage))
    }
    
    /// Adjust a color by a percentage (positive to lighten, negative to darken)
    func adjust(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let adjustmentFactor = 1.0 + percentage / 100.0
            
            let newRed = min(max(red * adjustmentFactor, 0.0), 1.0)
            let newGreen = min(max(green * adjustmentFactor, 0.0), 1.0)
            let newBlue = min(max(blue * adjustmentFactor, 0.0), 1.0)
            
            return Color(red: Double(newRed), green: Double(newGreen), blue: Double(newBlue))
        }
        
        return self
    }
    
    /// Get a color with adjusted opacity
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
    
    // MARK: - Gradients
    
    /// Create a linear gradient from this color to another
    func gradient(to endColor: Color) -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [self, endColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Create a radial gradient from this color to another
    func radialGradient(to endColor: Color) -> RadialGradient {
        return RadialGradient(
            gradient: Gradient(colors: [self, endColor]),
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }
    
    /// Create a gradient with multiple colors
    static func gradient(colors: [Color], startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    // MARK: - Color Schemes
    
    /// Create a monochromatic color scheme from this color
    func monochromaticScheme(steps: Int = 5) -> [Color] {
        var colors: [Color] = []
        for i in 0..<steps {
            let percentage = CGFloat(i) * (100.0 / CGFloat(steps - 1)) - 50.0
            colors.append(adjust(by: percentage))
        }
        return colors
    }
    
    /// Create a complementary color
    var complementary: Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let complementaryHue = (hue + 0.5).truncatingRemainder(dividingBy: 1.0)
            return Color(UIColor(hue: complementaryHue, saturation: saturation, brightness: brightness, alpha: alpha))
        }
        
        return self
    }
}

// MARK: - Color Theme Extensions

struct ColorTheme {
    /// Primary brand color
    let primary: Color
    
    /// Secondary brand color
    let secondary: Color
    
    /// Accent brand color
    let accent: Color
    
    /// Background color
    let background: Color
    
    /// Text color for primary content
    let text: Color
    
    /// Text color for secondary content
    let secondaryText: Color
    
    /// Brand success color
    let success: Color
    
    /// Brand warning color
    let warning: Color
    
    /// Brand error color
    let error: Color
    
    /// Brand info color
    let info: Color
    
    /// Default light theme
    static let light = ColorTheme(
        primary: Color.blue,
        secondary: Color.purple,
        accent: Color.orange,
        background: Color(UIColor.systemBackground),
        text: Color.primary,
        secondaryText: Color.secondary,
        success: Color.green,
        warning: Color.orange,
        error: Color.red,
        info: Color.blue
    )
    
    /// Default dark theme
    static let dark = ColorTheme(
        primary: Color.blue.lighter(by: 10),
        secondary: Color.purple.lighter(by: 10),
        accent: Color.orange.lighter(by: 10),
        background: Color(UIColor.systemBackground),
        text: Color.primary,
        secondaryText: Color.secondary,
        success: Color.green.lighter(by: 10),
        warning: Color.orange.lighter(by: 10),
        error: Color.red.lighter(by: 10),
        info: Color.blue.lighter(by: 10)
    )
    
    /// Get the current theme based on color scheme
    static func current(for colorScheme: ColorScheme) -> ColorTheme {
        return colorScheme == .dark ? dark : light
    }
}

// MARK: - Environment Extension

struct ColorThemeKey: EnvironmentKey {
    static let defaultValue = ColorTheme.light
}

extension EnvironmentValues {
    var colorTheme: ColorTheme {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}

extension View {
    /// Apply the color theme to the view hierarchy
    func colorTheme(_ theme: ColorTheme) -> some View {
        environment(\.colorTheme, theme)
    }
    
    /// Apply the appropriate color theme based on the current color scheme
    func adaptiveColorTheme(for colorScheme: ColorScheme) -> some View {
        colorTheme(ColorTheme.current(for: colorScheme))
    }
}
