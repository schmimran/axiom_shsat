//
//  DashboardView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData

struct DashboardView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // User stats summary
                statsCardsView
                
                // Daily challenge
                dailyChallengeCard
                
                // Recommended topics
                recommendedTopicsSection
                
                // Recent activity
                recentActivitySection
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
    
    // Stats Cards Grid
    private var statsCardsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatCard(
                title: "Streak",
                value: "\(viewModel.dailyStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Today",
                value: "\(viewModel.questionsAnsweredToday)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Overall",
                value: "\(Int(viewModel.overallPerformance))%",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }
    
    // Daily Challenge Card
    private var dailyChallengeCard: some View {
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
                        
                        Text(challenge.text.replacingOccurrences(of: "$", with: ""))
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
                HStack {
                    Text("Challenge loading...")
                    Spacer()
                    ProgressView()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Recommended Topics Section
    private var recommendedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended Practice")
                .font(.headline)
            
            if viewModel.recommendedTopics.isEmpty {
                Text("No recommendations yet. Start practicing!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                ForEach(viewModel.recommendedTopics) { topic in
                    RecommendationRow(topic: topic) {
                        // Start practice for this topic
                        Task {
                            _ = await viewModel.startPracticeSession(
                                for: topic.topic,
                                difficulty: nil,
                                questionCount: 10
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline)
            
            if viewModel.recentSessions.isEmpty {
                Text("No recent activity. Start practicing!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
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
            
            // View all button
            if !viewModel.recentSessions.isEmpty {
                NavigationLink(destination: ProgressView(userId: viewModel.userId)) {
                    Text("View all activity")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let modelContainer = try! ModelContainer(for: [
            UserProfile.self,
            Question.self,
            TestSession.self,
            QuestionResponse.self,
            TopicProgress.self
        ])
        
        let dummyUserID = UUID()
        
        return NavigationView {
            DashboardView(viewModel: HomeViewModel(
                modelContext: modelContainer.mainContext,
                userId: dummyUserID
            ))
            .navigationTitle("Dashboard")
        }
    }
}