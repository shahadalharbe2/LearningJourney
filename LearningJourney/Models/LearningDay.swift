//
//  LearningDay.swift
//  LearningJourney
//
//  Created by shahad on 02/06/1448 AH.
//

import Foundation
import SwiftData

enum LearningDayType: String, Codable {
    case learned
    case frozen
}
@Model
final class LearningDay {
    var date: Date
    var type: LearningDayType
    var goal: LearningGoal?

    init(date: Date, type: LearningDayType, goal: LearningGoal? = nil) {
        self.date = date
        self.type = type
        self.goal = goal
    }
}
