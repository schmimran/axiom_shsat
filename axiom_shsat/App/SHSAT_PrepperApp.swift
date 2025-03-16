//
//  SHSAT_PrepperApp.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData

@main
struct SHSAT_PrepperApp: App {
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        let container = ModelContainer.shared
        _authViewModel = StateObject(wrappedValue: AuthViewModel(modelContext: container.mainContext))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
        .modelContainer(ModelContainer.shared)
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if let userId = authViewModel.currentUser?.id {
                    HomeView(modelContext: ModelContainer.shared.mainContext, userId: userId)
                } else {
                    // Fallback if user ID is missing but authenticated state is true
                    Text("Error loading user profile")
                        .onAppear {
                            authViewModel.signOut()
                        }
                }
            } else {
                AuthenticationView()
            }
        }
        .task {
            // Preload sample questions on first launch
            if UserDefaults.standard.bool(forKey: "initialQuestionsLoaded") == false {
                await loadInitialQuestions()
            }
        }
    }
    
    private func loadInitialQuestions() async {
        let questionService = QuestionService(modelContext: ModelContainer.shared.mainContext)
        
        do {
            // Import questions from the CSV file in the bundle
            let count = try await questionService.importQuestionsFromBundle(fileName: "SampleQuestions")
            
            if count > 0 {
                UserDefaults.standard.set(true, forKey: "initialQuestionsLoaded")
                print("Successfully loaded \(count) initial questions")
            }
        } catch {
            print("Error loading initial questions: \(error)")
        }
    }
}

// Shared ModelContainer
extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Question.self,
            TestSession.self,
            QuestionResponse.self,
            TopicProgress.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
