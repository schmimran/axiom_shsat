//
//  UserProfile.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftData
import Foundation

@Model
final class UserProfile {
    var id: UUID
    var appleUserId: String
    var displayName: String
    var email: String?
    var dateJoined: Date
    var lastActive: Date
    var streak: Int
    var totalQuestionsAnswered: Int
    var totalCorrectAnswers: Int
    
    @Relationship(deleteRule: .cascade, inverse: \TestSession.user)
    var sessions: [TestSession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \TopicProgress.user)
    var topicProgress: [TopicProgress] = []
    
    init(
        id: UUID = UUID(),
        appleUserId: String,
        displayName: String,
        email: String? = nil
    ) {
        self.id = id
        self.appleUserId = appleUserId
        self.displayName = displayName
        self.email = email
        self.dateJoined = Date()
        self.lastActive = Date()
        self.streak = 0
        self.totalQuestionsAnswered = 0
        self.totalCorrectAnswers = 0
    }
    
    var overallAccuracy: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(totalQuestionsAnswered) * 100
    }
    
    func updateActivity() {
        let calendar = Calendar.current
        let lastActiveDay = calendar.startOfDay(for: lastActive)
        let today = calendar.startOfDay(for: Date())
        
        if calendar.isDate(lastActiveDay, inSameDayAs: today) {
            // Already active today, just update the timestamp
            lastActive = Date()
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  calendar.isDate(lastActiveDay, inSameDayAs: yesterday) {
            // Active yesterday, increment streak
            streak += 1
            lastActive = Date()
        } else {
            // Break in streak
            streak = 1
            lastActive = Date()
        }
    }
}