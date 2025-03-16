//
//  TopicProgress.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftData
import Foundation

@Model
final class TopicProgress {
    var id: UUID
    var topic: String
    var questionsAttempted: Int
    var correctAnswers: Int
    var lastPracticed: Date
    
    @Relationship(deleteRule: .nullify, inverse: \UserProfile.topicProgress)
    var user: UserProfile?
    
    init(
        id: UUID = UUID(),
        topic: String,
        user: UserProfile? = nil
    ) {
        self.id = id
        self.topic = topic
        self.questionsAttempted = 0
        self.correctAnswers = 0
        self.lastPracticed = Date()
        self.user = user
    }
    
    var proficiencyPercentage: Double {
        guard questionsAttempted > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAttempted) * 100
    }
    
    func updateProgress(isCorrect: Bool) {
        questionsAttempted += 1
        if isCorrect {
            correctAnswers += 1
        }
        lastPracticed = Date()
    }
    
    var proficiencyLevel: String {
        let percentage = proficiencyPercentage
        
        switch percentage {
        case 0..<20:
            return "Beginner"
        case 20..<40:
            return "Developing"
        case 40..<60:
            return "Intermediate"
        case 60..<80:
            return "Proficient"
        case 80...100:
            return "Expert"
        default:
            return "Unknown"
        }
    }
    
    var proficiencyColor: String {
        let percentage = proficiencyPercentage
        
        switch percentage {
        case 0..<20:
            return "#FF6B6B" // Red
        case 20..<40:
            return "#FFD166" // Yellow
        case 40..<60:
            return "#06D6A0" // Green
        case 60..<80:
            return "#118AB2" // Blue
        case 80...100:
            return "#073B4C" // Dark Blue
        default:
            return "#CCCCCC" // Gray
        }
    }
}