import Foundation
import SwiftUI

/// Utility class for formatting and processing mathematical expressions
class MathFormatter {
    /// Shared instance for convenience
    static let shared = MathFormatter()
    
    /// Available math notation formats
    enum NotationFormat {
        case latex        // LaTeX notation (e.g., "$x^2 + 3x + 2$")
        case asciiMath    // ASCII math notation (e.g., "x^2 + 3x + 2")
        case plainText    // Plain text (e.g., "x² + 3x + 2")
    }
    
    /// Converts mathematical notation between different formats
    func convert(expression: String, from sourceFormat: NotationFormat, to targetFormat: NotationFormat) -> String {
        // This is a simplified implementation - in a real app, this would use a more sophisticated
        // parser to convert between notation formats
        
        switch (sourceFormat, targetFormat) {
        case (.latex, .asciiMath):
            return convertLatexToAsciiMath(expression)
        case (.latex, .plainText):
            return convertLatexToPlainText(expression)
        case (.asciiMath, .latex):
            return convertAsciiMathToLatex(expression)
        case (.asciiMath, .plainText):
            return convertAsciiMathToPlainText(expression)
        case (.plainText, .latex):
            return convertPlainTextToLatex(expression)
        case (.plainText, .asciiMath):
            return convertPlainTextToAsciiMath(expression)
        default:
            // Same format, no conversion needed
            return expression
        }
    }
    
    /// Removes LaTeX delimiters ($ symbols) from an expression
    func removeLatexDelimiters(from expression: String) -> String {
        var result = expression
        
        // Remove opening and closing $ delimiters
        if result.hasPrefix("$") {
            result.removeFirst()
        }
        if result.hasSuffix("$") {
            result.removeLast()
        }
        
        // Remove opening and closing $$ delimiters
        if result.hasPrefix("$$") {
            result.removeFirst(2)
        }
        if result.hasSuffix("$$") {
            result.removeLast(2)
        }
        
        return result
    }
    
    /// Adds LaTeX delimiters to an expression if needed
    func addLatexDelimiters(to expression: String) -> String {
        if expression.hasPrefix("$") || expression.hasPrefix("$$") {
            // Already has delimiters
            return expression
        }
        return "$" + expression + "$"
    }
    
