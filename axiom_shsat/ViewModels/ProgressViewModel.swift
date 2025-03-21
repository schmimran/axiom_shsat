import Foundation
import SwiftData
import Combine

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var topicProgress: [TopicProgress] = []
    @Published var recentSessions: [TestSession] = []
    @Published var dailyStats: [(date: Date, count: Int, correct: Int)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let environment: AppEnvironment
    private var modelContext: ModelContext { environment.modelContext }
    let userId: UUID
    private var cancellables = Set<AnyCancellable>()
    
    init(environment: AppEnvironment, userId: UUID) {
        self.environment = environment
        self.userId = userId
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load topic progress
            var topicDescriptor = FetchDescriptor<TopicProgress>(
                predicate: #Predicate<TopicProgress> { $0.user?.id == userId }
            )
            topicDescriptor.sortBy = [SortDescriptor(\.proficiencyPercentage, order: .forward)]
            
            topicProgress = try modelContext.fetch(topicDescriptor)
            
            // Load recent sessions
            var sessionDescriptor = FetchDescriptor<TestSession>(
                predicate: #Predicate<TestSession> { $0.user?.id == userId }
            )
            sessionDescriptor.sortBy = [SortDescriptor(\.startTime, order: .reverse)]
            sessionDescriptor.fetchLimit = 10
            
            recentSessions = try modelContext.fetch(sessionDescriptor)
            
            // Generate daily stats for the last 30 days
            await loadDailyStats()
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load progress data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func loadDailyStats() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        var resultStats: [(date: Date, count: Int, correct: Int)] = []
        
        // Create a date for each of the last 30 days
        for dayOffset in 0..<30 {
            let currentDate = calendar.date(byAdding: .day, value: -dayOffset, to: endDate)!
            let startOfDay = calendar.startOfDay(for: currentDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // Fetch responses for this day
            var responseDescriptor = FetchDescriptor<QuestionResponse>(
                predicate: #Predicate<QuestionResponse> {
                    $0.session?.user?.id == userId &&
                    $0.timestamp >= startOfDay &&
                    $0.timestamp < endOfDay
                }
            )
            
            do {
                let responses = try modelContext.fetch(responseDescriptor)
                let totalCount = responses.count
                let correctCount = responses.filter { $0.isCorrect }.count
                
                resultStats.append((date: startOfDay, count: totalCount, correct: correctCount))
            } catch {
                print("Error fetching daily stats: \(error)")
                // Add empty data for this day
                resultStats.append((date: startOfDay, count: 0, correct: 0))
            }
        }
        
        // Sort by date (oldest to newest)
        dailyStats = resultStats.sorted { $0.date < $1.date }
    }
    
    func getTopicRecommendations() -> [TopicProgress] {
        // Return the top 3 weakest topics
        return topicProgress
            .sorted { $0.proficiencyPercentage < $1.proficiencyPercentage }
            .prefix(3)
            .map { $0 }
    }
    
    var overallAccuracy: Double {
        let allSessions = recentSessions
        guard !allSessions.isEmpty else { return 0 }
        
        let totalQuestions = allSessions.reduce(0) { $0 + $1.totalQuestions }
        let totalCorrect = allSessions.reduce(0) { $0 + $1.correctAnswers }
        
        guard totalQuestions > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestions) * 100
    }
    
    var questionsAnsweredToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return dailyStats.last?.count ?? 0
    }
    
    var currentStreak: Int {
        guard let user = try? getUserProfile() else { return 0 }
        return user.streak
    }
    
    private func getUserProfile() throws -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id == userId }
        )
        
        let users = try modelContext.fetch(descriptor)
        return users.first
    }
    
    var weeklyProgress: Double {
        // Calculate improvement over the last week
        guard dailyStats.count >= 7 else { return 0 }
        
        let lastWeek = Array(dailyStats.suffix(7))
        let totalAnswered = lastWeek.reduce(0) { $0 + $1.count }
        let totalCorrect = lastWeek.reduce(0) { $0 + $1.correct }
        
        guard totalAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswered) * 100
    }
    
    var mostImprovedTopic: TopicProgress? {
        // This would require historical data to track improvement over time
        // For now, just return the highest proficiency topic
        return topicProgress.max { $0.proficiencyPercentage < $1.proficiencyPercentage }
    }
}
