//
//  QuestionView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData
import SwiftMath

struct QuestionView: View {
    let question: Question
    @State private var selectedOption: String?
    @State private var isAnswered = false
    @State private var showExplanation = false
    @State private var responseStartTime = Date()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question header
                questionHeaderView
                
                // Question text
                questionTextView
                
                // Answer options
                answerOptionsView
                
                // Submit button
                if !isAnswered {
                    submitButton
                } else {
                    // Feedback section
                    feedbackView
                    
                    // Show explanation toggle
                    explanationToggleView
                    
                    // Explanation content
                    if showExplanation {
                        explanationView
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Question")
        .onAppear {
            responseStartTime = Date()
        }
    }
    
    private var questionHeaderView: some View {
        HStack {
            Text("Topic: \(question.topic.capitalized)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Difficulty: \(question.difficulty.capitalized)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(difficultyColor)
                .cornerRadius(5)
        }
    }
    
    private var questionTextView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Question")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Using MathView for LaTeX rendering
            MathView(
                equation: question.text,
                font: .latinModernFont,
                fontSize: 18
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var answerOptionsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 10) {
                optionButton(option: "A", text: question.optionA)
                optionButton(option: "B", text: question.optionB)
                optionButton(option: "C", text: question.optionC)
                optionButton(option: "D", text: question.optionD)
                optionButton(option: "E", text: question.optionE)
            }
        }
    }
    
    private func optionButton(option: String, text: String) -> some View {
        Button(action: {
            if !isAnswered {
                selectedOption = option
            }
        }) {
            HStack(alignment: .top) {
                Text("\(option).")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(width: 30, alignment: .leading)
                
                // Using MathView for LaTeX rendering in options
                MathView(
                    equation: text,
                    font: .latinModernFont,
                    fontSize: 16
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                if isAnswered {
                    if option == question.correctOption {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if option == selectedOption {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                } else if option == selectedOption {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(optionBackgroundColor(option: option))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAnswered)
    }
    
    private func optionBackgroundColor(option: String) -> Color {
        if isAnswered {
            if option == question.correctOption {
                return Color.green.opacity(0.15)
            } else if option == selectedOption {
                return Color.red.opacity(0.15)
            }
            return Color(.systemGray6)
        }
        
        return option == selectedOption ? Color.blue.opacity(0.15) : Color(.systemGray6)
    }
    
    private var submitButton: some View {
        Button(action: {
            submitAnswer()
        }) {
            Text("Submit Answer")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedOption != nil ? Color.blue : Color.gray)
                .cornerRadius(10)
        }
        .disabled(selectedOption == nil)
        .padding(.vertical, 10)
    }
    
    private var feedbackView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.title2)
                
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            if !isCorrect {
                Text("The correct answer is: \(question.correctOption)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.top, 5)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var explanationToggleView: some View {
        Button(action: {
            showExplanation.toggle()
        }) {
            HStack {
                Text(showExplanation ? "Hide Explanation" : "Show Explanation")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: showExplanation ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var explanationView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Explanation")
                .font(.headline)
                .foregroundColor(.primary)
            
            // In a real app, you'd have an explanation field in your Question model
            // For now, we'll just display a placeholder
            MathView(
                equation: "\\text{The correct answer is } \(question.correctOption) \\text{: } \(question.correctAnswerText)",
                font: .latinModernFont,
                fontSize: 16
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
    
    private var isCorrect: Bool {
        return selectedOption == question.correctOption
    }
    
    private var difficultyColor: Color {
        switch question.difficulty {
        case "easy":
            return Color.green.opacity(0.2)
        case "medium":
            return Color.orange.opacity(0.2)
        case "hard":
            return Color.red.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    private func submitAnswer() {
        guard let selectedOption = selectedOption else { return }
        isAnswered = true
        
        // Calculate response time
        let responseTime = Date().timeIntervalSince(responseStartTime)
        
        // Create and save response
        let isCorrect = selectedOption == question.correctOption
        
        // Get the current user
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let userDescriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id == userId }
        )
        
        do {
            let users = try modelContext.fetch(userDescriptor)
            guard let user = users.first else { return }
            
            // Find or create a session for this individual question (if not in a test session)
            let sessionDescriptor = FetchDescriptor<TestSession>(
                predicate: #Predicate<TestSession> { 
                    $0.user?.id == userId && 
                    !$0.completed && 
                    $0.sessionType == SessionType.practice.rawValue
                }
            )
            sessionDescriptor.sortBy = [SortDescriptor(\.startTime, order: .reverse)]
            
            let sessions = try modelContext.fetch(sessionDescriptor)
            let session: TestSession
            
            if let existingSession = sessions.first {
                session = existingSession
            } else {
                // Create a new session for this individual question
                session = TestSession(
                    totalQuestions: 1,
                    sessionType: SessionType.practice.rawValue,
                    topics: [question.topic],
                    difficulty: question.difficulty,
                    user: user
                )
                modelContext.insert(session)
            }
            
            // Create the response
            let response = QuestionResponse(
                selectedOption: selectedOption,
                isCorrect: isCorrect,
                responseTime: responseTime,
                question: question,
                session: session
            )
            
            modelContext.insert(response)
            
            // Update question stats
            question.timesAttempted += 1
            if isCorrect {
                question.timesCorrect += 1
            }
            question.lastAttempted = Date()
            
            // Update topic progress
            updateTopicProgress(for: user, question: question, isCorrect: isCorrect)
            
            try modelContext.save()
            
        } catch {
            print("Error saving response: \(error)")
        }
    }
    
    private func updateTopicProgress(for user: UserProfile, question: Question, isCorrect: Bool) {
        // Find existing topic progress
        let topicDescriptor = FetchDescriptor<TopicProgress>(
            predicate: #Predicate<TopicProgress> { 
                $0.user?.id == user.id && $0.topic == question.topic
            }
        )
        
        do {
            let topicProgressEntries = try modelContext.fetch(topicDescriptor)
            
            if let progress = topicProgressEntries.first {
                // Update existing progress
                progress.updateProgress(isCorrect: isCorrect)
            } else {
                // Create new topic progress
                let newProgress = TopicProgress(topic: question.topic, user: user)
                newProgress.updateProgress(isCorrect: isCorrect)
                modelContext.insert(newProgress)
            }
        } catch {
            print("Error updating topic progress: \(error)")
        }
    }
}

#Preview {
    let modelContainer = try! ModelContainer(for: [
        Question.self,
        UserProfile.self,
        TestSession.self,
        QuestionResponse.self,
        TopicProgress.self
    ])
    
    let sampleQuestion = Question(
        text: "If $x + 3 = 7$, what is the value of $x$?",
        optionA: "$x = 2$",
        optionB: "$x = 3$",
        optionC: "$x = 4$",
        optionD: "$x = 5$",
        optionE: "$x = 10$",
        correctOption: "C",
        topic: "algebra",
        difficulty: "easy"
    )
    
    let authViewModel = AuthViewModel(modelContext: modelContainer.mainContext)
    
    return NavigationView {
        QuestionView(question: sampleQuestion)
            .environmentObject(authViewModel)
    }
}
