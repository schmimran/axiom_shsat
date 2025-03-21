import Foundation
import SwiftUI

/// Centralized error handling utility for the app
class ErrorHandler : ObservableObject {
    /// Shared instance for app-wide error handling
    static let shared = ErrorHandler()
    
    /// Published error observable for global error subscription
    @Published var currentError: AppError?
    
    private init() {}
    
    /// Handle an error with appropriate logging and user feedback
    func handle(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        // Convert to AppError if possible
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else {
            appError = .systemError(
                underlyingError: error,
                message: error.localizedDescription,
                file: file,
                line: line,
                function: function
            )
        }
        
        // Log the error
        logError(appError)
        
        // Set the current error for observers
        currentError = appError
        
        // In a production app, you might want to send the error to a logging service
        // or analytics platform
        #if DEBUG
        print("Error handled: \(appError.localizedDescription)")
        #endif
    }
    
    /// Clear the current error
    func clearError() {
        currentError = nil
    }
    
    /// Handle errors from throwing functions and transforms them into AppError
    func withErrorHandling<T>(_ operation: () throws -> T) -> Result<T, AppError> {
        do {
            let result = try operation()
            return .success(result)
        } catch let error as AppError {
            handle(error)
            return .failure(error)
        } catch {
            let appError = AppError.systemError(
                underlyingError: error,
                message: error.localizedDescription
            )
            handle(appError)
            return .failure(appError)
        }
    }
    
    /// Handle errors from async throwing functions
    func withAsyncErrorHandling<T>(_ operation: () async throws -> T) async -> Result<T, AppError> {
        do {
            let result = try await operation()
            return .success(result)
        } catch let error as AppError {
            handle(error)
            return .failure(error)
        } catch {
            let appError = AppError.systemError(
                underlyingError: error,
                message: error.localizedDescription
            )
            handle(appError)
            return .failure(appError)
        }
    }
    
    // MARK: - Private Methods
    
    private func logError(_ error: AppError) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        
        var logMessage = "[\(timestamp)] ERROR: \(error.localizedDescription)"
        
        if case let .systemError(underlyingError, _, file, line, function) = error {
            logMessage += "\nUnderlying Error: \(underlyingError)"
            logMessage += "\nLocation: \(file):\(line) - \(function)"
        }
        
        // Append to the error log file
        appendToErrorLog(logMessage)
    }
    
    private func appendToErrorLog(_ message: String) {
        // Get the path to the log file
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsDirectory.appendingPathComponent("app_errors.log")
        
        // Append the message to the log file
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            if let data = (message + "\n\n").data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            // Create the log file if it doesn't exist
            try? message.data(using: .utf8)?.write(to: logFileURL)
        }
    }
}

// MARK: - App Error Types

/// Structured error type for app-specific errors
enum AppError: Error, Equatable {
    /// Authentication errors
    case authentication(message: String)
    
    /// Network or connectivity errors
    case network(message: String)
    
    /// Data persistence errors
    case database(message: String)
    
    /// Validation errors
    case validation(message: String)
    
    /// Business logic errors
    case businessLogic(message: String)
    
    /// User input errors
    case userInput(message: String)
    
    /// File or resource errors
    case resource(message: String)
    
    /// Permission or authorization errors
    case permission(message: String)
    
