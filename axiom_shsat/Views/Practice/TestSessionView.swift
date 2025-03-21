//
//  TestSessionView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData

struct TestSessionView: View {
    @StateObject private var viewModel: TestSessionViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingConfirmation = false
    @State private var showingResults = false
    
    init(topic: String?, difficulty: String?, questionCount: Int = 10, environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: {
            let vm = TestSessionViewModel(environment: environment)
            
            // We'll start the session asynchronously when the view appears
            vm.topic = topic
            vm.difficulty = difficulty
            vm.questionCount = questionCount
            
            return vm
        }())
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isCompleted {
                resultsView
            } else if let currentQuestion = viewModel.currentQuestion {
                questionView(question: currentQuestion)
            } else {
                Text("No questions available.")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if !viewModel.isCompleted {
                        showingConfirmation = true
                    } else {
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Exit")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(viewModel.currentQuestionIndex + 1)/\(viewModel.questionCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .alert("Exit Test?", isPresented: $showingConfirmation) {
            Button("Continue Test", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will be lost. Are you sure you want to exit?")
        }
        .onAppear {
            startSession()
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading questions...")
                .font(.headline)
        }
    }
    
    private func questionView(question: Question) -> some View {
        VStack {
            // Progress bar
            ProgressView(value: viewModel.progressPercentage)
                .padding(.horizontal)
                .padding(.top)
            
            // Question content
            QuestionView(question: question)
            
            // Next/Finish button (only shown after answering)
            if viewModel.selectedAnswer != nil {
                Button(action: {
                    if viewModel.isLastQuestion {
                        viewModel.completeSession()
                        showingResults = true
                    } else {
                        viewModel.nextQuestion()
                    }
                }) {
                    Text(viewModel.isLastQuestion ? "Finish Test" : "Next Question")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 8) {
                    Text("Test Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let session = viewModel.session {
                        Text("Session: \(session.sessionType)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Score card
                scoreCardView
                
                // Topic breakdown
                topicBreakdownView
                
                // Action buttons
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        startSession()
                    }) {
                        Text("New Test")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                // Questions review
                questionReviewSection
            }
            .padding()
        }
    }
    
    private var scoreCardView: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.blue.opacity(0.2),
                    lineWidth: 15
                )
            
            Circle()
                .trim(from: 0, to: viewModel.correctAnswersPercentage / 100)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: viewModel.correctAnswersPercentage)
            
            VStack {
                Text("\(Int(viewModel.correctAnswersPercentage))%")
                    .font(.system(size: 40, weight: .bold))
                
                Text("\(viewModel.responses.filter { $0.isCorrect }.count)/\(viewModel.responses.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .padding()
    }
    
    private var topicBreakdownView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Topic Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(Array(topicPerformance.keys.sorted()), id: \.self) { topic in
                    if let performance = topicPerformance[topic] {
                        HStack {
                            Text(topic.capitalized)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(performance.correct)/\(performance.total)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            let percentage = performance.total > 0 ? Double(performance.correct) / Double(performance.total) * 100 : 0
                            Text("\(Int(percentage))%")
                                .font(.subheadline)
                                .foregroundColor(percentage >= 70 ? .green : (percentage >= 50 ? .orange : .red))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    private var questionReviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Question Review")
                .font(.headline)
                .padding(.horizontal)
            
            Divider()
            
            ForEach(Array(viewModel.responses.enumerated()), id: \.element.id) { index, response in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Question \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if response.isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let question = response.question {
                        Text(question.text.replacingOccurrences(of: "$", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            Text("Your answer: \(response.selectedOption)")
                                .font(.caption)
                                .foregroundColor(response.isCorrect ? .green : .red)
                            
                            if !response.isCorrect, let correctOption = response.question?.correctOption {
                                Text("Correct: \(correctOption)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if index < viewModel.responses.count - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var navigationTitle: String {
        if let topic = viewModel.topic {
            return "\(topic.capitalized) Practice"
        } else if let difficulty = viewModel.difficulty {
            return "\(difficulty.capitalized) Test"
        } else {
            return "Practice Test"
        }
    }
    
    private var scoreColor: Color {
        let percentage = viewModel.correctAnswersPercentage
        
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
    
    private var topicPerformance: [String: (correct: Int, total: Int)] {
        var performance: [String: (correct: Int, total: Int)] = [:]
        
        for response in viewModel.responses {
            guard let topic = response.question?.topic else { continue }
            
            let current = performance[topic] ?? (correct: 0, total: 0)
            let newCorrect = current.correct + (response.isCorrect ? 1 : 0)
            let newTotal = current.total + 1
            
            performance[topic] = (correct: newCorrect, total: newTotal)
        }
        
        return performance
    }
    
    private func startSession() {
        Task {
            await viewModel.startNewSession(
                sessionType: viewModel.topic != nil ? SessionType.topicReview.rawValue : (viewModel.questionCount >= 25 ? SessionType.fullTest.rawValue : SessionType.practice.rawValue),
                topics: viewModel.topic != nil ? [viewModel.topic!] : [],
                difficulty: viewModel.difficulty,
                questionCount: viewModel.questionCount,
                user: authViewModel.currentUser
            )
        }
    }
}


#Preview {
    let environment = AppEnvironment.shared
    TestSessionView(topic: "algebra", difficulty: "medium", questionCount: 5, environment: environment)
        .environmentObject(AuthViewModel(environment: environment))
        .modelContainer(environment.modelContainer)
}
