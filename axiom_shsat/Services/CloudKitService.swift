import Foundation
import CloudKit
import SwiftData

class CloudKitService {
    // CloudKit container identifier
    private let containerIdentifier = "iCloud.com.yourdomain.SHSATPrepper"
    
    // CloudKit private database - for user data
    private lazy var privateDatabase: CKDatabase = {
        let container = CKContainer(identifier: containerIdentifier)
        return container.privateCloudDatabase
    }()
    
    // CloudKit shared database - for shared question data
    private lazy var sharedDatabase: CKDatabase = {
        let container = CKContainer(identifier: containerIdentifier)
        return container.sharedCloudDatabase
    }()
    
    // CloudKit public database - for global app data
    private lazy var publicDatabase: CKDatabase = {
        let container = CKContainer(identifier: containerIdentifier)
        return container.publicCloudDatabase
    }()
    
    // MARK: - User Account Operations
    
    // Check iCloud account status
    func checkAccountStatus() async throws -> CKAccountStatus {
        let container = CKContainer(identifier: containerIdentifier)
        return try await container.accountStatus()
    }
    
    // Synchronize user profile with CloudKit
    func syncUserProfile(_ userProfile: UserProfile) async throws {
        let record = try userProfileToRecord(userProfile)
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            print("User profile synchronized with CloudKit: \(savedRecord.recordID)")
        } catch {
            print("Error syncing user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Test Session Operations
    
    // Save test session to CloudKit
    func saveTestSession(_ session: TestSession) async throws {
        let record = try testSessionToRecord(session)
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            print("Test session saved to CloudKit: \(savedRecord.recordID)")
            
            // Also save all associated question responses
            try await saveQuestionResponses(session.responses, for: session)
        } catch {
            print("Error saving test session: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Save question responses to CloudKit
    private func saveQuestionResponses(_ responses: [QuestionResponse], for session: TestSession) async throws {
        guard !responses.isEmpty else { return }
        
        let records = try responses.map { response in
            try questionResponseToRecord(response, sessionRecordID: CKRecord.ID(recordName: session.id.uuidString))
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            
            privateDatabase.add(operation)
        }
    }
    
    // MARK: - Data Synchronization
    
    // Fetch user data from CloudKit
    func fetchUserData(for userProfile: UserProfile) async throws {
        // Fetch test sessions for the user
        let predicate = NSPredicate(format: "userID == %@", userProfile.id.uuidString)
        let query = CKQuery(recordType: "TestSession", predicate: predicate)
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query)
            
            // Process the session records
            for (_, result) in results {
                switch result {
                case .success(let record):
                    // Create local session from record
                    let session = try recordToTestSession(record, userProfile: userProfile)
                    
                    // Fetch responses for this session
                    try await fetchSessionResponses(for: session)
                    
                case .failure(let error):
                    print("Error fetching record: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Fetch session responses from CloudKit
    private func fetchSessionResponses(for session: TestSession) async throws {
        let predicate = NSPredicate(format: "sessionID == %@", session.id.uuidString)
        let query = CKQuery(recordType: "QuestionResponse", predicate: predicate)
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query)
            
            // Process the response records
            for (_, result) in results {
                switch result {
                case .success(let record):
                    // Create local response from record
                    _ = try recordToQuestionResponse(record, session: session)
                    
                case .failure(let error):
                    print("Error fetching response record: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error fetching session responses: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Record Conversions
    
    // Convert UserProfile to CKRecord
    private func userProfileToRecord(_ userProfile: UserProfile) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: userProfile.id.uuidString)
        let record = CKRecord(recordType: "UserProfile", recordID: recordID)
        
        record["appleUserId"] = userProfile.appleUserId
        record["displayName"] = userProfile.displayName
        record["email"] = userProfile.email
        record["dateJoined"] = userProfile.dateJoined
        record["lastActive"] = userProfile.lastActive
        record["streak"] = userProfile.streak
        record["totalQuestionsAnswered"] = userProfile.totalQuestionsAnswered
        record["totalCorrectAnswers"] = userProfile.totalCorrectAnswers
        
        return record
    }
    
    // Convert TestSession to CKRecord
    private func testSessionToRecord(_ session: TestSession) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: session.id.uuidString)
        let record = CKRecord(recordType: "TestSession", recordID: recordID)
        
        record["startTime"] = session.startTime
        record["endTime"] = session.endTime
        record["totalQuestions"] = session.totalQuestions
        record["correctAnswers"] = session.correctAnswers
        record["completed"] = session.completed
        record["sessionType"] = session.sessionType
        record["topics"] = session.topics
        record["difficulty"] = session.difficulty
        record["duration"] = session.duration
        
        // Reference to the user
        if let userId = session.user?.id {
            let userReference = CKRecord.Reference(
                recordID: CKRecord.ID(recordName: userId.uuidString),
                action: .deleteSelf
            )
            record["userID"] = userId.uuidString
            record["userReference"] = userReference
        }
        
        return record
    }
    
    // Convert QuestionResponse to CKRecord
    private func questionResponseToRecord(_ response: QuestionResponse, sessionRecordID: CKRecord.ID) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: response.id.uuidString)
        let record = CKRecord(recordType: "QuestionResponse", recordID: recordID)
        
        record["selectedOption"] = response.selectedOption
        record["isCorrect"] = response.isCorrect
        record["timestamp"] = response.timestamp
        record["responseTime"] = response.responseTime
        
        // Reference to the session
        let sessionReference = CKRecord.Reference(recordID: sessionRecordID, action: .deleteSelf)
        record["sessionReference"] = sessionReference
        record["sessionID"] = sessionRecordID.recordName
        
        // Reference to the question
        if let questionId = response.question?.id {
            record["questionID"] = questionId.uuidString
        }
        
        return record
    }
    
    // Convert CKRecord to TestSession
    private func recordToTestSession(_ record: CKRecord, userProfile: UserProfile) throws -> TestSession {
        guard let startTime = record["startTime"] as? Date,
              let totalQuestions = record["totalQuestions"] as? Int,
              let sessionType = record["sessionType"] as? String else {
            throw CloudKitError.invalidRecord
        }
        
        let sessionID = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let endTime = record["endTime"] as? Date
        let correctAnswers = record["correctAnswers"] as? Int ?? 0
        let completed = record["completed"] as? Bool ?? false
        let topics = record["topics"] as? [String] ?? []
        let difficulty = record["difficulty"] as? String
        let duration = record["duration"] as? TimeInterval
        
        // Create session object
        let session = TestSession(
            id: sessionID,
            startTime: startTime,
            totalQuestions: totalQuestions,
            sessionType: sessionType,
            topics: topics,
            difficulty: difficulty,
            user: userProfile
        )
        
        session.endTime = endTime
        session.correctAnswers = correctAnswers
        session.completed = completed
        session.duration = duration
        
        return session
    }
    
    // Convert CKRecord to QuestionResponse
    private func recordToQuestionResponse(_ record: CKRecord, session: TestSession) throws -> QuestionResponse {
        guard let selectedOption = record["selectedOption"] as? String,
              let isCorrect = record["isCorrect"] as? Bool,
              let timestamp = record["timestamp"] as? Date,
              let responseTime = record["responseTime"] as? TimeInterval else {
            throw CloudKitError.invalidRecord
        }
        
        let responseID = UUID(uuidString: record.recordID.recordName) ?? UUID()
        
        // Get question ID if available
        let questionID = record["questionID"] as? String
        var question: Question?
        
        if let questionID = questionID, let questionUUID = UUID(uuidString: questionID) {
            // In real implementation, fetch question from SwiftData
            // This is a placeholder - would need ModelContext to actually fetch
            question = nil
        }
        
        // Create response object
        let response = QuestionResponse(
            id: responseID,
            selectedOption: selectedOption,
            isCorrect: isCorrect,
            responseTime: responseTime,
            question: question,
            session: session
        )
        
        response.timestamp = timestamp
        
        return response
    }
}

enum CloudKitError: Error {
    case accountNotAvailable
    case invalidRecord
    case recordNotFound
    case syncFailed
}

extension CloudKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return NSLocalizedString("iCloud account is not available or not signed in", comment: "")
        case .invalidRecord:
            return NSLocalizedString("Invalid record format", comment: "")
        case .recordNotFound:
            return NSLocalizedString("Record not found", comment: "")
        case .syncFailed:
            return NSLocalizedString("Data synchronization failed", comment: "")
        }
    }
}
