import SwiftUI
import Charts

struct PerformanceChartView: View {
    enum ChartType {
        case line
        case bar
        case pie
    }
    
    enum DataType {
        case accuracy
        case responseTime
        case questionCount
        case topicDistribution
    }
    
    let dataPoints: [DataPoint]
    let chartType: ChartType
    let dataType: DataType
    let title: String
    let subtitle: String?
    
    @State private var selectedDataPoint: DataPoint?
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let category: String
        let date: Date?
        
        init(label: String, value: Double, category: String = "", date: Date? = nil) {
            self.label = label
            self.value = value
            self.category = category
            self.date = date
        }
    }
    
    init(
        dataPoints: [DataPoint],
        chartType: ChartType = .line,
        dataType: DataType = .accuracy,
        title: String,
        subtitle: String? = nil
    ) {
        self.dataPoints = dataPoints
        self.chartType = chartType
        self.dataType = dataType
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Chart title and subtitle
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // The chart itself
            chartView
                .frame(height: 220)
            
            // Legend if needed
            if chartType == .pie || (chartType == .bar && dataType == .topicDistribution) {
                legendView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
    
    // Dynamic chart view based on type
    private var chartView: some View {
        Group {
            switch chartType {
            case .line:
                lineChart
            case .bar:
                barChart
            case .pie:
                pieChart
            }
        }
    }
    
    // Line chart implementation
    private var lineChart: some View {
        Chart {
            ForEach(dataPoints) { dataPoint in
                LineMark(
                    x: .value("Category", dataPoint.label),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(by: .value("Category", dataPoint.category.isEmpty ? "Default" : dataPoint.category))
                .symbol(by: .value("Category", dataPoint.category.isEmpty ? "Default" : dataPoint.category))
                .interpolationMethod(.catmullRom)
            }
            
            if dataType == .accuracy {
                RuleMark(y: .value("Target", 70))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing) {
                        Text("Target")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
            }
            
            if let selected = selectedDataPoint {
                PointMark(
                    x: .value("Category", selected.label),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(Color.primary)
                .symbolSize(CGSize(width: 10, height: 10))
            }
        }
        .chartYScale(domain: yScaleDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(dataPoints.count, 8))) { value in
                if let stringValue = value.as(String.self) {
                    AxisValueLabel {
                        Text(stringValue)
                            .font(.caption)
                    }
                } else if let dateValue = value.as(Date.self) {
                    AxisValueLabel {
                        Text(dateValue, format: .dateTime.month().day())
                            .font(.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formattedYAxisValue(doubleValue))
                            .font(.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                guard xPosition >= 0, xPosition <= geometry[proxy.plotAreaFrame].width else {
                                    selectedDataPoint = nil
                                    return
                                }
                                
                                let dataIndex = Int((xPosition / geometry[proxy.plotAreaFrame].width) * CGFloat(dataPoints.count))
                                if dataIndex >= 0 && dataIndex < dataPoints.count {
                                    selectedDataPoint = dataPoints[dataIndex]
                                }
                            }
                            .onEnded { _ in
                                selectedDataPoint = nil
                            }
                    )
            }
        }
    }
    
    // Bar chart implementation
    private var barChart: some View {
        Chart {
            ForEach(dataPoints) { dataPoint in
                BarMark(
                    x: .value("Category", dataPoint.label),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(by: .value("Category", dataPoint.category.isEmpty ? "Default" : dataPoint.category))
                .annotation(position: .top, alignment: .center) {
                    if dataPoints.count <= 8 {
                        Text(formattedValue(dataPoint.value))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if dataType == .accuracy {
                RuleMark(y: .value("Target", 70))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartYScale(domain: yScaleDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(dataPoints.count, 8))) { value in
                if let stringValue = value.as(String.self) {
                    AxisValueLabel {
                        Text(stringValue)
                            .font(.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formattedYAxisValue(doubleValue))
                            .font(.caption)
                    }
                }
                AxisGridLine()
            }
        }
    }
    
    // Pie chart implementation
    private var pieChart: some View {
        Chart(dataPoints) { dataPoint in
            SectorMark(
                angle: .value("Value", dataPoint.value),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("Category", dataPoint.label))
            .annotation(position: .overlay) {
                if dataPoint.value / totalValue > 0.05 {
                    Text(formattedValue(dataPoint.value))
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    // Legend view for pie and categorical bar charts
    private var legendView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(dataPoints) { dataPoint in
                HStack(spacing: 5) {
                    Circle()
                        .fill(categoryColor(for: dataPoint.label))
                        .frame(width: 10, height: 10)
                    
                    Text(dataPoint.label)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedValue(dataPoint.value))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // Helper methods and computed properties
    
    private var yScaleDomain: ClosedRange<Double> {
        switch dataType {
        case .accuracy:
            return 0...100
        case .responseTime:
            let maxValue = dataPoints.map { $0.value }.max() ?? 10
            return 0...(maxValue * 1.1)
        case .questionCount:
            let maxValue = dataPoints.map { $0.value }.max() ?? 10
            return 0...(maxValue * 1.1)
        case .topicDistribution:
            let maxValue = dataPoints.map { $0.value }.max() ?? 10
            return 0...(maxValue * 1.1)
        }
    }
    
    private var totalValue: Double {
        dataPoints.reduce(0) { $0 + $1.value }
    }
    
    private func formattedValue(_ value: Double) -> String {
        switch dataType {
        case .accuracy:
            return "\(Int(value))%"
        case .responseTime:
            return String(format: "%.1fs", value)
        case .questionCount:
            return "\(Int(value))"
        case .topicDistribution:
            let percentage = (value / totalValue) * 100
            return "\(Int(percentage))%"
        }
    }
    
    private func formattedYAxisValue(_ value: Double) -> String {
        switch dataType {
        case .accuracy:
            return "\(Int(value))%"
        case .responseTime:
            return "\(Int(value))s"
        case .questionCount, .topicDistribution:
            return "\(Int(value))"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        // This is a simple hash-based color generator
        // In a real app, you might want to use a predefined color palette
        let hash = abs(category.hashValue)
        let hue = Double(hash % 256) / 256.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
}

// Helper extensions and modifiers

struct PerformanceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
            )
    }
}

extension View {
    func performanceCardStyle() -> some View {
        self.modifier(PerformanceCardModifier())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Line chart example
            PerformanceChartView(
                dataPoints: [
                    .init(label: "Mon", value: 65, date: Date().addingTimeInterval(-7 * 86400)),
                    .init(label: "Tue", value: 68, date: Date().addingTimeInterval(-6 * 86400)),
                    .init(label: "Wed", value: 72, date: Date().addingTimeInterval(-5 * 86400)),
                    .init(label: "Thu", value: 70, date: Date().addingTimeInterval(-4 * 86400)),
                    .init(label: "Fri", value: 75, date: Date().addingTimeInterval(-3 * 86400)),
                    .init(label: "Sat", value: 78, date: Date().addingTimeInterval(-2 * 86400)),
                    .init(label: "Sun", value: 82, date: Date().addingTimeInterval(-1 * 86400))
                ],
                chartType: .line,
                dataType: .accuracy,
                title: "Weekly Performance",
                subtitle: "Your accuracy over the last 7 days"
            )
            
            // Bar chart example
            PerformanceChartView(
                dataPoints: [
                    .init(label: "Algebra", value: 75),
                    .init(label: "Geometry", value: 82),
                    .init(label: "Numbers", value: 65),
                    .init(label: "Probability", value: 90),
                    .init(label: "General", value: 70)
                ],
                chartType: .bar,
                dataType: .accuracy,
                title: "Topic Performance",
                subtitle: "Your accuracy by subject"
            )
            
            // Pie chart example
            PerformanceChartView(
                dataPoints: [
                    .init(label: "Algebra", value: 35),
                    .init(label: "Geometry", value: 25),
                    .init(label: "Numbers", value: 20),
                    .init(label: "Probability", value: 15),
                    .init(label: "General", value: 5)
                ],
                chartType: .pie,
                dataType: .topicDistribution,
                title: "Study Time Distribution",
                subtitle: "Where you spend your time"
            )
            
            // Response time bar chart
            PerformanceChartView(
                dataPoints: [
                    .init(label: "Q1", value: 12.5),
                    .init(label: "Q2", value: 8.2),
                    .init(label: "Q3", value: 15.7),
                    .init(label: "Q4", value: 6.3),
                    .init(label: "Q5", value: 9.1)
                ],
                chartType: .bar,
                dataType: .responseTime,
                title: "Response Times",
                subtitle: "Time spent on each question (seconds)"
            )
        }
        .padding()
    }
}
