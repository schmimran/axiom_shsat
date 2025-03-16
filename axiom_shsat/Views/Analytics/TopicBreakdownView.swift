import SwiftUI
import SwiftData
import Charts

struct TopicBreakdownView: View {
    let userId: UUID
    
    @Environment(\.modelContext) private var modelContext
    @Query private var topicProgress: [TopicProgress]
    @State private var selectedTopic: String?
    @State private var showingPracticeSheet = false
    
    init(userId: UUID) {
        self.userId = userId
        
        // Configure the query predicate for this user's topics
        let predicate = #Predicate<TopicProgress> { $0.user?.id == userId }
        self._topicProgress = Query(
            filter: predicate,
            sort: [SortDescriptor(\TopicProgress.proficiencyPercentage, order: .reverse)]
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Overview chart
                proficiencyChart
                
                // Topic details
                ForEach(topicProgress) { topic in
                    TopicDetailCard(
                        topic: topic,
                        onPractice: {
                            selectedTopic = topic.topic
                            showingPracticeSheet = true
                        }
                    )
                }
                
                if topicProgress.isEmpty {
                    emptyStateView
                }
            }
            .padding()
        }
        .navigationTitle("Topic Breakdown")
        .sheet(isPresented: $showingPracticeSheet) {
            if let topic = selectedTopic {
                NavigationView {
                    TestConfigurationView(viewModel: HomeViewModel(modelContext: modelContext, userId: userId))
                        .navigationTitle("Practice \(topic.capitalized)")
                }
            }
        }
    }
    
    // Overview proficiency chart
    private var proficiencyChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Topic Proficiency")
                .font(.headline)
            
            if topicProgress.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(topicProgress) { topic in
                    BarMark(
                        x: .value("Proficiency", topic.proficiencyPercentage),
                        y: .value("Topic", topic.topic.capitalized)
                    )
                    .foregroundStyle(
                        Gradient(colors: [proficiencyColor(topic.proficiencyPercentage).opacity(0.6), proficiencyColor(topic.proficiencyPercentage)])
                    )
                    .annotation(position: .trailing) {
                        Text("\(Int(topic.proficiencyPercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .chartXScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 25)) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .frame(height: 300)
                
                // Legend
                HStack(spacing: 15) {
                    ForEach([(0..<30, "Needs Work"), (30..<60, "Developing"), (60..<80, "Proficient"), (80...100, "Mastered")], id: \.1) { range, label in
                        legendItem(
                            color: proficiencyColor(range.lowerBound + 1),
                            label: label
                        )
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
                .padding()
            
            Text("No Topic Data Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start practicing to generate topic insights and track your progress across different areas of study.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingPracticeSheet = true
            }) {
                Label("Start Practicing", systemImage: "play.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 50)
    }
    
    // Helper views and functions
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func proficiencyColor(_ percentage: Double) -> Color {
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

// Topic detail card
struct TopicDetailCard: View {
    let topic: TopicProgress
    let onPractice: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text(topic.topic.capitalized)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                ProficiencyBadge(
                    percentage: topic.proficiencyPercentage,
                    level: topic.proficiencyLevel
                )
            }
            
            // Stats
            HStack {
                StatItem(
                    label: "Questions",
                    value: "\(topic.questionsAttempted)"
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    label: "Correct",
                    value: "\(topic.correctAnswers)"
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    label: "Accuracy",
                    value: "\(Int(topic.proficiencyPercentage))%"
                )
            }
            .padding(.vertical, 5)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 5) {
                Text("Proficiency")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 8)
                            .opacity(0.2)
                            .foregroundColor(proficiencyColor)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(topic.proficiencyPercentage) / 100.0 * geometry.size.width, geometry.size.width), height: 8)
                            .foregroundColor(proficiencyColor)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
            }
            
            // Last practiced and action button
            HStack {
                if topic.questionsAttempted > 0 {
                    Text("Last practiced: \(topic.lastPracticed, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not practiced yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onPractice) {
                    Text("Practice")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    private var proficiencyColor: Color {
        let percentage = topic.proficiencyPercentage
        
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

// Supporting views

struct ProficiencyBadge: View {
    let percentage: Double
    let level: String
    
    var body: some View {
        Text(level)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .cornerRadius(15)
    }
    
    private var badgeColor: Color {
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

#Preview {
    NavigationView {
        TopicBreakdownView(userId: UUID())
    }
}
