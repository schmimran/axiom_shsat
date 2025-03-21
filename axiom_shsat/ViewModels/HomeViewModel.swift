import Foundation
import SwiftData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var dailyChallenge: Question?
    @Published var recommendedTopics: [TopicProgress] = []
    @Published var recentSessions: [TestSession] = []
    @Published var overallPerformance: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let environment: AppEnvironment
    private var modelContext: ModelContext { environment.modelContext }
    private let progressViewModel: ProgressViewModel
    private var questionService: QuestionService { environment.questionService }
    private var cancellables = Set<AnyCancellable>()
    private let userId: UUID
    
    init(environment: AppEnvironment, userId: UUID) {
        self.environment = environment
        self.userId = userId
        self.progressViewModel = ProgressViewModel(environment: environment, userId: userId)
    }
    
    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load progress data first
            await progressViewModel.loadData()
            
            // Get recommended topics based on progress
            recommendedTopics = progressViewModel.getTopicRecommendations()
            
            // Get recent sessions
            recentSessions = progressViewModel.recentSessions
            
            // Get overall performance
            overallPerformance = progressViewModel.overallAccuracy
            
            // Generate daily challenge
            await generateDailyChallenge()
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func generateDailyChallenge() async {
        // Check if we've already generated a challenge today
        if let existingChallenge = UserDefaults.standard.string(forKey: getDailyChallengeKey()),
           let questionId = UUID(uuidString: existingChallenge) {
            // Fetch the existing challenge
            var descriptor = FetchDescriptor<Question>(
                predicate: #Predicate<Question> { $0.id == questionId }
            )
            
            do {
                let questions = try modelContext.fetch(descriptor)
                if let question = questions.first {
                    dailyChallenge = question
                    return
                }
            } catch {
                print("Error fetching existing daily challenge: \(error)")
                // Continue to generate a new challenge if there was an error
            }
        }
        
        // Generate a new challenge
        do {
            // Get a random question with medium-hard difficulty
            let difficulties = ["medium", "hard"]
            let questions = try await questionService.getQuestions(
                difficulty: difficulties.randomElement(),
                limit: 10
            )
            
            if let randomQuestion = questions.randomElement() {
                dailyChallenge = randomQuestion
                
                // Save the question ID for today
                UserDefaults.standard.set(
                    randomQuestion.id.uuidString,
                    forKey: getDailyChallengeKey()
                )
            }
        } catch {
            print("Error generating daily challenge: \(error)")
        }
    }
    
    private func getDailyChallengeKey() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "dailyChallenge-\(dateString)"
    }
    
    func startPracticeSession(for topic: String? = nil, difficulty: String? = nil, questionCount: Int = 10) async -> TestSession? {
        do {
            // Get the user
            let userDescriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate<UserProfile> { $0.id == self.userId }
            )
            
            let users = try modelContext.fetch(userDescriptor)
            guard let user = users.first else {
                throw SessionError.userNotFound
            }
            
            // Create a new session
            let topics = topic != nil ? [topic!] : []
            let sessionType = topic != nil ? SessionType.topicReview.rawValue : SessionType.practice.rawValue
            
            let session = TestSession(
                totalQuestions: questionCount,
                sessionType: sessionType,
                topics: topics,
                difficulty: difficulty,
                user: user
            )
            
            modelContext.insert(session)
            try modelContext.save()
            
            return session
        } catch {
            errorMessage = "Failed to start practice session: \(error.localizedDescription)"
            return nil
        }
    }
    
    var dailyStreak: Int {
        return progressViewModel.currentStreak
    }
    
    var questionsAnsweredToday: Int {
        return progressViewModel.questionsAnsweredToday
    }
    
    var mostImprovedTopic: String {
        return progressViewModel.mostImprovedTopic?.topic.capitalized ?? "N/A"
    }
    
    var weeklyProgress: Double {
        return progressViewModel.weeklyProgress
    }
}

enum SessionError: Error {
    case userNotFound
    case sessionCreationFailed
}

extension SessionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return NSLocalizedString("User profile not found", comment: "")
        case .sessionCreationFailed:
            return NSLocalizedString("Failed to create practice session", comment: "")
        }
    }
}
