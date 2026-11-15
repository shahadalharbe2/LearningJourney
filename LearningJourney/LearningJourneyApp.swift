//
//  LearningJourneyApp.swift
//  LearningJourney
//
//  Created by shahad on 30/05/1448 AH.
//

import SwiftUI
import SwiftData

@main
struct LearningJourneyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [LearningGoal.self, LearningDay.self])
    }
}
