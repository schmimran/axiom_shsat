import Foundation
import AuthenticationServices
import SwiftData
import Combine

enum AuthState {
    case signedOut
    case signingIn
    case signedIn
    case error(Error)
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .signedOut
    @Published var currentUser: UserProfile?
    
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        if let userId = UserDefaults.standard.string(forKey: "appleUserId") {
            authState = .signingIn
            loadUser(userId: userId)
        }
    }
    
    private func loadUser(userId: String) {
        let predicate = #Predicate<UserProfile> { $0.appleUserId == userId }
        let descriptor = FetchDescriptor<UserProfile>(predicate: predicate)
        
        do {
            let existingUsers = try modelContext.fetch(descriptor)
            if let existingUser = existingUsers.first {
                currentUser = existingUser
                existingUser.lastActive = Date()
                authState = .signedIn
            } else {
                authState = .signedOut
                UserDefaults.standard.removeObject(forKey: "appleUserId")
            }
        } catch {
            authState = .error(error)
            print("Error loading user: \(error)")
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        authState = .signingIn
        
        // Extract user info from credential
        let userId = credential.user
        let email = credential.email
        
        // Get name from credential if available
        let firstName = credential.fullName?.givenName ?? ""
        let lastName = credential.fullName?.familyName ?? ""
        let displayName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        let finalName = !displayName.isEmpty ? displayName : "SHSAT Student"
        
        // Save user ID to UserDefaults
        UserDefaults.standard.set(userId, forKey: "appleUserId")
        
        // Check if user exists
        let predicate = #Predicate<UserProfile> { $0.appleUserId == userId }
        let descriptor = FetchDescriptor<UserProfile>(predicate: predicate)
        
        do {
            let existingUsers = try modelContext.fetch(descriptor)
            
            if let existingUser = existingUsers.first {
                // Update existing user
                existingUser.lastActive = Date()
                if !displayName.isEmpty {
                    existingUser.displayName = finalName
                }
                if email != nil && existingUser.email == nil {
                    existingUser.email = email
                }
                currentUser = existingUser
            } else {
                // Create new user
                let newUser = UserProfile(
                    appleUserId: userId,
                    displayName: finalName,
                    email: email
                )
                modelContext.insert(newUser)
                currentUser = newUser
                
                // Initialize topic progress for common topics
                initializeTopicProgress(for: newUser)
            }
            
            authState = .signedIn
            
            // Sync with CloudKit would go here
            syncWithCloudKit()
            
        } catch {
            authState = .error(error)
            print("Error signing in with Apple: \(error)")
        }
    }
    
    private func initializeTopicProgress(for user: UserProfile) {
        // Standard SHSAT topics
        let topics = ["algebra", "geometry", "numbers", "probability", "general"]
        
        for topic in topics {
            let topicProgress = TopicProgress(topic: topic, user: user)
            modelContext.insert(topicProgress)
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        currentUser = nil
        authState = .signedOut
    }
    
    private func syncWithCloudKit() {
        // CloudKit sync logic would go here
        // This would involve saving user data to CloudKit private database
    }
    
    var isAuthenticated: Bool {
        if case .signedIn = authState {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .signingIn = authState {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let error) = authState {
            return error.localizedDescription
        }
        return nil
    }
}
