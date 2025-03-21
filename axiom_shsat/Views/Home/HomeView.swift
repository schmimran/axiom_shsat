//
//  HomeView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedTab = 0
    @State private var showingTestConfig = false
    
    init(userId: UUID, environment: AppEnvironment = .shared) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(environment: environment, userId: userId))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            dashboardTab
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            practiceTab
                .tabItem {
                    Label("Practice", systemImage: "book.fill")
                }
                .tag(1)
            
            analyticsTab
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            profileTab
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .sheet(isPresented: $showingTestConfig) {
            TestConfigView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadDashboard()
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
    }
    
    // Dashboard Tab
    private var dashboardTab: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // User stats summary
                    statsView
                    
                    // Daily challenge
                    dailyChallengeView
                    
                    // Recommended topics
                    recommendedTopicsView
                    
                    // Recent activity
                    recentActivityView
                }
                .padding()
            }
            .navigationTitle("Hello, \(authViewModel.currentUser?.displayName ?? "Student")")
            .navigationBarItems(
                trailing: Button(action: {
                    authViewModel.signOut()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.gray)
                }
            )
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
    
    private var statsView: some View {
        HStack(spacing: 15) {
            UIComponents.StatCard(
                title: "Daily Streak",
                value: "\(viewModel.dailyStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            UIComponents.StatCard(
                title: "Today's Questions",
                value: "\(viewModel.questionsAnsweredToday)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            UIComponents.StatCard(
                title: "Overall Score",
                value: "\(Int(viewModel.overallPerformance))%",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }
    
    private var dailyChallengeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Challenge")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            if let challenge = viewModel.dailyChallenge {
                NavigationLink(destination: QuestionView(question: challenge)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topic: \(challenge.topic.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(challenge.text)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Text("Tap to solve")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            } else {
                Text("Challenge loading...")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
    
    private var recommendedTopicsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended Practice")
                .font(.headline)
            
            if viewModel.recommendedTopics.isEmpty {
                Text("No recommendations yet. Start practicing!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recommendedTopics) { topic in
                    NavigationLink(
                        destination: TestSessionView(
                            topic: topic.topic,
                            difficulty: nil,
                            questionCount: 10,
                            environment: environment
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(topic.topic.capitalized)
                                    .font(.headline)
                                
                                Text("Proficiency: \(Int(topic.proficiencyPercentage))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Practice")
                                .font(.caption)
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
    
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline)
            
            if viewModel.recentSessions.isEmpty {
                Text("No recent activity. Start practicing!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentSessions.prefix(3)) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.sessionType)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if let endTime = session.endTime {
                                Text(endTime, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text("\(session.correctAnswers)/\(session.totalQuestions)")
                                .font(.callout)
                                .foregroundColor(.primary)
                            
                            Text("\(Int(session.accuracyPercentage))%")
                                .font(.callout)
                                .foregroundColor(session.accuracyPercentage >= 70 ? .green : .orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
    
    // Practice Tab
    private var practiceTab: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Practice Options")) {
                        NavigationLink(destination: TopicListView()) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                                Text("Practice by Topic")
                            }
                        }
                        
                        Button(action: {
                            showingTestConfig = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.grid.2x2")
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.green)
                                Text("Custom Practice Test")
                            }
                        }
                        
                        NavigationLink(destination: TestSessionView(topic: nil, difficulty: "medium", questionCount: 25, environment: environment)) {
                            HStack {
                                Image(systemName: "timer")
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.orange)
                                Text("Full Length Test")
                            }
                        }
                    }
                    
                    Section(header: Text("Quick Practice")) {
                        NavigationLink(destination: TestSessionView(topic: nil, difficulty: "easy", questionCount: 5, environment: environment)) {
                            HStack {
                                Image(systemName: "1.circle")
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                Text("5 Easy Questions")
                            }
                        }
                        
                        NavigationLink(destination: TestSessionView(topic: nil, difficulty: "medium", questionCount: 10, environment: environment)) {
                            HStack {
                                Image(systemName: "2.circle")
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                Text("10 Medium Questions")
                            }
                        }
                        
                        NavigationLink(destination: TestSessionView(topic: nil, difficulty: "hard", questionCount: 5, environment: environment)) {
                            HStack {
                                Image(systemName: "3.circle")
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                Text("5 Hard Questions")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Practice")
        }
    }
    
    // Analytics Tab
    private var analyticsTab: some View {
        NavigationView {
            Text("Analytics View - Coming Soon")
                .navigationTitle("Your Progress")
        }
    }
    
    // Profile Tab
    private var profileTab: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Account")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(authViewModel.currentUser?.displayName ?? "Student")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(authViewModel.currentUser?.email ?? "Not provided")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Member Since")
                            Spacer()
                            if let dateJoined = authViewModel.currentUser?.dateJoined {
                                Text(dateJoined, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Settings")) {
                        Toggle("Dark Mode", isOn: .constant(false))
                        Toggle("Sound Effects", isOn: .constant(true))
                        Toggle("Notifications", isOn: .constant(true))
                    }
                    
                    Section {
                        Button("Sign Out") {
                            authViewModel.signOut()
                        }
                        .foregroundColor(.red)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Profile")
        }
    }
}

// Moved to SharedComponents.swift as UIComponents.StatCard

struct TestConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var selectedTopic: String?
    @State private var selectedDifficulty = "medium"
    @State private var questionCount = 10
    
    let topics = ["algebra", "geometry", "numbers", "probability", "general"]
    let difficulties = ["easy", "medium", "hard"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test Configuration")) {
                    Picker("Topic", selection: $selectedTopic) {
                        Text("All Topics").tag(String?.none)
                        ForEach(topics, id: \.self) { topic in
                            Text(topic.capitalized).tag(String?(topic))
                        }
                    }
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(difficulties, id: \.self) { difficulty in
                            Text(difficulty.capitalized).tag(difficulty)
                        }
                    }
                    
                    Stepper("Number of Questions: \(questionCount)", value: $questionCount, in: 5...50, step: 5)
                }
                
                Section {
                    Button("Start Practice") {
                        presentationMode.wrappedValue.dismiss()
                        
                        Task {
                            _ = await viewModel.startPracticeSession(
                                for: selectedTopic,
                                difficulty: selectedDifficulty,
                                questionCount: questionCount
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Configure Test")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    let environment = AppEnvironment.shared
    let authViewModel = AuthViewModel(environment: environment)
    let dummyUserID = UUID()
    
    HomeView(userId: dummyUserID, environment: environment)
        .environmentObject(authViewModel)
}
