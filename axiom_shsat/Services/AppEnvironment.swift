import Foundation
import SwiftData
import SwiftUI

/// Central environment for app-wide dependencies and services
@MainActor
class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    // Core data access
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    // Service singletons
    let authService: AuthenticationService
    let questionService: QuestionService
    let cloudKitService: CloudKitService
    
    private init() {
        // Initialize ModelContainer
        do {
            let schema = Schema([
                UserProfile.self, Question.self, TestSession.self, 
                QuestionResponse.self, TopicProgress.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            self.modelContext = modelContainer.mainContext
            
            // Initialize services
            self.cloudKitService = CloudKitService()
            self.authService = AuthenticationService(modelContext: modelContext)
            self.questionService = QuestionService(modelContext: modelContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}