    /// Unknown or system errors with the underlying error
    case systemError(
        underlyingError: Error,
        message: String = "An unexpected error occurred",
        file: String = #file,
        line: Int = #line,
        function: String = #function
    )
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.authentication(let lhsMsg), .authentication(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.network(let lhsMsg), .network(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.database(let lhsMsg), .database(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.validation(let lhsMsg), .validation(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.businessLogic(let lhsMsg), .businessLogic(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.userInput(let lhsMsg), .userInput(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.resource(let lhsMsg), .resource(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.permission(let lhsMsg), .permission(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.systemError(_, let lhsMsg, _, _, _), .systemError(_, let rhsMsg, _, _, _)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .authentication(let message):
            return NSLocalizedString("Authentication Error: \(message)", comment: "")
        case .network(let message):
            return NSLocalizedString("Network Error: \(message)", comment: "")
        case .database(let message):
            return NSLocalizedString("Database Error: \(message)", comment: "")
        case .validation(let message):
            return NSLocalizedString("Validation Error: \(message)", comment: "")
        case .businessLogic(let message):
            return NSLocalizedString("Application Error: \(message)", comment: "")
        case .userInput(let message):
            return NSLocalizedString("Input Error: \(message)", comment: "")
        case .resource(let message):
            return NSLocalizedString("Resource Error: \(message)", comment: "")
        case .permission(let message):
            return NSLocalizedString("Permission Error: \(message)", comment: "")
        case .systemError(_, let message, _, _, _):
            return NSLocalizedString(message, comment: "")
        }
    }
}

extension AppError: Identifiable {
    var id: String {
        switch self {
        case .authentication(let message):
            return "auth_\(message.hashValue)"
        case .network(let message):
            return "net_\(message.hashValue)"
        case .database(let message):
            return "db_\(message.hashValue)"
        case .validation(let message):
            return "val_\(message.hashValue)"
        case .businessLogic(let message):
            return "logic_\(message.hashValue)"
        case .userInput(let message):
            return "input_\(message.hashValue)"
        case .resource(let message):
            return "res_\(message.hashValue)"
        case .permission(let message):
            return "perm_\(message.hashValue)"
        case .systemError(let error, _, _, _, _):
            return "sys_\(error.localizedDescription.hashValue)"
        }
    }
}

// MARK: - SwiftUI Extensions for Error Handling

/// Environment value for the error handler
struct ErrorHandlerKey: EnvironmentKey {
    static let defaultValue = ErrorHandler.shared
}

extension EnvironmentValues {
    var errorHandler: ErrorHandler {
        get { self[ErrorHandlerKey.self] }
        set { self[ErrorHandlerKey.self] = newValue }
    }
}

/// View extension to handle errors
extension View {
    /// Apply global error handling to a view
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlingViewModifier())
    }
    
    /// Handle a specific error type with a custom action
    func onAppError<T: Error>(_ errorType: T.Type, perform action: @escaping (T) -> Void) -> some View {
        self.modifier(ErrorTypeHandlerModifier(errorType: errorType, action: action))
    }
}

/// View modifier to add error handling alert
struct ErrorHandlingViewModifier: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    @State private var showingError = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: errorHandler.currentError) { _, newError in
                showingError = newError != nil
            }
            .alert(
                "Error",
                isPresented: $showingError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

/// View modifier to handle specific error types
struct ErrorTypeHandlerModifier<T: Error>: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    let errorType: T.Type
    let action: (T) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: errorHandler.currentError) { _, newError in
                if let error = newError,
                   case let .systemError(underlyingError, _, _, _, _) = error,
                   let specificError = underlyingError as? T {
                    action(specificError)
                    errorHandler.clearError()
                }
            }
    }
}

// MARK: - Result Extensions

extension Result {
    /// Executes the given transformation if the result is a success
    func onSuccess(_ action: (Success) -> Void) -> Result<Success, Failure> {
        if case .success(let value) = self {
            action(value)
        }
        return self
    }
    
    /// Executes the given transformation if the result is a failure
    func onFailure(_ action: (Failure) -> Void) -> Result<Success, Failure> {
        if case .failure(let error) = self {
            action(error)
        }
        return self
    }
    
    /// Transforms the success value of the result into a new value
    func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Transforms the error value of the result into a new error
    func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> Result<Success, NewFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }
    
    /// Transforms the success value of the result into a new result
    func flatMap<NewSuccess>(_ transform: (Success) -> Result<NewSuccess, Failure>) -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Usage Examples

#if DEBUG
// Example function that demonstrates error handling
func exampleErrorHandling() {
    // Example 1: Simple error handling
    do {
        try throwingFunction()
    } catch {
        ErrorHandler.shared.handle(error)
    }
    
    // Example 2: Using withErrorHandling
    let result = ErrorHandler.shared.withErrorHandling {
        try throwingFunction()
    }
    
    // Example 3: Using result extensions
    result
        .onSuccess { value in
            print("Success: \(value)")
        }
        .onFailure { error in
            print("Failure: \(error.localizedDescription)")
        }
    
    // Example 4: Async error handling
    Task {
        let asyncResult = await ErrorHandler.shared.withAsyncErrorHandling {
            try await asyncThrowingFunction()
        }
        
        switch asyncResult {
        case .success(let value):
            print("Async Success: \(value)")
        case .failure(let error):
            print("Async Failure: \(error.localizedDescription)")
        }
    }
}

// Example throwing functions for demonstration
func throwingFunction() throws -> String {
    throw AppError.validation(message: "Example validation error")
}

func asyncThrowingFunction() async throws -> String {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    throw AppError.network(message: "Example network error")
}
#endif
