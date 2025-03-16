import SwiftUI
import SwiftData
import StoreKit

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingEditProfile = false
    @State private var showingSubscriptionInfo = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // User profile header
                profileHeader
                
                // Main content
                VStack(spacing: 20) {
                    // Account information
                    accountInfoSection
                    
                    // Performance stats
                    performanceStatsSection
                    
                    // App settings
                    settingsSection
                    
                    // Logout and account actions
                    accountActionsSection
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(
                displayName: viewModel.displayName,
                onSave: { newName in
                    Task {
                        await viewModel.updateUserProfile(displayName: newName)
                    }
                }
            )
        }
        .sheet(isPresented: $showingSubscriptionInfo) {
            SubscriptionView(isProUser: viewModel.isProUser) { isSubscribed in
                viewModel.toggleProSubscription(isEnabled: isSubscribed)
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount() {
                        authViewModel.signOut()
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .overlay {
            if viewModel.isSyncing {
                ProgressView("Syncing profile...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
    
    // User profile header
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Profile image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Display name
            Text(viewModel.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Member since
            Text("Member since \(viewModel.memberSinceString)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Pro badge
            if viewModel.isProUser {
                Label("Pro Member", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
        }
        .padding(.vertical)
    }
    
    // Account information section
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Account")
            
            VStack(spacing: 0) {
                InfoRow(label: "Name", value: viewModel.displayName)
                
                Divider()
                
                InfoRow(label: "Email", value: viewModel.email)
                
                Divider()
                
                InfoRow(label: "Member Since", value: viewModel.memberSinceString)
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // Performance stats section
    private var performanceStatsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Performance")
            
            VStack(spacing: 15) {
                HStack {
                    StatisticView(
                        title: "Questions",
                        value: "\(viewModel.totalQuestionsAnswered)",
                        icon: "list.number",
                        color: .blue
                    )
                    
                    StatisticView(
                        title: "Score",
                        value: "\(Int(viewModel.performancePercentage))%",
                        icon: "chart.bar.fill",
                        color: .green
                    )
                    
                    StatisticView(
                        title: "Streak",
                        value: "\(viewModel.streak)",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // Settings section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Settings")
            
            VStack(spacing: 0) {
                Toggle("Dark Mode", isOn: $viewModel.preferences.isDarkModeEnabled)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(viewModel.preferences.isSoundEnabled ? 0 : 10, corners: [.bottomLeft, .bottomRight])
                
                if viewModel.preferences.isDarkModeEnabled {
                    Divider()
                }
                
                Toggle("Sound Effects", isOn: $viewModel.preferences.isSoundEnabled)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(viewModel.preferences.isSoundEnabled ? 0 : 10, corners: [.bottomLeft, .bottomRight])
                
                if viewModel.preferences.isSoundEnabled {
                    Divider()
                }
                
                Toggle("Notifications", isOn: $viewModel.preferences.isNotificationsEnabled)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(viewModel.preferences.isNotificationsEnabled ? 0 : 10, corners: [.bottomLeft, .bottomRight])
                
                if viewModel.preferences.isNotificationsEnabled {
                    Divider()
                    
                    HStack {
                        Text("Daily Reminder")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $viewModel.preferences.dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                }
            }
            .onChange(of: viewModel.preferences) { _, _ in
                viewModel.saveUserPreferences()
            }
        }
    }
    
    // Account actions section
    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Account Actions")
            
            VStack(spacing: 0) {
                Button(action: {
                    showingEditProfile = true
                }) {
                    HStack {
                        Text("Edit Profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: {
                    showingSubscriptionInfo = true
                }) {
                    HStack {
                        Text(viewModel.isProUser ? "Manage Subscription" : "Upgrade to Pro")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: {
                    authViewModel.signOut()
                }) {
                    HStack {
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Text("Delete Account")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var initials: String {
        let components = viewModel.displayName.split(separator: " ")
        if components.isEmpty {
            return "?"
        } else if components.count == 1 {
            return String(components[0].prefix(1))
        } else {
            return "\(components[0].prefix(1))\(components[1].prefix(1))"
        }
    }
}

// Supporting Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.bottom, 5)
            .padding(.leading, 5)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
        .padding()
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    let onSave: (String) -> Void
    
    init(displayName: String, onSave: @escaping (String) -> Void) {
        self._displayName = State(initialValue: displayName)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Display Name", text: $displayName)
                }
                
                Section {
                    Button("Save Changes") {
                        onSave(displayName)
                        dismiss()
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    let isProUser: Bool
    let onSubscriptionChange: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header image
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .padding()
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple.opacity(0.7), .blue.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                        )
                    
                    // Title
                    Text(isProUser ? "You're a Pro Member!" : "Upgrade to Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Feature list
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Practice Tests",
                            description: "Access all practice tests with no limits"
                        )
                        
                        FeatureRow(
                            icon: "bell",
                            title: "Advanced Analytics",
                            description: "Deep insights into your performance"
                        )
                        
                        FeatureRow(
                            icon: "icloud",
                            title: "Cloud Sync",
                            description: "Sync your progress across all your devices"
                        )
                        
                        FeatureRow(
                            icon: "doc.text",
                            title: "Detailed Explanations",
                            description: "Get step-by-step explanations for all questions"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Price
                    if !isProUser {
                        VStack {
                            Text("$4.99 / month")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("or $49.99 / year (save 16%)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Action button
                    Button(action: {
                        // This would typically initiate an in-app purchase
                        // For now, we'll just toggle the value
                        onSubscriptionChange(!isProUser)
                        dismiss()
                    }) {
                        Text(isProUser ? "Manage Subscription" : "Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if !isProUser {
                        // Terms
                        Text("7-day free trial • Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(isProUser ? "Pro Membership" : "Upgrade to Pro")
            .navigationBarItems(
                trailing: Button("Close") {
                    dismiss()
                }
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationView {
        ProfileView(viewModel: ProfileViewModel(
            modelContext: ModelContainer.shared.mainContext,
            userId: UUID()
        ))
        .environmentObject(AuthViewModel(modelContext: ModelContainer.shared.mainContext))
    }
}
