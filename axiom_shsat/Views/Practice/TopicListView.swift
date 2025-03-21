import SwiftUI

struct TopicListView: View {
    @EnvironmentObject var environment: AppEnvironment
    
    let topics = ["algebra", "geometry", "numbers", "probability", "general"]
    
    var body: some View {
        List {
            ForEach(topics, id: \.self) { topic in
                NavigationLink(
                    destination: TestSessionView(
                        topic: topic,
                        difficulty: nil,
                        questionCount: 10,
                        environment: environment
                    )
                ) {
                    HStack {
                        Text(topic.capitalized)
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Topics")
    }
}

#Preview {
    let environment = AppEnvironment.shared
    return NavigationView {
        TopicListView()
            .environmentObject(environment)
    }
}