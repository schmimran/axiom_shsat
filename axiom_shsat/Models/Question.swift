//
//  Question.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftData
import Foundation

@Model
final class Question {
    var id: UUID
    var text: String
    var optionA: String
    var optionB: String
    var optionC: String
    var optionD: String
    var optionE: String
    var correctOption: String
    var topic: String
    var difficulty: String
    var lastAttempted: Date?
    var timesAttempted: Int
    var timesCorrect: Int
    
    @Relationship(deleteRule: .cascade)
    var responses: [QuestionResponse] = []
    
    init(
        id: UUID = UUID(),
        text: String,
        optionA: String,
        optionB: String,
        optionC: String,
        optionD: String,
        optionE: String,
        correctOption: String,
        topic: String,
        difficulty: String
    ) {
        self.id = id
        self.text = text
        self.optionA = optionA
        self.optionB = optionB
        self.optionC = optionC
        self.optionD = optionD
        self.optionE = optionE
        self.correctOption = correctOption
        self.topic = topic
        self.difficulty = difficulty
        self.timesAttempted = 0
        self.timesCorrect = 0
    }
    
    var correctAnswerText: String {
        switch correctOption {
        case "A": return optionA
        case "B": return optionB
        case "C": return optionC
        case "D": return optionD
        case "E": return optionE
        default: return ""
        }
    }
    
    var accuracyPercentage: Double {
        guard timesAttempted > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesAttempted) * 100
    }
}
