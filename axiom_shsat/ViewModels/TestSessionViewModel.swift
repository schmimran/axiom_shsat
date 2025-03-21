import Foundation
import SwiftData
import Combine

@MainActor
class TestSessionViewModel: ObservableObject {
    // Session state properties
    @Published var currentQuestionIndex = 0
    @Published var questions: [Question] = []
    @Published var selectedAnswer: String?
    @Published var session: TestSession?
    @Published var isLoading = false
    @Published var isCompleted = false
    @Published var sessionError: Error?
    @Published var responseStartTime: Date?
    @Published var responses: [QuestionResponse] = []
    @Published var showExplanation = false
    
    // Configuration properties
    @Published var topic: String?
    @Published var difficulty: String?
    @Published var questionCount: Int = 10
    
    private let environment: AppEnvironment
    private var modelContext: ModelContext { environment.modelContext }
    private var cancellables = Set<AnyCancellable>()
    
    init(environment: AppEnvironment) {
        self.environment = environment
    }
    
    func startNewSession(
        sessionType: String,
        topics: [String] = [],
        difficulty: String? = nil,
        questionCount: Int = 10,
        user: UserProfile? = nil
    ) {
        isLoading = true
        sessionError = nil
        
        // Create new test session
        let newSession = TestSession(
            totalQuestions: questionCount,
            sessionType: sessionType,
            topics: topics,
            difficulty: difficulty,
            user: user
        )
        
        modelContext.insert(newSession)
        session = newSession
        
        // Fetch questions
        loadQuestions(topics: topics, difficulty: difficulty, count: questionCount)
        
        // Reset state
        currentQuestionIndex = 0
        responseStartTime = Date()
        isCompleted = false
        isLoading = false
    }
    
    private func loadQuestions(topics: [String], difficulty: String?, count: Int) {
        // Construct filter predicate
        var predicate: Predicate<Question>?
        
        if !topics.isEmpty && difficulty != nil {
            predicate = #Predicate<Question> { question in
                topics.contains(question.topic) && question.difficulty == difficulty!
            }
        } else if !topics.isEmpty {
            predicate = #Predicate<Question> { question in
                topics.contains(question.topic)
            }
        } else if let difficulty = difficulty {
            predicate = #Predicate<Question> { question in
                question.difficulty == difficulty
            }
        }
        
        // Set up fetch descriptor
        var descriptor = FetchDescriptor<Question>()
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        
        // Add randomization
        descriptor.sortBy = [SortDescriptor(\.id, order: .forward)]
        
        do {
            var fetchedQuestions = try modelContext.fetch(descriptor)
            
            // If we don't have enough questions, get additional ones
            if fetchedQuestions.count < count {
                let remainingCount = count - fetchedQuestions.count
                var backupDescriptor = FetchDescriptor<Question>()
                backupDescriptor.fetchLimit = remainingCount
                let additionalQuestions = try modelContext.fetch(backupDescriptor)
                fetchedQuestions.append(contentsOf: additionalQuestions)
            }
            
            // Shuffle and limit to requested count
            questions = Array(fetchedQuestions.shuffled().prefix(count))
        } catch {
            sessionError = error
            questions = []
            print("Error fetching questions: \(error)")
        }
    }
    
    func selectAnswer(_ option: String) {
        guard let currentQuestion = currentQuestion else { return }
        
        selectedAnswer = option
        
        // Calculate response time
        let endTime = Date()
        let responseTime = responseStartTime?.distance(to: endTime) ?? 0
        
        // Check if the answer is correct
        let isCorrect = option == currentQuestion.correctOption
        
        // Create and save response
        let response = QuestionResponse(
            selectedOption: option,
            isCorrect: isCorrect,
            responseTime: responseTime,
            question: currentQuestion,
            session: session
        )
        
        modelContext.insert(response)
        responses.append(response)
        
        // Update topic progress
        updateTopicProgress(question: currentQuestion, isCorrect: isCorrect)
    }
    
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            responseStartTime = Date()
            showExplanation = false
        } else {
            completeSession()
        }
    }
    
    private func completeSession() {
        guard let session = session else { return }
        
        session.complete()
        isCompleted = true
        
        // Save session to persistent storage
        do {
            try modelContext.save()
        } catch {
            sessionError = error
            print("Error saving completed session: \(error)")
        }
    }
    
    private func updateTopicProgress(question: Question, isCorrect: Bool) {
        guard let userId = session?.user?.id else { return }
        
        // Fetch the topic progress for this user and topic
        let predicate = #Predicate<TopicProgress> { progress in
            progress.topic == question.topic && progress.user?.id == userId
        }
        
        let descriptor = FetchDescriptor<TopicProgress>(predicate: predicate)
        
        do {
            let progressEntries = try modelContext.fetch(descriptor)
            
            if let progress = progressEntries.first {
                // Update existing progress
                progress.updateProgress(isCorrect: isCorrect)
            } else {
                // Create new topic progress if it doesn't exist
                let newProgress = TopicProgress(
                    topic: question.topic,
                    user: session?.user
                )
                newProgress.updateProgress(isCorrect: isCorrect)
                modelContext.insert(newProgress)
            }
        } catch {
            print("Error updating topic progress: \(error)")
        }
    }
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progressPercentage: Double {
        guard !questions.isEmpty else { return 0.0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var correctAnswersPercentage: Double {
        guard !responses.isEmpty else { return 0.0 }
        let correctCount = responses.filter { $0.isCorrect }.count
        return Double(correctCount) / Double(responses.count) * 100
    }
    
    var currentQuestionResponse: QuestionResponse? {
        guard let selectedAnswer = selectedAnswer,
              let currentQuestion = currentQuestion else { return nil }
        
        return responses.first { response in 
            response.question?.id == currentQuestion.id
        }
    }
    
    var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
    }
    
    var totalQuestionCount: Int {
        return questions.count
    }
    
    var answeredQuestionsCount: Int {
        return responses.count
    }
    
    func toggleExplanation() {
        showExplanation.toggle()
    }
}
