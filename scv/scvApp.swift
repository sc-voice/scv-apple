//
//  scv_appleApp.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import SwiftData
import SwiftUI

@main
struct scv_appleApp: App {
  var sharedModelContainer: ModelContainer = {
    do {
      let schema = Schema([Card.self])
      let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
      )
      return try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )
    } catch {
      print("SwiftData Error: \(error)")
      print("Error details: \(error.localizedDescription)")
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
