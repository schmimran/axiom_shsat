//
//  TestConfigurationView.swift
//  axiom_shsat
//
//  Created by Imran Ahmed on 3/16/25.
//


import SwiftUI
import SwiftData

struct TestConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var selectedTopics: Set<String> = []
    @State private var selectedDifficulty: String = "medium"
    @State private var questionCount: Int = 10
    @State private var useCustomizedTest: Bool = false
    @State private var isStarting: Bool = false
    @State private var errorMessage: String?
    
    // Test configuration options
    let allTopics = ["algebra", "geometry", "numbers", "probability", "general"]
    let difficulties = ["easy", "medium", "hard", "mixed"]
    let questionCountOptions = [5, 10, 15, 20, 25, 30]
    
    var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            Form {
                // Test type selection
                Section(header: Text("Test Type")) {
                    Toggle("Customized Test", isOn: $useCustomizedTest)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if !useCustomizedTest {
                        Picker("Test Format", selection: $selectedDifficulty) {
                            Text("Quick Practice (10 Easy)").tag("easy")
                            Text("Standard Practice (15 Medium)").tag("medium")
                            Text("Challenge Practice (10 Hard)").tag("hard")
                            Text("Full SHSAT Simulation (30 Mixed)").tag("mixed")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // Custom configuration
                if useCustomizedTest {
                    // Topic selection
                    Section(header: Text("Topics")) {
                        ForEach(allTopics, id: \.self) { topic in
                            Button(action: {
                                toggleTopic(topic)
                            }) {
                                HStack {
                                    Text(topic.capitalized)
                                    Spacer()
                                    if selectedTopics.contains(topic) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.primary)
                        }
                    }
                    
                    // Difficulty selection
                    Section(header: Text("Difficulty")) {
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(difficulties, id: \.self) { difficulty in
                                Text(difficulty.capitalized).tag(difficulty)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Question count selection
                    Section(header: Text("Number of Questions")) {
                        Picker("Questions", selection: $questionCount) {
                            ForEach(questionCountOptions, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                // Start button
                Section {
                    Button(action: startTest) {
                        if isStarting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Start Test")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isStarting || (useCustomizedTest && selectedTopics.isEmpty))
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Configure Test")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .onAppear {
                // Select "algebra" by default if no topics are selected
                if selectedTopics.isEmpty {
                    selectedTopics.insert("algebra")
                }
            }
        }
    }
    
    private func toggleTopic(_ topic: String) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
    }
    
    private func startTest() {
        isStarting = true
        errorMessage = nil
        
        Task {
            // Determine test parameters based on selection
            var topics: [String]? = nil
            var difficulty: String? = nil
            var count = questionCount
            
            if useCustomizedTest {
                // Use custom configuration
                if !selectedTopics.isEmpty {
                    topics = Array(selectedTopics)
                }
                difficulty = selectedDifficulty == "mixed" ? nil : selectedDifficulty
            } else {
                // Use preset configuration
                switch selectedDifficulty {
                case "easy":
                    difficulty = "easy"
                    count = 10
                case "medium":
                    difficulty = "medium"
                    count = 15
                case "hard":
                    difficulty = "hard"
                    count = 10
                case "mixed":
                    difficulty = nil
                    count = 30
                default:
                    difficulty = "medium"
                    count = 10
                }
            }
            
            // Start the session
            if let session = await viewModel.startPracticeSession(
                for: topics?.first,
                difficulty: difficulty,
                questionCount: count
            ) {
                // Navigate to test session view
                // This would typically be handled in the parent view
                dismiss()
            } else {
                errorMessage = "Failed to start test session. Please try again."
                isStarting = false
            }
        }
    }
}

#Preview {
    let environment = AppEnvironment.shared
    
    let viewModel = HomeViewModel(
        environment: environment,
        userId: UUID()
    )
    
    TestConfigurationView(viewModel: viewModel)
        .environmentObject(AuthViewModel(environment: environment))
        .modelContainer(environment.modelContainer)
}
