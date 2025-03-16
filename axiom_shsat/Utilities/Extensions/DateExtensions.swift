import Foundation

extension Date {
    /// Get the start of the day (midnight) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get the end of the day (23:59:59) for this date
    var endOfDay: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.date(from: components) ?? self
    }
    
    /// Get the start of the week for this date
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get the end of the week for this date
    var endOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let weekStart = calendar.date(from: components) ?? self
        return calendar.date(byAdding: .day, value: 7, to: weekStart)?.addingTimeInterval(-1) ?? self
    }
    
    /// Get the start of the month for this date
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get the end of the month for this date
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return calendar.date(byAdding: .second, value: -1, to: startOfNextMonth) ?? self
    }
    
    /// Get the start of the year for this date
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get the end of the year for this date
    var endOfYear: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year], from: self)
        components.year = components.year! + 1
        let startOfNextYear = calendar.date(from: components) ?? self
        return calendar.date(byAdding: .second, value: -1, to: startOfNextYear) ?? self
    }
    
    /// Get yesterday's date
    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self) ?? self
    }
    
    /// Get tomorrow's date
    var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self) ?? self
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Check if date is on a weekend
    var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return weekday == 1 || weekday == 7
    }
    
    /// Check if date is on a weekday
    var isWeekday: Bool {
        !isWeekend
    }
    
    /// Get the day of the week (Sunday = 1, Saturday = 7)
    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    /// Get the day number of the month
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// Get the weekday name (e.g., "Monday")
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Get the short weekday name (e.g., "Mon")
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// Get the month name (e.g., "January")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }
    
    /// Get the short month name (e.g., "Jan")
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }
    
    /// Get date formatted with the specified format
    func formatted(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// Get date as a relative string (e.g., "2 days ago")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Get date as a short relative string (e.g., "2d ago")
    var shortRelativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Return the date formatted for display in a header
    var headerFormatted: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) {
            return weekdayName
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }
    
    /// Add a specified number of days to the date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Add a specified number of weeks to the date
    func addingWeeks(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    /// Add a specified number of months to the date
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// Add a specified number of years to the date
    func addingYears(_ years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
    
    /// Calculate the difference in days between this date and another date
    func daysBetween(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
    
    /// Calculate the difference in weeks between this date and another date
    func weeksBetween(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: self, to: date)
        return components.weekOfYear ?? 0
    }
    
    /// Calculate the difference in months between this date and another date
    func monthsBetween(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self, to: date)
        return components.month ?? 0
    }
    
    /// Calculate the difference in years between this date and another date
    func yearsBetween(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self, to: date)
        return components.year ?? 0
    }
    
    /// Get the dates of the current week (Sunday to Saturday)
    var datesOfWeek: [Date] {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: self)
        let weekdayOrdinal = calendar.component(.weekdayOrdinal, from: self)
        let firstDate = calendar.date(byAdding: .day, value: -(dayOfWeek - 1), to: self) ?? self
        
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    /// Get the dates of the current month
    var datesOfMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self) ?? 1...30
        let firstDate = startOfMonth
        
        var dates: [Date] = []
        for i in range.lowerBound...range.upperBound {
            if let date = calendar.date(byAdding: .day, value: i - 1, to: firstDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    /// Default calendar for consistent usage
    private var calendar: Calendar {
        Calendar.current
    }
}

// Extension to Date for educational app specific utilities
extension Date {
    /// Format date for study sessions
    var studySessionFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date for test results
    var testResultFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: self)
    }
    
    /// Check if the date is within the current study week (Monday to Sunday)
    var isCurrentStudyWeek: Bool {
        let calendar = Calendar.current
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart) ?? Date()
        return self >= thisWeekStart && self < thisWeekEnd
    }
    
    /// Create a formatted study streak representation (e.g., "5-day streak")
    static func formatStreak(_ days: Int) -> String {
        switch days {
        case 0:
            return "No streak"
        case 1:
            return "1-day streak"
        default:
            return "\(days)-day streak"
        }
    }
    
    /// Get time remaining formatted as "MM:SS" for test timers
    static func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Get the date range formatted for a study period (e.g., "Jan 1 - Jan 7, 2023")
    static func formatDateRange(from startDate: Date, to endDate: Date) -> String {
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "MMM d"
        
        let endFormatter = DateFormatter()
        
        // If dates are in the same year
        if Calendar.current.component(.year, from: startDate) == Calendar.current.component(.year, from: endDate) {
            endFormatter.dateFormat = "MMM d, yyyy"
        } else {
            endFormatter.dateFormat = "MMM d, yyyy"
            startFormatter.dateFormat = "MMM d, yyyy"
        }
        
        return "\(startFormatter.string(from: startDate)) - \(endFormatter.string(from: endDate))"
    }
    
    /// Format a time period for study sessions (e.g., "45 minutes")
    static func formatStudyDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hour\(hours == 1 ? "" : "s") \(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s")"
        }
    }
}
