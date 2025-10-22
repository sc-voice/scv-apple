//
//  ContentView.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var cardManager = CardManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var persistedCards: [Card]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(persistedCards) { card in
                    NavigationLink {
                        Text(card.title())
                    } label: {
                        Text(card.title())
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
                        Label("add.card".localized, systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("select.card".localized)
        }
    }

    private func addCard() {
        withAnimation {
            let newCard = Card()
            cardManager.addCard(newCard)
            modelContext.insert(newCard)
        }
    }

    private func deleteCards(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let card = persistedCards[index]
                cardManager.removeCard(card)
                modelContext.delete(card)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
