//
//  LearningGoal.swift
//  LearningJourney
//
//  Created by shahad on 01/06/1448 AH.
//

import Foundation
import SwiftData
enum LearningDuration: String, Codable {
    case week
    case month
    case year
}
@Model
final class LearningGoal {
    var title: String
    var duration: LearningDuration
    var startDate: Date
    var isCompleted: Bool = false
    init(title: String, duration: LearningDuration, startDate: Date) {
        self.title = title
        self.duration = duration
        self.startDate = startDate
    }
}
