import SwiftUI
import SwiftData
import Charts

struct UserProgressView: View {
    @StateObject private var viewModel: ProgressViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedTab = 0
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
    }
    
    init(userId: UUID, environment: AppEnvironment = .shared) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(
            environment: environment,
            userId: userId
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                summaryCards
                
                // Tab selection
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Topics").tag(1)
                    Text("History").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab content
                switch selectedTab {
                case 0:
                    overviewTab
                case 1:
                    topicsTab
                case 2:
                    historyTab
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .navigationTitle("Your Progress")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
    
    // Summary cards
    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            SummaryCard(
                title: "Overall Score",
                value: "\(Int(viewModel.overallAccuracy))%",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "Questions Today",
                value: "\(viewModel.questionsAnsweredToday)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            SummaryCard(
                title: "Current Streak",
                value: "\(viewModel.currentStreak) days",
                icon: "flame.fill",
                color: .orange
            )
            
            SummaryCard(
                title: "Weekly Progress",
                value: "\(Int(viewModel.weeklyProgress))%",
                icon: "arrow.up.right",
                color: weeklyProgressColor
            )
        }
    }
    
    // Overview tab content
    private var overviewTab: some View {
        VStack(spacing: 25) {
            // Activity chart
            activityChart
            
            // Most improved topic
            if let mostImprovedTopic = viewModel.mostImprovedTopic {
                mostImprovedTopicCard(mostImprovedTopic)
            }
            
            // Learning time distribution
            learningTimeDistribution
        }
    }
    
    // Topics tab content
    private var topicsTab: some View {
        VStack(spacing: 20) {
            // Progress by topic
            VStack(alignment: .leading, spacing: 10) {
                Text("Topic Proficiency")
                    .font(.headline)
                
                ForEach(viewModel.topicProgress.sorted(by: { $0.proficiencyPercentage > $1.proficiencyPercentage })) { topic in
                    TopicProgressRow(topic: topic)
                }
            }
            
            // Recommendations
            if !viewModel.topicProgress.isEmpty {
                recommendationsSection
            }
        }
    }
    
    // History tab content
    private var historyTab: some View {
        VStack(spacing: 20) {
            // Time range selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Sessions list
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Sessions")
                    .font(.headline)
                
                if viewModel.recentSessions.isEmpty {
                    Text("No sessions found in this time range")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                } else {
                    ForEach(viewModel.recentSessions) { session in
                        SessionHistoryRow(session: session)
                    }
                }
            }
            
            // Performance trends
            performanceTrendsSection
        }
    }
    
    // Activity chart
    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Activity")
                .font(.headline)
            
            let filteredData = filteredDailyStats
            
            Chart {
                ForEach(filteredData, id: \.date) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Questions", day.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    
                    if day.count > 0 {
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Correct", day.correct)
                        )
                        .foregroundStyle(Color.green.gradient)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 4)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.day().month())
                                .font(.caption)
                        }
                    }
                }
            }
            
            HStack {
                LegendItem(color: .blue, label: "Attempted")
                LegendItem(color: .green, label: "Correct")
                
                Spacer()
                
                Text("Total: \(totalQuestionsInTimeRange) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Most improved topic card
    private func mostImprovedTopicCard(_ topic: TopicProgress) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Most Improved Topic")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(topic.topic.capitalized)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Proficiency: \(Int(topic.proficiencyPercentage))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Last practiced: \(topic.lastPracticed, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(
                            Color.blue.opacity(0.2),
                            lineWidth: 10
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: topic.proficiencyPercentage / 100)
                        .stroke(
                            topicProficiencyColor(topic.proficiencyPercentage),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(topic.proficiencyPercentage))%")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            Button(action: {
                // Navigate to practice for this topic
            }) {
                Text("Practice \(topic.topic.capitalized)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Learning time distribution chart
    private var learningTimeDistribution: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Learning Time Distribution")
                .font(.headline)
            
            // This would be populated with real data in a production app
            let timeData = [
                ("Algebra", 35.0),
                ("Geometry", 25.0),
                ("Numbers", 20.0),
                ("Probability", 15.0),
                ("General", 5.0)
            ]
            
            Chart {
                ForEach(timeData, id: \.0) { item in
                    SectorMark(
                        angle: .value("Time", item.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", item.0))
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Recommendations section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended Actions")
                .font(.headline)
            
            if let weakestTopic = viewModel.topicProgress
                .sorted(by: { $0.proficiencyPercentage < $1.proficiencyPercentage })
                .first {
                
                RecommendationCard(
                    title: "Practice \(weakestTopic.topic.capitalized)",
                    message: "Improve your \(weakestTopic.topic) proficiency by focusing on this topic.",
                    icon: "square.stack",
                    color: .orange,
                    action: {
                        // Would navigate to practice for this topic
                    }
                )
            }
            
            if viewModel.currentStreak < 3 {
                RecommendationCard(
                    title: "Build Your Streak",
                    message: "Practice daily to build your learning streak and retain knowledge better.",
                    icon: "flame",
                    color: .red,
                    action: {
                        // Would navigate to quick practice
                    }
                )
            }
            
            RecommendationCard(
                title: "Take a Full Test",
                message: "Challenge yourself with a complete test to measure your overall progress.",
                icon: "checkmark.seal",
                color: .green,
                action: {
                    // Would navigate to full test
                }
            )
        }
    }
    
    // Performance trends section
    private var performanceTrendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Performance Trends")
                .font(.headline)
            
            // This would be populated with real data in a production app
            let performanceData: [(Date, Double)] = [
                (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 65),
                (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 68),
                (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 72),
                (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 70),
                (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 75),
                (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 78),
                (Date(), 82)
            ]
            
            Chart {
                ForEach(performanceData, id: \.0) { item in
                    LineMark(
                        x: .value("Date", item.0, unit: .day),
                        y: .value("Score", item.1)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", item.0, unit: .day),
                        y: .value("Score", item.1)
                    )
                    .foregroundStyle(Color.blue)
                }
                
                RuleMark(y: .value("Passing", 70))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing) {
                        Text("70%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
            }
            .frame(height: 200)
            .chartYScale(domain: 50...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.day())
                                .font(.caption)
                        }
                    }
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
    
    // Helper views and computed properties
    
    private var filteredDailyStats: [(date: Date, count: Int, correct: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: today)!
        case .year:
            startDate = calendar.date(byAdding: .day, value: -365, to: today)!
        }
        
        return viewModel.dailyStats.filter { $0.date >= startDate }
    }
    
    private var totalQuestionsInTimeRange: Int {
        return filteredDailyStats.reduce(0) { $0 + $1.count }
    }
    
    private var weeklyProgressColor: Color {
        let progress = viewModel.weeklyProgress
        
        switch progress {
        case ..<0:
            return .red
        case 0..<50:
            return .orange
        case 50..<80:
            return .blue
        default:
            return .green
        }
    }
    
    private func topicProficiencyColor(_ percentage: Double) -> Color {
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

// Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
}

struct TopicProgressRow: View {
    let topic: TopicProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(topic.topic.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text(topic.proficiencyLevel)
                    .font(.subheadline)
                    .foregroundColor(proficiencyColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(proficiencyColor.opacity(0.1))
                    .cornerRadius(5)
            }
            
            HStack {
                Text("\(topic.questionsAttempted) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(topic.proficiencyPercentage))% proficiency")
                    .font(.caption)
                    .foregroundColor(proficiencyColor)
            }
            
            // Progress bar
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3)
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

struct RecommendationCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(color)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3)
        )
    }
}

struct SessionHistoryRow: View {
    let session: TestSession
    
    var body: some View {
        NavigationLink(destination: TestResultsView(session: session, responses: session.responses)) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.sessionType)
                        .font(.headline)
                    
                    if let endTime = session.endTime {
                        Text(endTime, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(session.correctAnswers)/\(session.totalQuestions)")
                        .font(.subheadline)
                    
                    Text("\(Int(session.accuracyPercentage))%")
                        .font(.caption)
                        .foregroundColor(scoreColor(session.accuracyPercentage))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func scoreColor(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<50:
            return .red
        case 50..<70:
            return .orange
        case 70..<90:
            return .blue
        default:
            return .green
        }
    }
}

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

#Preview {
    NavigationView {
        UserProgressView(userId: UUID())
            .environmentObject(AppEnvironment.shared)
    }
}
