//
//  scv_appleApp.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import SwiftUI
import SwiftData

@main
struct scv_appleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Card.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
