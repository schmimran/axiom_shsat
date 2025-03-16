//
//  SessionType.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftData
import Foundation

enum SessionType: String, Codable {
    case practice = "Practice"
    case fullTest = "Full Test"
    case topicReview = "Topic Review"
    case dailyChallenge = "Daily Challenge"
}

@Model
final class TestSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var totalQuestions: Int
    var correctAnswers: Int
    var completed: Bool
    var sessionType: String
    var topics: [String]
    var difficulty: String?
    var duration: TimeInterval?
    
    @Relationship(deleteRule: .nullify, inverse: \UserProfile.sessions)
    var user: UserProfile?
    
    @Relationship(deleteRule: .cascade, inverse: \QuestionResponse.session)
    var responses: [QuestionResponse] = []
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        totalQuestions: Int,
        sessionType: String,
        topics: [String] = [],
        difficulty: String? = nil,
        user: UserProfile? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.totalQuestions = totalQuestions
        self.correctAnswers = 0
        self.completed = false
        self.sessionType = sessionType
        self.topics = topics
        self.difficulty = difficulty
        self.user = user
    }
    
    var accuracyPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    var completedQuestionsCount: Int {
        return responses.count
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func complete() {
        guard !completed else { return }
        
        endTime = Date()
        completed = true
        
        if let startTime = startTime, let endTime = endTime {
            duration = endTime.timeIntervalSince(startTime)
        }
        
        // Update user statistics
        user?.totalQuestionsAnswered += totalQuestions
        user?.totalCorrectAnswers += correctAnswers
        user?.updateActivity()
    }
}