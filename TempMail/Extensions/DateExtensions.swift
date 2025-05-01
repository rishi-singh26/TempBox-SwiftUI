//
//  DateExtensions.swift
//  TempBox
//
//  Created by Rishi Singh on 26/09/23.
//

import Foundation

extension Date {

    func formatRelativeString(useTwentyFourHour: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.doesRelativeDateFormatting = true

        if calendar.isDateInToday(self) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else if calendar.isDateInYesterday(self){
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
        } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
            let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
            return dateFormatter.weekdaySymbols[weekday-1]
        } else {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .short
        }

        // Set the time format to 24-hour
        dateFormatter.dateFormat = useTwentyFourHour ? "HH:mm a" : "HH:mm"

        return dateFormatter.string(from: self)
    }
}

