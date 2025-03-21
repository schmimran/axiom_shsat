import Foundation
import SwiftData

// Use custom CSV parsing since TabularData is not available on all platforms
typealias CSVReadingOptions = Dictionary<String, Any>

class DataFrame {
    var rows: [CSVRow] = []
    
    init(csvData: Data, options: CSVReadingOptions) throws {
        guard let csvString = String(data: csvData, encoding: .utf8) else {
            throw QuestionError.invalidData
        }
        
        let lines = csvString.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return }
        
        let hasHeader = options["hasHeaderRow"] as? Bool ?? true
        let usesQuotes = options["usesQuoting"] as? Bool ?? true
        
        // Parse header
        var headers: [String] = []
        let startIndex = hasHeader ? 1 : 0
        
        if hasHeader {
            headers = parseCSVLine(lines[0], usesQuotes: usesQuotes)
        }
        
        // Parse data rows
        for i in startIndex..<lines.count {
            let line = lines[i]
            if line.isEmpty && options["ignoresEmptyLines"] as? Bool ?? true {
                continue
            }
            
            let values = parseCSVLine(line, usesQuotes: usesQuotes)
            let row = CSVRow(values: values, headers: headers)
            rows.append(row)
        }
    }
    
    private func parseCSVLine(_ line: String, usesQuotes: Bool) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" && usesQuotes {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        // Add the last value
        result.append(currentValue)
        
        return result
    }
}

class CSVRow {
    private var values: [String]
    private var headers: [String]
    
    init(values: [String], headers: [String]) {
        self.values = values
        self.headers = headers
    }
    
    subscript(_ column: String, type: String.Type) -> String? {
        guard let index = headers.firstIndex(of: column), index < values.count else {
            return nil
        }
        return values[index]
    }
}

class QuestionService {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Import questions from a CSV file in the bundle
    func importQuestionsFromBundle(fileName: String) async throws -> Int {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw QuestionError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        return try await importQuestionsFromCSV(data: data)
    }
    
    // Import questions from an external CSV file (Data)
    func importQuestionsFromCSV(data: Data) async throws -> Int {
        do {
            let options: CSVReadingOptions = ["hasHeaderRow": true, "ignoresEmptyLines": true, "usesQuoting": true]
            let dataFrame = try DataFrame(csvData: data, options: options)
            
            var importedCount = 0
            
            // Process each row of the DataFrame
            for row in dataFrame.rows {
                // Extract values from each column
                guard let questionText = row["Question", String.self],
                      let optionA = row["OptionA", String.self],
                      let optionB = row["OptionB", String.self],
                      let optionC = row["OptionC", String.self],
                      let optionD = row["OptionD", String.self],
                      let optionE = row["OptionE", String.self],
                      let correctOption = row["CorrectOption", String.self],
                      let topic = row["Topic", String.self],
                      let difficulty = row["Difficulty", String.self] else {
                    continue
                }
                
                // Check if question already exists
                let descriptor = FetchDescriptor<Question>(
                    predicate: #Predicate<Question> { $0.text == questionText }
                )
                
                let existingQuestions = try modelContext.fetch(descriptor)
                
                if existingQuestions.isEmpty {
                    // Create a new question
                    let question = Question(
                        text: questionText,
                        optionA: optionA,
                        optionB: optionB,
                        optionC: optionC,
                        optionD: optionD,
                        optionE: optionE,
                        correctOption: correctOption,
                        topic: topic.lowercased(),
                        difficulty: difficulty.lowercased()
                    )
                    
                    modelContext.insert(question)
                    importedCount += 1
                }
            }
            
            try modelContext.save()
            return importedCount
        } catch {
            throw QuestionError.importFailed(error)
        }
    }
    
    // Generate a practice set based on user's weak areas
    func generatePracticeSet(for user: UserProfile, count: Int = 10) async throws -> [Question] {
        // First, get the user's weak topics (below 70% proficiency)
        let weakTopics = user.topicProgress
            .filter { $0.proficiencyPercentage < 70 }
            .map { $0.topic }
        
        var questions: [Question] = []
        
        if !weakTopics.isEmpty {
            // Prioritize questions from weak topics
            var descriptor = FetchDescriptor<Question>(
                predicate: #Predicate<Question> { weakTopics.contains($0.topic) }
            )
            descriptor.sortBy = [SortDescriptor(\.lastAttempted, order: .forward)]
            descriptor.fetchLimit = count
            
            questions = try modelContext.fetch(descriptor)
        }
        
        // If we don't have enough questions from weak topics, add more questions
        if questions.count < count {
            var descriptor = FetchDescriptor<Question>()
            descriptor.sortBy = [SortDescriptor(\.lastAttempted, order: .forward)]
            descriptor.fetchLimit = count - questions.count
            
            let additionalQuestions = try modelContext.fetch(descriptor)
            questions.append(contentsOf: additionalQuestions)
        }
        
        return questions.shuffled()
    }
    
    // Get questions by topic and difficulty
    func getQuestions(topics: [String]? = nil, difficulty: String? = nil, limit: Int? = nil) async throws -> [Question] {
        var predicate: Predicate<Question>?
        
        if let topics = topics, let difficulty = difficulty {
            // Filter by both topic and difficulty
            predicate = #Predicate<Question> { 
                topics.contains($0.topic) && $0.difficulty == difficulty
            }
        } else if let topics = topics {
            // Filter by topic only
            predicate = #Predicate<Question> { topics.contains($0.topic) }
        } else if let difficulty = difficulty {
            // Filter by difficulty only
            predicate = #Predicate<Question> { $0.difficulty == difficulty }
        }
        
        var descriptor = FetchDescriptor<Question>()
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    // Create a new question
    func createQuestion(
        text: String,
        optionA: String,
        optionB: String,
        optionC: String,
        optionD: String,
        optionE: String,
        correctOption: String,
        topic: String,
        difficulty: String
    ) throws {
        let question = Question(
            text: text,
            optionA: optionA,
            optionB: optionB,
            optionC: optionC,
            optionD: optionD,
            optionE: optionE,
            correctOption: correctOption,
            topic: topic.lowercased(),
            difficulty: difficulty.lowercased()
        )
        
        modelContext.insert(question)
        try modelContext.save()
    }
}

enum QuestionError: Error {
    case fileNotFound
    case importFailed(Error)
    case invalidData
}

extension QuestionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return NSLocalizedString("Question file not found", comment: "")
        case .importFailed(let error):
            return NSLocalizedString("Failed to import questions: \(error.localizedDescription)", comment: "")
        case .invalidData:
            return NSLocalizedString("Invalid question data", comment: "")
        }
    }
}
