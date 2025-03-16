import SwiftUI

struct CircularProgressView: View {
    let progress: Double // Value between 0 and 1
    var lineWidth: CGFloat = 15
    var showLabel: Bool = false
    var primaryColor: Color? = nil
    var secondaryColor: Color = Color(.systemGray5)
    var font: Font = .system(.title, design: .rounded).bold()
    var labelView: AnyView? = nil
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    secondaryColor,
                    lineWidth: lineWidth
                )
            
            // Progress circle
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            // Label
            if let customLabelView = labelView {
                customLabelView
            } else if showLabel {
                VStack(spacing: 5) {
                    Text("\(Int(progress * 100))%")
                        .font(font)
                    
                    if progress < 1.0 {
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .animation(.none, value: progress)
            }
        }
    }
    
    private var progressGradient: LinearGradient {
        if let color = primaryColor {
            return LinearGradient(
                gradient: Gradient(colors: [color, color]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return progressColorGradient(for: progress)
        }
    }
    
    private func progressColorGradient(for progress: Double) -> LinearGradient {
        switch progress {
        case 0..<0.3:
            return LinearGradient(
                gradient: Gradient(colors: [.red, .orange]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case 0.3..<0.7:
            return LinearGradient(
                gradient: Gradient(colors: [.orange, .yellow]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case 0.7..<0.9:
            return LinearGradient(
                gradient: Gradient(colors: [.yellow, .green]),
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [.blue, .green]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

struct TaskProgressView: View {
    let progress: Double
    let taskName: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Progress circle
            CircularProgressView(
                progress: progress,
                lineWidth: 8
            )
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                // Task name
                Text(taskName)
                    .font(.headline)
                
                // Progress text
                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 6)
                            .opacity(0.2)
                            .foregroundColor(.gray)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                            .foregroundColor(progressColor)
                    }
                    .cornerRadius(3)
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.3:
            return .red
        case 0.3..<0.7:
            return .orange
        case 0.7..<0.9:
            return .yellow
        default:
            return .green
        }
    }
}

struct CircularTimerView: View {
    let duration: TimeInterval
    @Binding var remainingTime: TimeInterval
    var size: CGFloat = 100
    var lineWidth: CGFloat = 10
    
    var body: some View {
        CircularProgressView(
            progress: (duration - remainingTime) / duration,
            lineWidth: lineWidth,
            primaryColor: .blue,
            labelView: AnyView(
                VStack(spacing: 5) {
                    Text(timeString(from: remainingTime))
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                    
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            )
        )
        .frame(width: size, height: size)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PercentageRingView: View {
    let percentage: Double // Between 0 and 100
    let title: String
    var ringWidth: CGFloat = 15
    var icon: String? = nil
    var size: CGFloat = 120
    
    var body: some View {
        ZStack {
            // Background for ring
            Circle()
                .stroke(Color(.systemGray6), lineWidth: ringWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(
                    percentageColor,
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: percentage)
            
            // Content
            VStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(percentageColor)
                }
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
        }
    }
    
    private var percentageColor: Color {
        switch percentage {
        case 0..<30:
            return .red
        case 30..<60:
            return .orange
        case 60..<80:
            return .blue
        default:
            return .green
        }
    }
}

struct SectionProgressView: View {
    let sections: [(title: String, progress: Double)]
    let overallProgress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Overall progress
            CircularProgressView(
                progress: overallProgress,
                lineWidth: 12,
                showLabel: true
            )
            .frame(width: 120, height: 120)
            
            // Section breakdown
            VStack(spacing: 10) {
                ForEach(sections, id: \.title) { section in
                    SectionProgressRow(
                        title: section.title,
                        progress: section.progress
                    )
                }
            }
        }
    }
}

struct SectionProgressRow: View {
    let title: String
    let progress: Double
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            // Circular mini progress
            ZStack {
                Circle()
                    .stroke(
                        Color(.systemGray6),
                        lineWidth: 4
                    )
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(.vertical, 5)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.3:
            return .red
        case 0.3..<0.7:
            return .orange
        case 0.7..<0.9:
            return .blue
        default:
            return .green
        }
    }
}

#Preview("Circular Progress") {
    VStack(spacing: 30) {
        CircularProgressView(progress: 0.25, showLabel: true)
            .frame(width: 100, height: 100)
        
        CircularProgressView(progress: 0.5, showLabel: true)
            .frame(width: 100, height: 100)
        
        CircularProgressView(progress: 0.75, showLabel: true)
            .frame(width: 100, height: 100)
        
        CircularProgressView(progress: 1.0, showLabel: true)
            .frame(width: 100, height: 100)
    }
    .padding()
}

#Preview("Task Progress") {
    VStack(spacing: 20) {
        TaskProgressView(progress: 0.3, taskName: "Algebra Practice")
        TaskProgressView(progress: 0.7, taskName: "Geometry Quiz")
        TaskProgressView(progress: 1.0, taskName: "Numbers Review")
    }
    .padding()
}

#Preview("Timer") {
    CircularTimerView(
        duration: 300,
        remainingTime: .constant(120)
    )
    .padding()
}

#Preview("Percentage Rings") {
    HStack(spacing: 20) {
        PercentageRingView(
            percentage: 35, 
            title: "Algebra",
            icon: "function"
        )
        
        PercentageRingView(
            percentage: 75, 
            title: "Geometry",
            icon: "triangle"
        )
        
        PercentageRingView(
            percentage: 90, 
            title: "Numbers",
            icon: "number"
        )
    }
    .padding()
}

#Preview("Section Progress") {
    SectionProgressView(
        sections: [
            ("Algebra", 0.25),
            ("Geometry", 0.5),
            ("Numbers", 0.8),
            ("Probability", 0.65)
        ],
        overallProgress: 0.55
    )
    .padding()
}
