import Foundation
import SwiftData
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var dateJoined: Date = Date()
    @Published var totalQuestionsAnswered: Int = 0
    @Published var totalCorrectAnswers: Int = 0
    @Published var streak: Int = 0
    @Published var isSyncing: Bool = false
    @Published var syncError: String?
    @Published var isEditingProfile: Bool = false
    @Published var isProUser: Bool = false
    @Published var preferences: UserPreferences
    
    private let environment: AppEnvironment
    private var modelContext: ModelContext { environment.modelContext }
    private let userId: UUID
    private var cancellables = Set<AnyCancellable>()
    private var cloudKitService: CloudKitService { environment.cloudKitService }
    
    struct UserPreferences: Codable, Equatable {
        var isDarkModeEnabled: Bool
        var isSoundEnabled: Bool
        var isNotificationsEnabled: Bool
        var dailyReminderTime: Date
        var isHapticFeedbackEnabled: Bool
        
        init(
            isDarkModeEnabled: Bool = false,
            isSoundEnabled: Bool = true,
            isNotificationsEnabled: Bool = true,
            dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date(),
            isHapticFeedbackEnabled: Bool = true
        ) {
            self.isDarkModeEnabled = isDarkModeEnabled
            self.isSoundEnabled = isSoundEnabled
            self.isNotificationsEnabled = isNotificationsEnabled
            self.dailyReminderTime = dailyReminderTime
            self.isHapticFeedbackEnabled = isHapticFeedbackEnabled
        }
    }
    
    init(environment: AppEnvironment, userId: UUID) {
        self.environment = environment
        self.userId = userId
        self.preferences = UserPreferences()
        
        loadUserData()
        loadUserPreferences()
    }
    
    private func loadUserData() {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id == userId }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                updateFromUserProfile(user)
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    private func updateFromUserProfile(_ user: UserProfile) {
        displayName = user.displayName
        email = user.email ?? "No email provided"
        dateJoined = user.dateJoined
        totalQuestionsAnswered = user.totalQuestionsAnswered
        totalCorrectAnswers = user.totalCorrectAnswers
        streak = user.streak
        
        // Check if the user is a pro user (this could be stored in UserDefaults or in the UserProfile)
        isProUser = UserDefaults.standard.bool(forKey: "isProUser_\(userId.uuidString)")
    }
    
    private func loadUserPreferences() {
        if let savedPreferencesData = UserDefaults.standard.data(forKey: "userPreferences_\(userId.uuidString)"),
           let savedPreferences = try? JSONDecoder().decode(UserPreferences.self, from: savedPreferencesData) {
            preferences = savedPreferences
        }
    }
    
    func saveUserPreferences() {
        if let preferencesData = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(preferencesData, forKey: "userPreferences_\(userId.uuidString)")
        }
        
        // If notifications preference changed, update registration
        updateNotificationSettings()
    }
    
    private func updateNotificationSettings() {
        // This would typically call a notification service to register or unregister
        // based on preferences.isNotificationsEnabled
    }
    
    func updateUserProfile(displayName: String) async {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id == userId }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                user.displayName = displayName
                self.displayName = displayName
                
                try modelContext.save()
                
                // Sync changes to CloudKit
                await syncUserProfile(user)
            }
        } catch {
            print("Error updating user profile: \(error)")
        }
    }
    
    private func syncUserProfile(_ profile: UserProfile) async {
        isSyncing = true
        syncError = nil
        
        do {
            try await cloudKitService.syncUserProfile(profile)
            isSyncing = false
        } catch {
            syncError = "Failed to sync profile: \(error.localizedDescription)"
            isSyncing = false
        }
    }
    
    func toggleProSubscription(isEnabled: Bool) {
        // In a real app, this would involve in-app purchase processing
        // For now, we'll just simulate it
        isProUser = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isProUser_\(userId.uuidString)")
    }
    
    func deleteAccount() async -> Bool {
        // This would typically involve:
        // 1. Confirmation dialog (handled in the UI)
        // 2. Delete data from CloudKit
        // 3. Delete local data
        // 4. Sign out
        
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id == userId }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                // Delete the user's data
                modelContext.delete(user)
                try modelContext.save()
                
                // Clear user preferences
                UserDefaults.standard.removeObject(forKey: "userPreferences_\(userId.uuidString)")
                UserDefaults.standard.removeObject(forKey: "isProUser_\(userId.uuidString)")
                
                // In a real app, you would also delete the CloudKit data
                // This would be done through the CloudKitService
                
                return true
            }
            return false
        } catch {
            print("Error deleting account: \(error)")
            return false
        }
    }
    
    var performancePercentage: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(totalQuestionsAnswered) * 100
    }
    
    var memberSinceString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dateJoined)
    }
}
