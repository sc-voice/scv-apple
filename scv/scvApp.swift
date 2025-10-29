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
    let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "SC-Voice"

    return WindowGroup {
      ZStack {
        ContentView()
      }
      .navigationTitle(displayName)
      #if os(iOS)
      .overlay(alignment: .top) {
        TitleOverlay(displayName: displayName)
      }
      #endif
    }
    .modelContainer(sharedModelContainer)
  }
}

struct TitleOverlay: View {
  let displayName: String
  @State private var fontSize: Double = 17 // .title default size
  @State private var opacity: Double = 1.0
  @State private var isAnimating: Bool = false

  var body: some View {
    GeometryReader { geometry in
      Text(displayName)
        .font(.system(size: fontSize))
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .offset(y: 0)
        .zIndex(1000)
        .opacity(opacity)
        .onAppear {
          triggerAnimation()
          setupNotificationListener()
        }
    }
  }

  private func setupNotificationListener() {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name("onCardContextChange"),
      object: nil,
      queue: .main
    ) { _ in
      let timestamp = ISO8601DateFormatter().string(from: Date())
      print("[\(timestamp)] onCardContextChange isAnimating=\(isAnimating)")
      // Only trigger animation if one isn't already running
      if !isAnimating {
        isAnimating = true
        triggerAnimation()
      }
    }
  }

  private func triggerAnimation() {
    // Reset state
    fontSize = 17
    opacity = 1.0

    // Both animations run in parallel for 15 seconds
    withAnimation(.linear(duration: 15)) {
      fontSize = 8
      opacity = 0
    }

    // Mark animation as complete after 15 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
      isAnimating = false
    }
  }
}
