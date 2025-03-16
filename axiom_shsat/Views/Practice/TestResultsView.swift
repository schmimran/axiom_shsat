//
//  TestResultsView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData
import Charts

struct TestResultsView: View {
    let session: TestSession
    let responses: [QuestionResponse]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSegment = 0
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header with score
                scoreHeader
                
                // Segmented control for different sections
                Picker("View", selection: $selectedSegment) {
                    Text("Summary").tag(0)
                    Text("Topics").tag(1)
                    Text("Review").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selected segment
                switch selectedSegment {
                case 0:
                    summarySectionView
                case 1:
                    topicBreakdownView
                case 2:
                    questionReviewView
                default:
                    EmptyView()
                }
                
                // Action buttons
                actionButtonsView
            }
            .padding()
        }
        .navigationTitle("Test Results")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
            Text("Done")
        })
    }
    
    // Score header with circular progress indicator
    private var scoreHeader: some View {
        VStack(spacing: 12) {
            Text("Test Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(session.sessionType)
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                CircularProgressView(
                    progress: session.accuracyPercentage / 100,
                    lineWidth: 20
                )
                .frame(width: 200, height: 200)
                
                VStack {
                    Text("\(Int(session.accuracyPercentage))%")
                        .font(.system(size: 42, weight: .bold))
                    
                    Text("\(session.correctAnswers)/\(session.totalQuestions)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            
            if let duration = session.duration {
                HStack {
                    Label(
                        title: { Text("Time: \(formatDuration(duration))") },
                        icon: { Image(systemName: "clock") }
                    )
                    .font(.headline)
                    
                    Spacer()
                    
                    Label(
                        title: { Text("\(Int(Double(session.correctAnswers) / (duration / 60))) per min") },
                        icon: { Image(systemName: "speedometer") }
                    )
                    .font(.headline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    // Summary section view
    private var summarySectionView: some View {
        VStack(spacing: 20) {
            // Performance chart (time per question)
            performanceChart
            
            // Key statistics
            VStack(alignment: .leading, spacing: 5) {
                Text("Session Statistics")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                keyStatisticsGrid
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // Performance chart showing time per question
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Response Time")
                .font(.headline)
            
            let chartData = responses.enumerated().map { index, response in
                return (
                    index: index + 1,
                    time: response.responseTime,
                    isCorrect: response.isCorrect
                )
            }
            
            Chart {
                ForEach(chartData, id: \.index) { item in
                    BarMark(
                        x: .value("Question", "\(item.index)"),
                        y: .value("Time (s)", item.time)
                    )
                    .foregroundStyle(item.isCorrect ? Color.green : Color.red)
                }
                
                RuleMark(y: .value("Average", averageResponseTime))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(String(format: "%.1f", averageResponseTime))s")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...(maxResponseTime * 1.1))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // Grid of key statistics
    private var keyStatisticsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatisticCard(
                label: "Accuracy",
                value: "\(Int(session.accuracyPercentage))%",
                icon: "checkmark.circle",
                color: accuracyColor
            )
            
            StatisticCard(
                label: "Avg. Time",
                value: "\(String(format: "%.1f", averageResponseTime))s",
                icon: "clock",
                color: .blue
            )
            
            StatisticCard(
                label: "Fastest",
                value: "\(String(format: "%.1f", fastestResponseTime))s",
                icon: "bolt",
                color: .green
            )
            
            StatisticCard(
                label: "Slowest",
                value: "\(String(format: "%.1f", slowestResponseTime))s",
                icon: "tortoise",
                color: .orange
            )
        }
    }
    
    // Topic breakdown view
    private var topicBreakdownView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance by Topic")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(topicPerformance.sorted(by: { $0.key < $1.key }), id: \.key) { topic, performance in
                TopicPerformanceRow(
                    topic: topic,
                    correct: performance.correct,
                    total: performance.total,
                    averageTime: performance.averageTime
                )
            }
            
            Text("Focus Areas")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 10)
            
            if let weakestTopic = weakestTopic {
                FocusAreaCard(
                    topic: weakestTopic,
                    message: "Needs improvement. Practice more \(weakestTopic.capitalized) questions."
                )
            } else {
                Text("Great job! Keep practicing all topics.")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
    
    // Question review view
    private var questionReviewView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Question Review")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(Array(responses.enumerated()), id: \.element.id) { index, response in
                QuestionReviewCard(
                    questionNumber: index + 1,
                    response: response,
                    sessionTotalQuestions: session.totalQuestions
                )
            }
        }
    }
    
    // Action buttons
    private var actionButtonsView: some View {
        HStack(spacing: 20) {
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "house")
                    Text("Home")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                // Start a new test with the same configuration
                // This would need to be handled by the parent view
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("New Test")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper methods and computed properties
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var averageResponseTime: Double {
        guard !responses.isEmpty else { return 0 }
        let totalTime = responses.reduce(0) { $0 + $1.responseTime }
        return totalTime / Double(responses.count)
    }
    
    private var fastestResponseTime: Double {
        return responses.min { $0.responseTime < $1.responseTime }?.responseTime ?? 0
    }
    
    private var slowestResponseTime: Double {
        return responses.max { $0.responseTime < $1.responseTime }?.responseTime ?? 0
    }
    
    private var maxResponseTime: Double {
        return responses.max { $0.responseTime < $1.responseTime }?.responseTime ?? 10
    }
    
    private var accuracyColor: Color {
        let percentage = session.accuracyPercentage
        
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
    
    private var topicPerformance: [String: (correct: Int, total: Int, averageTime: Double)] {
        var performance: [String: (correct: Int, total: Int, averageTime: Double, totalTime: Double)] = [:]
        
        for response in responses {
            guard let topic = response.question?.topic else { continue }
            
            var current = performance[topic] ?? (correct: 0, total: 0, averageTime: 0, totalTime: 0)
            
            current.total += 1
            if response.isCorrect {
                current.correct += 1
            }
            current.totalTime += response.responseTime
            current.averageTime = current.totalTime / Double(current.total)
            
            performance[topic] = current
        }
        
        // Convert to the return type (without totalTime)
        return performance.mapValues { (correct: $0.correct, total: $0.total, averageTime: $0.averageTime) }
    }
    
    private var weakestTopic: String? {
        guard !topicPerformance.isEmpty else { return nil }
        
        return topicPerformance
            .filter { $0.value.total >= 2 } // Need at least 2 questions to evaluate
            .min { a, b in
                let aPercentage = Double(a.value.correct) / Double(a.value.total) * 100
                let bPercentage = Double(b.value.correct) / Double(b.value.total) * 100
                return aPercentage < bPercentage
            }?.key
    }
}

// MARK: - Supporting Views

struct TopicPerformanceRow: View {
    let topic: String
    let correct: Int
    let total: Int
    let averageTime: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(topic.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text("\(correct)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("(\(Int(percentage))%)")
                    .font(.subheadline)
                    .foregroundColor(percentageColor)
            }
            
            HStack {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 8)
                            .opacity(0.3)
                            .foregroundColor(Color(.systemGray4))
                        
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(Double(correct) / Double(total)), height: 8)
                            .foregroundColor(percentageColor)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                Spacer()
                
                Text("Avg: \(String(format: "%.1f", averageTime))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
    
    private var percentageColor: Color {
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

struct FocusAreaCard: View {
    let topic: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(topic.capitalized)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Would navigate to practice for this topic
            }) {
                Text("Practice \(topic.capitalized)")
                    .font(.callout)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
}

struct QuestionReviewCard: View {
    let questionNumber: Int
    let response: QuestionResponse
    let sessionTotalQuestions: Int
    
    @State private var showDetails: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question header (always visible)
            Button(action: {
                showDetails.toggle()
            }) {
                HStack {
                    Text("Q\(questionNumber) of \(sessionTotalQuestions)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if response.isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: showDetails)
                }
                .padding()
                .background(Color(.systemGray6))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Question details (shown when expanded)
            if showDetails {
                VStack(alignment: .leading, spacing: 10) {
                    if let question = response.question {
                        Text(question.text.replacingOccurrences(of: "$", with: ""))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 5)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Your answer:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(response.selectedOption)
                                    .font(.callout)
                                    .foregroundColor(response.isCorrect ? .green : .red)
                            }
                            
                            Spacer()
                            
                            if !response.isCorrect {
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("Correct answer:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(question.correctOption)
                                        .font(.callout)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("Time: \(String(format: "%.1f", response.responseTime))s", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Topic: \(question.topic.capitalized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Question details not available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray5))
            }
        }
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct StatisticCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
        )
    }
}

#Preview {
    let modelContainer = try! ModelContainer(for: [
        TestSession.self,
        QuestionResponse.self,
        Question.self
    ])
    
    // Create a sample session and responses for preview
    let session = TestSession(
        totalQuestions: 10,
        sessionType: "Practice Test",
        topics: ["algebra", "geometry"],
        difficulty: "medium"
    )
    session.correctAnswers = 7
    session.completed = true
    session.duration = 420 // 7 minutes
    
    var responses: [QuestionResponse] = []
    for i in 1...10 {
        let isCorrect = i <= 7
        let question = Question(
            text: "Sample question \(i)",
            optionA: "Option A",
            optionB: "Option B",
            optionC: "Option C",
            optionD: "Option D",
            optionE: "Option E",
            correctOption: "C",
            topic: i % 2 == 0 ? "algebra" : "geometry",
            difficulty: "medium"
        )
        
        let response = QuestionResponse(
            selectedOption: isCorrect ? "C" : "A",
            isCorrect: isCorrect,
            responseTime: Double(10 + i * 2),
            question: question,
            session: session
        )
        
        responses.append(response)
    }
    
    return NavigationView {
        TestResultsView(session: session, responses: responses)
            .environmentObject(AuthViewModel(modelContext: modelContainer.mainContext))
    }
}