//
//  DateExtensions.swift
//  TempBox
//
//  Created by Rishi Singh on 26/09/23.
//

import Foundation

extension Date {
    func formatRelativeString() -> String {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let isToday = calendar.isDate(self, inSameDayAs: today)
        let isYesterday = calendar.isDate(self, inSameDayAs: yesterday)

        var formattedDate = ""
        if isToday {
            // No date prefix
        } else if isYesterday {
            formattedDate = "Yesterday, "
        } else {
            let day = calendar.component(.day, from: self)
            let month = calendar.component(.month, from: self)
            let year = calendar.component(.year, from: self)
            let currentYear = calendar.component(.year, from: today)

            let suffix: String
            if (11...13).contains(day % 100) {
                suffix = "th"
            } else {
                switch day % 10 {
                case 1: suffix = "st"
                case 2: suffix = "nd"
                case 3: suffix = "rd"
                default: suffix = "th"
                }
            }

            let monthStr = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month - 1]

            if year == currentYear {
                formattedDate = "\(day)\(suffix) \(monthStr), "
            } else {
                formattedDate = "\(day)\(suffix) \(monthStr) \(year), "
            }
        }

        // Determine if system uses 24-hour format
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("j") // "j" is time format symbol

        let is24Hour = !formatter.dateFormat.contains("a") // "a" means AM/PM

        // Format time
        formatter.dateFormat = is24Hour ? "HH:mm" : "h:mm a"
        let timeStr = formatter.string(from: self)

        return "\(formattedDate)\(timeStr)"
    }

    func dd_mmm_yyyy() -> String {
        return self.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.abbreviated)
                .year()
        )
    }
}

