//
//  AppDelegate.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import UIKit
import CloudKit
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure global appearance
        configureAppearance()
        
        // Register for remote notifications
        registerForRemoteNotifications()
        
        // Setup CloudKit subscription for changes
        setupCloudKitSubscriptions()
        
        // Other initialization
        setupLogging()
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    // MARK: - Push Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // You could send this token to your server if needed
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Check if this is a CloudKit notification
        if let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            handleCloudKitNotification(cloudKitNotification)
            completionHandler(.newData)
            return
        }
        
        // Handle other notification types
        handlePushNotification(userInfo)
        completionHandler(.newData)
    }
    
    // MARK: - Private Methods
    
    private func configureAppearance() {
        // Configure global appearance settings
        UINavigationBar.appearance().tintColor = .systemBlue
        UITableView.appearance().backgroundColor = .systemGroupedBackground
    }
    
    private func registerForRemoteNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else {
                print("Notification authorization denied: \(String(describing: error))")
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    private func setupCloudKitSubscriptions() {
        // Setup CloudKit subscriptions to receive notifications about data changes
        Task {
            do {
                try await setupTestSessionSubscription()
            } catch {
                print("Failed to set up CloudKit subscriptions: \(error)")
            }
        }
    }
    
    private func setupTestSessionSubscription() async throws {
        let container = CKContainer(identifier: "iCloud.com.yourdomain.SHSATPrepper")
        let database = container.privateCloudDatabase
        
        // Create a subscription for test session changes
        let predicate = NSPredicate(value: true) // Subscribe to all test sessions
        let subscription = CKQuerySubscription(
            recordType: "TestSession",
            predicate: predicate,
            subscriptionID: "test-sessions-subscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        // Configure the notification
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Your test session data has been updated"
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription
        _ = try await database.save(subscription)
    }
    
    private func handleCloudKitNotification(_ notification: CKNotification) {
        // Post notification to refresh data
        NotificationCenter.default.post(name: Notification.Name("CloudKitDataChanged"), object: nil)
        
        // Handle specific notification types
        if let queryNotification = notification as? CKQueryNotification {
            print("CloudKit record changed: \(queryNotification.recordID)")
        }
    }
    
    private func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle regular push notifications
        if let aps = userInfo["aps"] as? [String: Any] {
            print("Received push notification: \(aps)")
        }
    }
    
    private func setupLogging() {
        // Configure any logging frameworks or custom logging here
        #if DEBUG
        print("App started in DEBUG mode")
        #else
        print("App started in RELEASE mode")
        #endif
    }
}

// MARK: - Scene Delegate
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state
        // Reset badge count
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background
        // Save any changes if needed
    }
}