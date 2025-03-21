import SwiftUI

/// Namespace for reusable UI components to avoid name conflicts with SwiftUI
enum UIComponents {
    /// Represents proficiency levels with associated colors and thresholds
    enum BadgeLevel: String {
        case beginner = "Beginner"
        case developing = "Developing"
        case intermediate = "Intermediate"
        case proficient = "Proficient"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .red
            case .developing: return .orange
            case .intermediate: return .yellow
            case .proficient: return .blue
            case .expert: return .green
            }
        }
        
        static func forPercentage(_ percentage: Double) -> BadgeLevel {
            switch percentage {
            case 0..<20: return .beginner
            case 20..<40: return .developing
            case 40..<60: return .intermediate
            case 60..<80: return .proficient
            default: return .expert
            }
        }
    }

    /// A badge showing proficiency level by percentage
    struct ProficiencyBadge: View {
        let percentage: Double
        let showPercentage: Bool
        let showText: Bool
        
        init(percentage: Double, showPercentage: Bool = true, showText: Bool = true) {
            self.percentage = percentage
            self.showPercentage = showPercentage
            self.showText = showText
        }
        
        var level: BadgeLevel {
            return BadgeLevel.forPercentage(percentage)
        }
        
        var body: some View {
            if showText {
                Text(showPercentage ? "\(Int(percentage))%" : level.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(level.color.opacity(0.15))
                    .foregroundColor(level.color)
                    .cornerRadius(15)
            } else {
                // Simple color badge without text
                Circle()
                    .fill(level.color)
                    .frame(width: 12, height: 12)
            }
        }
    }

    /// A stat item component showing a value with a label
    struct StatItem: View {
        let label: String
        let value: String
        
        var body: some View {
            VStack(spacing: 5) {
                Text(value)
                    .font(.headline)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// A card showing a statistic with icon
    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .bold()
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 3)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            UIComponents.ProficiencyBadge(percentage: 15)
            UIComponents.ProficiencyBadge(percentage: 35)
            UIComponents.ProficiencyBadge(percentage: 55)
            UIComponents.ProficiencyBadge(percentage: 75)
            UIComponents.ProficiencyBadge(percentage: 95)
        }
        
        HStack {
            UIComponents.ProficiencyBadge(percentage: 15, showPercentage: false)
            UIComponents.ProficiencyBadge(percentage: 35, showPercentage: false)
            UIComponents.ProficiencyBadge(percentage: 55, showPercentage: false)
            UIComponents.ProficiencyBadge(percentage: 75, showPercentage: false)
            UIComponents.ProficiencyBadge(percentage: 95, showPercentage: false)
        }
        
        HStack {
            UIComponents.StatItem(label: "Questions", value: "25")
            UIComponents.StatItem(label: "Correct", value: "18")
            UIComponents.StatItem(label: "Accuracy", value: "72%")
        }
        
        HStack {
            UIComponents.StatCard(title: "Streak", value: "5", icon: "flame.fill", color: .orange)
            UIComponents.StatCard(title: "Today", value: "12", icon: "checkmark.circle.fill", color: .green)
            UIComponents.StatCard(title: "Score", value: "78%", icon: "chart.bar.fill", color: .blue)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}