//
//  QuestionResponse.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftData
import Foundation

@Model
final class QuestionResponse {
    var id: UUID
    var selectedOption: String
    var isCorrect: Bool
    var timestamp: Date
    var responseTime: TimeInterval
    
    @Relationship(deleteRule: .nullify, inverse: \Question.responses)
    var question: Question?
    
    @Relationship(deleteRule: .nullify, inverse: \TestSession.responses)
    var session: TestSession?
    
    init(
        id: UUID = UUID(),
        selectedOption: String,
        isCorrect: Bool,
        responseTime: TimeInterval,
        question: Question? = nil,
        session: TestSession? = nil
    ) {
        self.id = id
        self.selectedOption = selectedOption
        self.isCorrect = isCorrect
        self.timestamp = Date()
        self.responseTime = responseTime
        self.question = question
        self.session = session
        
        // Update question statistics
        if let question = question {
            question.lastAttempted = Date()
            question.timesAttempted += 1
            if isCorrect {
                question.timesCorrect += 1
            }
        }
        
        // Update session statistics
        if let session = session, isCorrect {
            session.correctAnswers += 1
        }
    }
}