import SwiftUI
import SwiftData

@main
struct SHSAT_PrepperApp: App {
    @StateObject private var authViewModel: AuthViewModel
    private let environment = AppEnvironment.shared
    
    init() {
        _authViewModel = StateObject(wrappedValue: AuthViewModel(environment: AppEnvironment.shared))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(environment)
        }
        .modelContainer(environment.modelContainer)
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var environment: AppEnvironment
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if let userId = authViewModel.currentUser?.id {
                    HomeView(userId: userId)
                        .environmentObject(environment)
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
        let questionService = environment.questionService
        
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
