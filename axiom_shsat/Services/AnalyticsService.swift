import Foundation
import SwiftData
import Combine

class AnalyticsService {
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - User Session Analytics
    
    /// Record a user session start
    func recordSessionStart(userId: UUID, sessionType: String) {
        let event = AnalyticsEvent(
            eventType: "session_start",
            userId: userId,
            properties: [
                "session_type": sessionType,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        saveEvent(event)
    }
    
    /// Record a user session end
    func recordSessionEnd(userId: UUID, sessionType: String, duration: TimeInterval, questionsAnswered: Int, correctAnswers: Int) {
        let event = AnalyticsEvent(
            eventType: "session_end",
            userId: userId,
            properties: [
                "session_type": sessionType,
                "duration": String(duration),
                "questions_answered": String(questionsAnswered),
                "correct_answers": String(correctAnswers),
                "accuracy": String(questionsAnswered > 0 ? Double(correctAnswers) / Double(questionsAnswered) * 100 : 0),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        saveEvent(event)
    }
    
    // MARK: - Question Analytics
    
    /// Record a question answer event
    func recordQuestionAnswer(userId: UUID, questionId: UUID, topic: String, difficulty: String, isCorrect: Bool, responseTime: TimeInterval) {
        let event = AnalyticsEvent(
            eventType: "question_answer",
            userId: userId,
            properties: [
                "question_id": questionId.uuidString,
                "topic": topic,
                "difficulty": difficulty,
                "is_correct": String(isCorrect),
                "response_time": String(responseTime),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        saveEvent(event)
    }
    
    // MARK: - App Usage Analytics
    
    /// Record app open event
    func recordAppOpen(userId: UUID?) {
        let event = AnalyticsEvent(
            eventType: "app_open",
            userId: userId,
            properties: [
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        saveEvent(event)
    }
    
    /// Record app close event
    func recordAppClose(userId: UUID?, sessionDuration: TimeInterval) {
        let event = AnalyticsEvent(
            eventType: "app_close",
            userId: userId,
            properties: [
                "session_duration": String(sessionDuration),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        saveEvent(event)
    }
    
    /// Record screen view event
    func recordScreenView(userId: UUID?, screenName: String) {
        let event = AnalyticsEvent(
            eventType: "screen_view",
            userId: userId,
            properties: [
                "screen_name": screenName,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        saveEvent(event)
    }
    
    /// Record user action event
    func recordUserAction(userId: UUID?, actionName: String, additionalProperties: [String: String] = [:]) {
        var properties = additionalProperties
        properties["action_name"] = actionName
        properties["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        let event = AnalyticsEvent(
            eventType: "user_action",
            userId: userId,
            properties: properties
        )
        saveEvent(event)
    }
    
    // MARK: - Analytics Data Access
    
    /// Get user performance by topic
    func getUserPerformanceByTopic(userId: UUID) async throws -> [TopicPerformance] {
        let descriptor = FetchDescriptor<QuestionResponse>(
            predicate: #Predicate<QuestionResponse> { $0.session?.user?.id == userId }
        )
        
        let responses = try modelContext.fetch(descriptor)
        
        // Group responses by topic
        var topicResponses: [String: [QuestionResponse]] = [:]
        
        for response in responses {
            guard let topic = response.question?.topic else { continue }
            
            if topicResponses[topic] == nil {
                topicResponses[topic] = []
            }
            
            topicResponses[topic]?.append(response)
        }
        
        // Calculate performance metrics for each topic
        return topicResponses.map { topic, responses in
            let totalQuestions = responses.count
            let correctAnswers = responses.filter { $0.isCorrect }.count
            let totalResponseTime = responses.reduce(0) { $0 + $1.responseTime }
            let averageResponseTime = totalQuestions > 0 ? totalResponseTime / Double(totalQuestions) : 0
            
            return TopicPerformance(
                topic: topic,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                averageResponseTime: averageResponseTime,
                accuracyPercentage: totalQuestions > 0 ? (Double(correctAnswers) / Double(totalQuestions) * 100) : 0
            )
        }
    }
    
    /// Get user performance over time
    func getUserPerformanceOverTime(userId: UUID, timeFrame: TimeFrame = .month) async throws -> [DailyPerformance] {
        let currentDate = Date()
        let calendar = Calendar.current
        
        let startDate: Date
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: currentDate) ?? currentDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: currentDate) ?? currentDate
        case .year:
            startDate = calendar.date(byAdding: .day, value: -365, to: currentDate) ?? currentDate
        case .custom(let days):
            startDate = calendar.date(byAdding: .day, value: -days, to: currentDate) ?? currentDate
        }
        
        let descriptor = FetchDescriptor<QuestionResponse>(
            predicate: #Predicate<QuestionResponse> {
                $0.session?.user?.id == userId && $0.timestamp >= startDate
            },
            sortBy: [SortDescriptor(\QuestionResponse.timestamp)]
        )
        
        let responses = try modelContext.fetch(descriptor)
        
        // Group responses by day
        var dailyResponses: [Date: [QuestionResponse]] = [:]
        
        for response in responses {
            guard let timestamp = response.timestamp else { continue }
            
            let day = calendar.startOfDay(for: timestamp)
            
            if dailyResponses[day] == nil {
                dailyResponses[day] = []
            }
            
            dailyResponses[day]?.append(response)
        }
        
        // Create a list of all days in the time frame
        var allDays: [Date] = []
        var currentDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: currentDate)
        
        while currentDay <= endDay {
            allDays.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
        }
        
        // Calculate performance for each day
        return allDays.map { day in
            let dayResponses = dailyResponses[day] ?? []
            let totalQuestions = dayResponses.count
            let correctAnswers = dayResponses.filter { $0.isCorrect }.count
            
            return DailyPerformance(
                date: day,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                accuracyPercentage: totalQuestions > 0 ? (Double(correctAnswers) / Double(totalQuestions) * 100) : 0
            )
        }
    }
    
    /// Get user performance by difficulty
    func getUserPerformanceByDifficulty(userId: UUID) async throws -> [DifficultyPerformance] {
        let descriptor = FetchDescriptor<QuestionResponse>(
            predicate: #Predicate<QuestionResponse> { $0.session?.user?.id == userId }
        )
        
        let responses = try modelContext.fetch(descriptor)
        
        // Group responses by difficulty
        var difficultyResponses: [String: [QuestionResponse]] = [:]
        
        for response in responses {
            guard let difficulty = response.question?.difficulty else { continue }
            
            if difficultyResponses[difficulty] == nil {
                difficultyResponses[difficulty] = []
            }
            
            difficultyResponses[difficulty]?.append(response)
        }
        
        // Calculate performance metrics for each difficulty
        return difficultyResponses.map { difficulty, responses in
            let totalQuestions = responses.count
            let correctAnswers = responses.filter { $0.isCorrect }.count
            let totalResponseTime = responses.reduce(0) { $0 + $1.responseTime }
            let averageResponseTime = totalQuestions > 0 ? totalResponseTime / Double(totalQuestions) : 0
            
            return DifficultyPerformance(
                difficulty: difficulty,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                averageResponseTime: averageResponseTime,
                accuracyPercentage: totalQuestions > 0 ? (Double(correctAnswers) / Double(totalQuestions) * 100) : 0
            )
        }
    }
    
    /// Get user session statistics
    func getUserSessionStatistics(userId: UUID) async throws -> SessionStatistics {
        let descriptor = FetchDescriptor<TestSession>(
            predicate: #Predicate<TestSession> { $0.user?.id == userId }
        )
        
        let sessions = try modelContext.fetch(descriptor)
        
        let totalSessions = sessions.count
        let totalQuestions = sessions.reduce(0) { $0 + $1.totalQuestions }
        let totalCorrect = sessions.reduce(0) { $0 + $1.correctAnswers }
        
        // Calculate total study time
        let totalStudyTime = sessions.reduce(0) { total, session in
            guard let duration = session.duration else { return total }
            return total + duration
        }
        
        // Calculate average session length
        let averageSessionLength = totalSessions > 0 ? totalStudyTime / Double(totalSessions) : 0
        
        // Calculate accuracy
        let overallAccuracy = totalQuestions > 0 ? (Double(totalCorrect) / Double(totalQuestions) * 100) : 0
        
        return SessionStatistics(
            totalSessions: totalSessions,
            totalQuestions: totalQuestions,
            totalCorrect: totalCorrect,
            totalStudyTime: totalStudyTime,
            averageSessionLength: averageSessionLength,
            overallAccuracy: overallAccuracy
        )
    }
    
    // MARK: - Helper Functions
    
    private func saveEvent(_ event: AnalyticsEvent) {
        // In a real app, this would send the event to a backend analytics service
        // For now, we'll just log it
        print("Analytics event: \(event.eventType), properties: \(event.properties)")
        
        // Store event in local database for offline collection
        modelContext.insert(event)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving analytics event: \(error)")
        }
    }
}

// MARK: - Analytics Models

/// Model for an analytics event
@Model
class AnalyticsEvent {
    var id: UUID
    var eventType: String
    var userId: UUID?
    var timestamp: Date
    var properties: [String: String]
    
    init(eventType: String, userId: UUID? = nil, properties: [String: String] = [:]) {
        self.id = UUID()
        self.eventType = eventType
        self.userId = userId
        self.timestamp = Date()
        self.properties = properties
    }
}

/// Enum for time frame selection
enum TimeFrame {
    case week
    case month
    case year
    case custom(days: Int)
}

/// Struct for topic performance data
struct TopicPerformance: Identifiable {
    var id: String { topic }
    let topic: String
    let totalQuestions: Int
    let correctAnswers: Int
    let averageResponseTime: Double
    let accuracyPercentage: Double
}

/// Struct for daily performance data
struct DailyPerformance: Identifiable {
    var id: Date { date }
    let date: Date
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracyPercentage: Double
}

/// Struct for difficulty level performance data
struct DifficultyPerformance: Identifiable {
    var id: String { difficulty }
    let difficulty: String
    let totalQuestions: Int
    let correctAnswers: Int
    let averageResponseTime: Double
    let accuracyPercentage: Double
}

/// Struct for session statistics
struct SessionStatistics {
    let totalSessions: Int
    let totalQuestions: Int
    let totalCorrect: Int
    let totalStudyTime: TimeInterval
    let averageSessionLength: TimeInterval
    let overallAccuracy: Double
}
