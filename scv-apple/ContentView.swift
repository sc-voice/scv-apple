//
//  ContentView.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(cards) { card in
                    NavigationLink {
                        Text("Card at \(card.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(card.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteCards)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addCard) {
                        Label("Add Card", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a card")
        }
    }

    private func addCard() {
        withAnimation {
            let newCard = Card(timestamp: Date())
            modelContext.insert(newCard)
        }
    }

    private func deleteCards(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(cards[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
