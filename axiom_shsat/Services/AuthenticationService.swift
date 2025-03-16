import Foundation
import AuthenticationServices
import CryptoKit
import SwiftData

class AuthenticationService {
    private let modelContext: ModelContext
    private let cloudKitService: CloudKitService
    
    // State for Sign in with Apple
    private var currentNonce: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cloudKitService = CloudKitService()
    }
    
    // MARK: - Sign in with Apple
    
    func prepareSignInWithApple() -> String {
        let nonce = generateNonce()
        currentNonce = nonce
        return nonce
    }
    
    func handleSignInWithAppleCompletion(
        _ result: Result<ASAuthorization, Error>,
        completion: @escaping (Result<UserProfile, AuthError>) -> Void
    ) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                handleAppleIDCredential(appleIDCredential, completion: completion)
            } else {
                completion(.failure(.invalidCredential))
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
            completion(.failure(.authorizationFailed(error)))
        }
    }
    
    private func handleAppleIDCredential(
        _ credential: ASAuthorizationAppleIDCredential,
        completion: @escaping (Result<UserProfile, AuthError>) -> Void
    ) {
        // Verify the nonce
        guard let nonce = currentNonce else {
            completion(.failure(.invalidState))
            return
        }
        
        // Extract user info from credential
        let userId = credential.user
        let email = credential.email
        
        // Get name from credential if available
        let firstName = credential.fullName?.givenName ?? ""
        let lastName = credential.fullName?.familyName ?? ""
        let displayName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        let finalName = !displayName.isEmpty ? displayName : "SHSAT Student"
        
        // Check if user exists
        let predicate = #Predicate<UserProfile> { $0.appleUserId == userId }
        let descriptor = FetchDescriptor<UserProfile>(predicate: predicate)
        
        do {
            let existingUsers = try modelContext.fetch(descriptor)
            
            if let existingUser = existingUsers.first {
                // Update existing user
                updateExistingUser(existingUser, displayName: finalName, email: email)
                completion(.success(existingUser))
            } else {
                // Create new user
                let newUser = createNewUser(
                    appleUserId: userId,
                    displayName: finalName,
                    email: email
                )
                completion(.success(newUser))
            }
            
            // Save the Apple user ID to UserDefaults for persistent login
            UserDefaults.standard.set(userId, forKey: "appleUserId")
            
            // Sync with CloudKit would go here
            syncUserWithCloudKit(userId: userId)
            
        } catch {
            completion(.failure(.databaseError(error)))
        }
    }
    
    private func updateExistingUser(_ user: UserProfile, displayName: String, email: String?) {
        user.lastActive = Date()
        
        if !displayName.isEmpty {
            user.displayName = displayName
        }
        
        if let email = email, user.email == nil {
            user.email = email
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating user: \(error)")
        }
    }
    
    private func createNewUser(appleUserId: String, displayName: String, email: String?) -> UserProfile {
        let newUser = UserProfile(
            appleUserId: appleUserId,
            displayName: displayName,
            email: email
        )
        
        modelContext.insert(newUser)
        
        // Initialize topic progress for common topics
        initializeTopicProgress(for: newUser)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving new user: \(error)")
        }
        
        return newUser
    }
    
    private func initializeTopicProgress(for user: UserProfile) {
        // Standard SHSAT topics
        let topics = ["algebra", "geometry", "numbers", "probability", "general"]
        
        for topic in topics {
            let topicProgress = TopicProgress(topic: topic, user: user)
            modelContext.insert(topicProgress)
        }
    }
    
    // MARK: - User Authentication
    
    func checkExistingAuthentication() -> UserProfile? {
        if let userId = UserDefaults.standard.string(forKey: "appleUserId") {
            return getUserProfile(appleUserId: userId)
        }
        return nil
    }
    
    func getUserProfile(appleUserId: String) -> UserProfile? {
        let predicate = #Predicate<UserProfile> { $0.appleUserId == appleUserId }
        let descriptor = FetchDescriptor<UserProfile>(predicate: predicate)
        
        do {
            let existingUsers = try modelContext.fetch(descriptor)
            return existingUsers.first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }
    
    func getUserProfile(userId: UUID) -> UserProfile? {
        let predicate = #Predicate<UserProfile> { $0.id == userId }
        let descriptor = FetchDescriptor<UserProfile>(predicate: predicate)
        
        do {
            let existingUsers = try modelContext.fetch(descriptor)
            return existingUsers.first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
    }
    
    // MARK: - CloudKit Sync
    
    private func syncUserWithCloudKit(userId: String) {
        Task {
            guard let user = getUserProfile(appleUserId: userId) else { return }
            
            do {
                try await cloudKitService.syncUserProfile(user)
                print("User synced with CloudKit")
            } catch {
                print("Error syncing user with CloudKit: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Adapted from Apple's example for Sign in with Apple
    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Error Types

enum AuthError: Error {
    case invalidCredential
    case invalidState
    case authorizationFailed(Error)
    case databaseError(Error)
    case userNotFound
    case syncFailed(Error)
}

extension AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return NSLocalizedString("Invalid authentication credential", comment: "")
        case .invalidState:
            return NSLocalizedString("Invalid authentication state", comment: "")
        case .authorizationFailed(let error):
            return NSLocalizedString("Authorization failed: \(error.localizedDescription)", comment: "")
        case .databaseError(let error):
            return NSLocalizedString("Database error: \(error.localizedDescription)", comment: "")
        case .userNotFound:
            return NSLocalizedString("User profile not found", comment: "")
        case .syncFailed(let error):
            return NSLocalizedString("Failed to sync with iCloud: \(error.localizedDescription)", comment: "")
        }
    }
}
