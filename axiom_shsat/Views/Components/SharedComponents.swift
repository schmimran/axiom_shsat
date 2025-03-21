import SwiftUI

/// Namespace for all shared UI components
enum UIComponents {
    /// Proficiency badge shows skill level with color and text
    struct ProficiencyBadge: View {
        let percentage: Double
        let showPercentage: Bool
        let showText: Bool
        
        init(percentage: Double, showPercentage: Bool = true, showText: Bool = true) {
            self.percentage = percentage
            self.showPercentage = showPercentage
            self.showText = showText
        }
        
        var level: String {
            switch percentage {
            case 0..<20: return "Beginner"
            case 20..<40: return "Developing"
            case 40..<60: return "Intermediate"
            case 60..<80: return "Proficient"
            default: return "Expert"
            }
        }
        
        var color: Color {
            switch percentage {
            case 0..<30: return .red
            case 30..<60: return .orange
            case 60..<80: return .blue
            default: return .green
            }
        }
        
        var body: some View {
            if showText {
                Text(showPercentage ? "\(Int(percentage))%" : level)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .cornerRadius(15)
            } else {
                // Simple color badge without text
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    /// Stat card for displaying metrics in a grid
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
    
    /// Stat item for displaying a labeled value
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
    
    /// Legend item for charts
    struct LegendItem: View {
        let color: Color
        let label: String
        
        var body: some View {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
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