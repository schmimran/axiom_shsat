//
//  RecommendationRow.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData
// Ensure we have access to shared components
import Foundation

struct RecommendationRow: View {
    let topic: TopicProgress
    let onPractice: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(topic.topic.capitalized)
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ProficiencyBadge(percentage: topic.proficiencyPercentage)
                    
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

// Using the shared ProficiencyBadge from UIComponents.swift

#Preview {
    let sampleTopics = PreviewSampleData.createSampleTopics()
    
    Group {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(sampleTopics) { topic in
                    RecommendationRow(topic: topic) {
                        print("Practice \(topic.topic)")
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    .modelContainer(AppEnvironment.shared.modelContainer)
}

// Helper for creating preview data
fileprivate enum PreviewSampleData {
    static func createSampleTopics() -> [TopicProgress] {
        let topics = [
            (name: "Geometry", attempted: 10, correct: 2, daysAgo: 7),
            (name: "Algebra", attempted: 20, correct: 10, daysAgo: 2),
            (name: "Probability", attempted: 30, correct: 27, daysAgo: 0)
        ]
        
        return topics.map { data in
            let topic = TopicProgress(id: UUID(), topic: data.name)
            topic.questionsAttempted = data.attempted
            topic.correctAnswers = data.correct
            topic.lastPracticed = Date().addingTimeInterval(-86400 * Double(data.daysAgo))
            return topic
        }
    }
}