    /// Checks if a string contains LaTeX math notation
    func containsLatexMath(_ text: String) -> Bool {
        // Simple check for common LaTeX patterns
        let patterns = [
            "\\\\frac", "\\\\sqrt", "\\\\sum", "\\\\int", "\\\\prod",
            "\\\\alpha", "\\\\beta", "\\\\gamma", "\\\\delta",
            "\\^\\{[^\\}]*\\}", "\\_{[^\\}]*\\}"
        ]
        
        return patterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
    
    /// Splits a text that contains both regular text and LaTeX math into components
    func splitTextAndMath(mixedText: String) -> [MathTextComponent] {
        var components: [MathTextComponent] = []
        var currentText = ""
        
        // Simple delimiter-based parsing - for a real app you'd want a more robust parser
        var insideMath = false
        var mathDelimiter = ""
        
        for char in mixedText {
            if char == "$" {
                if insideMath {
                    // Check if this is the closing delimiter
                    if mathDelimiter == "$" {
                        // End of inline math
                        if !currentText.isEmpty {
                            components.append(.math(currentText))
                            currentText = ""
                        }
                        insideMath = false
                        mathDelimiter = ""
                    } else if mathDelimiter == "$$" && mixedText.suffix(from: mixedText.firstIndex(of: char)!).hasPrefix("$") {
                        // End of display math
                        if !currentText.isEmpty {
                            components.append(.math(currentText))
                            currentText = ""
                        }
                        insideMath = false
                        mathDelimiter = ""
                    } else {
                        // Just a dollar sign within math
                        currentText.append(char)
                    }
                } else {
                    // Start of math
                    if !currentText.isEmpty {
                        components.append(.text(currentText))
                        currentText = ""
                    }
                    insideMath = true
                    mathDelimiter = "$"
                    
                    // Check if this is display math ($$)
                    if mixedText.suffix(from: mixedText.firstIndex(of: char)!).hasPrefix("$$") {
                        mathDelimiter = "$$"
                    }
                }
            } else {
                currentText.append(char)
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            if insideMath {
                components.append(.math(currentText))
            } else {
                components.append(.text(currentText))
            }
        }
        
        return components
    }
    
    /// Format a fraction in LaTeX
    func formatFraction(numerator: String, denominator: String) -> String {
        return "\\frac{\(numerator)}{\(denominator)}"
    }
    
    /// Format a square root in LaTeX
    func formatSquareRoot(expression: String) -> String {
        return "\\sqrt{\(expression)}"
    }
    
    /// Format an nth root in LaTeX
    func formatNthRoot(expression: String, n: Int) -> String {
        return "\\sqrt[\(n)]{\(expression)}"
    }
    
    /// Format a summation in LaTeX
    func formatSummation(expression: String, lowerLimit: String, upperLimit: String) -> String {
        return "\\sum_{\(lowerLimit)}^{\(upperLimit)}{\(expression)}"
    }
    
    /// Format an integral in LaTeX
    func formatIntegral(expression: String, lowerLimit: String, upperLimit: String) -> String {
        return "\\int_{\(lowerLimit)}^{\(upperLimit)}{\(expression)}"
    }
    
    /// Format a limit in LaTeX
    func formatLimit(expression: String, variable: String, limit: String) -> String {
        return "\\lim_{\(variable) \\to \(limit)}{\(expression)}"
    }
    
    /// Format a matrix in LaTeX
    func formatMatrix(rows: [[String]]) -> String {
        let rowsText = rows.map { row in
            row.joined(separator: " & ")
        }.joined(separator: " \\\\ ")
        
        return "\\begin{bmatrix} \(rowsText) \\end{bmatrix}"
    }
    
    /// Format a system of equations in LaTeX
    func formatSystem(equations: [String]) -> String {
        let equationsText = equations.joined(separator: " \\\\ ")
        return "\\begin{cases} \(equationsText) \\end{cases}"
    }
    
    /// Convert a decimal to a fraction in LaTeX
    func decimalToLatexFraction(_ decimal: Double, precision: Double = 0.0001) -> String {
        // Handle special cases
        if decimal.isNaN || decimal.isInfinite {
            return decimal.description
        }
        
        // Use continued fraction algorithm for conversion
        var n = abs(decimal)
        var a = floor(n)
        var h1 = 1.0
        var h2 = 0.0
        var k1 = 0.0
        var k2 = 1.0
        var h = a * h1 + h2
        var k = a * k1 + k2
        
        while n - a > precision {
            n = 1.0 / (n - a)
            a = floor(n)
            
            // Update values
            (h2, h1) = (h1, a * h1 + h2)
            (k2, k1) = (k1, a * k1 + k2)
            
            h = h1
            k = k1
            
            // Avoid infinite loops for complex fractions
            if h > 10000 || k > 10000 {
                break
            }
        }
        
        // Handle negative numbers
        let sign = decimal < 0 ? "-" : ""
        
        // Return the LaTeX fraction
        if k == 1 {
            // Whole number
            return "\(sign)\(Int(h))"
        } else {
            return "\(sign)\\frac{\(Int(h))}{\(Int(k))}"
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func convertLatexToAsciiMath(_ latex: String) -> String {
        // Remove LaTeX delimiters
        var result = removeLatexDelimiters(from: latex)
        
        // Replace common LaTeX commands with AsciiMath equivalents
        let replacements: [String: String] = [
            "\\frac{": "",
            "\\sqrt{": "sqrt(",
            "\\sum_{": "sum_",
            "\\int_{": "int_",
            "\\infty": "oo",
            "\\alpha": "alpha",
            "\\beta": "beta",
            "\\gamma": "gamma",
            "\\delta": "delta",
            "\\pi": "pi",
            "\\theta": "theta",
            "\\phi": "phi"
        ]
        
        for (latexCmd, asciiMath) in replacements {
            result = result.replacingOccurrences(of: latexCmd, with: asciiMath)
        }
        
        // Handle fractions specially
        while let range = result.range(of: "\\frac{([^{}]*)}{([^{}]*)}", options: .regularExpression) {
            let match = String(result[range])
            
            // Extract numerator and denominator
            let pattern = "\\frac{([^{}]*)}{([^{}]*)}"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(range, in: result)
            let matches = regex.matches(in: result, options: [], range: nsRange)
            
            if let match = matches.first {
                if match.numberOfRanges >= 3 {
                    let numeratorRange = Range(match.range(at: 1), in: result)!
                    let denominatorRange = Range(match.range(at: 2), in: result)!
                    
                    let numerator = String(result[numeratorRange])
                    let denominator = String(result[denominatorRange])
                    
                    // Replace with AsciiMath fraction
                    let asciiMathFraction = "(" + numerator + ")/(" + denominator + ")"
                    result = result.replacingOccurrences(of: match.string, with: asciiMathFraction, options: [], range: nsRange)
                }
            }
        }
        
        return result
    }
    
    private func convertLatexToPlainText(_ latex: String) -> String {
        // Remove LaTeX delimiters
        var result = removeLatexDelimiters(from: latex)
        
        // Replace common LaTeX commands with plain text equivalents
        let replacements: [String: String] = [
            "\\frac{": "",
            "\\sqrt{": "√(",
            "\\sum_{": "Σ_",
            "\\int_{": "∫_",
            "\\infty": "∞",
            "\\alpha": "α",
            "\\beta": "β",
            "\\gamma": "γ",
            "\\delta": "δ",
            "\\pi": "π",
            "\\theta": "θ",
            "\\phi": "φ",
            "^2": "²",
            "^3": "³",
            "^{2}": "²",
            "^{3}": "³"
        ]
        
        for (latexCmd, plainText) in replacements {
            result = result.replacingOccurrences(of: latexCmd, with: plainText)
        }
        
        // Handle fractions specially
        while let range = result.range(of: "\\frac{([^{}]*)}{([^{}]*)}", options: .regularExpression) {
            let match = String(result[range])
            
            // Extract numerator and denominator
            let pattern = "\\frac{([^{}]*)}{([^{}]*)}"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(range, in: result)
            let matches = regex.matches(in: result, options: [], range: nsRange)
            
            if let match = matches.first {
                if match.numberOfRanges >= 3 {
                    let numeratorRange = Range(match.range(at: 1), in: result)!
                    let denominatorRange = Range(match.range(at: 2), in: result)!
                    
                    let numerator = String(result[numeratorRange])
                    let denominator = String(result[denominatorRange])
                    
                    // Replace with plain text fraction
                    let plainTextFraction = "(" + numerator + ")/(" + denominator + ")"
                    result = result.replacingOccurrences(of: match.string, with: plainTextFraction, options: [], range: nsRange)
                }
            }
        }
        
        return result
    }
    
    private func convertAsciiMathToLatex(_ asciiMath: String) -> String {
        // Simple implementation - would need a more sophisticated parser in a real app
        var result = asciiMath
        
        // Replace common AsciiMath with LaTeX
        let replacements: [String: String] = [
            "sqrt(": "\\sqrt{",
            "sum_": "\\sum_{",
            "int_": "\\int_{",
            "oo": "\\infty",
            "alpha": "\\alpha",
            "beta": "\\beta",
            "gamma": "\\gamma",
            "delta": "\\delta",
            "pi": "\\pi",
            "theta": "\\theta",
            "phi": "\\phi"
        ]
        
        for (asciiMathExpr, latexCmd) in replacements {
            result = result.replacingOccurrences(of: asciiMathExpr, with: latexCmd)
        }
        
        // Handle fractions
        let fractionPattern = "\\(([^()]*)\\)/\\(([^()]*)\\)"
        if let regex = try? NSRegularExpression(pattern: fractionPattern, options: []) {
            let nsString = result as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            let matches = regex.matches(in: result, options: [], range: range)
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    let numeratorRange = match.range(at: 1)
                    let denominatorRange = match.range(at: 2)
                    
                    let numerator = nsString.substring(with: numeratorRange)
                    let denominator = nsString.substring(with: denominatorRange)
                    
                    // Replace with LaTeX fraction
                    let latexFraction = "\\frac{\(numerator)}{\(denominator)}"
                    
                    result = (result as NSString).replacingCharacters(in: match.range, with: latexFraction)
                }
            }
        }
        
        // Add LaTeX delimiters
        return "$" + result + "$"
    }
    
    private func convertAsciiMathToPlainText(_ asciiMath: String) -> String {
        // Convert to LaTeX first, then to plain text
        let latex = convertAsciiMathToLatex(asciiMath)
        return convertLatexToPlainText(latex)
    }
    
    private func convertPlainTextToLatex(_ plainText: String) -> String {
        // Simple implementation - would need a more sophisticated parser in a real app
        var result = plainText
        
        // Replace common plain text symbols with LaTeX
        let replacements: [String: String] = [
            "√": "\\sqrt{",
            "Σ": "\\sum_{",
            "∫": "\\int_{",
            "∞": "\\infty",
            "α": "\\alpha",
            "β": "\\beta",
            "γ": "\\gamma",
            "δ": "\\delta",
            "π": "\\pi",
            "θ": "\\theta",
            "φ": "\\phi",
            "²": "^2",
            "³": "^3"
        ]
        
        for (plainTextSymbol, latexCmd) in replacements {
            result = result.replacingOccurrences(of: plainTextSymbol, with: latexCmd)
        }
        
        // Handle fractions
        let fractionPattern = "\\(([^()]*)\\)/\\(([^()]*)\\)"
        if let regex = try? NSRegularExpression(pattern: fractionPattern, options: []) {
            let nsString = result as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            let matches = regex.matches(in: result, options: [], range: range)
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    let numeratorRange = match.range(at: 1)
                    let denominatorRange = match.range(at: 2)
                    
                    let numerator = nsString.substring(with: numeratorRange)
                    let denominator = nsString.substring(with: denominatorRange)
                    
                    // Replace with LaTeX fraction
                    let latexFraction = "\\frac{\(numerator)}{\(denominator)}"
                    
                    result = (result as NSString).replacingCharacters(in: match.range, with: latexFraction)
                }
            }
        }
        
        // Add LaTeX delimiters
        return "$" + result + "$"
    }
    
    private func convertPlainTextToAsciiMath(_ plainText: String) -> String {
        // Convert to LaTeX first, then to AsciiMath
        let latex = convertPlainTextToLatex(plainText)
        return convertLatexToAsciiMath(latex)
    }
}

/// Enum to represent either text or math components in mixed content
enum MathTextComponent {
    case text(String)
    case math(String)
}

/// SwiftUI View extension to render mixed text and math
extension View {
    /// Renders mixed text containing both regular text and LaTeX math
    func renderMixedMath(_ text: String) -> some View {
        let components = MathFormatter.shared.splitTextAndMath(mixedText: text)
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<components.count, id: \.self) { index in
                switch components[index] {
                case .text(let textContent):
                    Text(textContent)
                        .fixedSize(horizontal: false, vertical: true)
                case .math(let mathContent):
                    MathView(equation: mathContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
