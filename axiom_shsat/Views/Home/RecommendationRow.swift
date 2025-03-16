//
//  RecommendationRow.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI

struct RecommendationRow: View {
    let topic: TopicProgress
    let onPractice: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(topic.topic.capitalized)
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ProficiencyBadge(proficiency: Int(topic.proficiencyPercentage))
                    
                    Text("Last practiced: \(topic.lastPracticed, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onPractice) {
                Text("Practice")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
        }
        .padding()
        .background(rowBackground)
        .cornerRadius(10)
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(progressColor.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var progressColor: Color {
        let percentage = topic.proficiencyPercentage
        
        switch percentage {
        case 0..<30:
            return .red
        case 30..<60:
            return .orange
        case 60..<80:
            return .blue
        default:
            return .green
        }
    }
}

struct ProficiencyBadge: View {
    let proficiency: Int
    
    var body: some View {
        Text("\(proficiency)%")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(badgeColor)
            )
            .foregroundColor(proficiency > 50 ? .white : .primary)
    }
    
    private var badgeColor: Color {
        switch proficiency {
        case 0..<30:
            return .red.opacity(0.8)
        case 30..<60:
            return .orange.opacity(0.8)
        case 60..<80:
            return .blue.opacity(0.8)
        default:
            return .green.opacity(0.8)
        }
    }
}

#Preview {
    let dummyTopic = TopicProgress(
        id: UUID(),
        topic: "Algebra"
    )
    dummyTopic.questionsAttempted = 25
    dummyTopic.correctAnswers = 15
    dummyTopic.lastPracticed = Date().addingTimeInterval(-86400)
    
    return VStack(spacing: 16) {
        // Low proficiency
        let lowTopic = TopicProgress(id: UUID(), topic: "Geometry")
        lowTopic.questionsAttempted = 10
        lowTopic.correctAnswers = 2
        lowTopic.lastPracticed = Date().addingTimeInterval(-86400 * 7)
        
        RecommendationRow(topic: lowTopic) {
            print("Practice geometry")
        }
        
        // Medium proficiency
        let medTopic = TopicProgress(id: UUID(), topic: "algebra")
        medTopic.questionsAttempted = 20
        medTopic.correctAnswers = 10
        medTopic.lastPracticed = Date().addingTimeInterval(-86400 * 2)
        
        RecommendationRow(topic: medTopic) {
            print("Practice algebra")
        }
        
        // High proficiency
        let highTopic = TopicProgress(id: UUID(), topic: "probability")
        highTopic.questionsAttempted = 30
        highTopic.correctAnswers = 27
        highTopic.lastPracticed = Date()
        
        RecommendationRow(topic: highTopic) {
            print("Practice probability")
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
