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
    @Query(sort: \Card.createdAt, order: .forward) private var persistedCards: [Card]
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(persistedCards) { card in
                    NavigationLink {
                        Text(cardTitle(for: card))
                    } label: {
                        Text(cardTitle(for: card))
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
        .onAppear {
            // Sync CardManager with SwiftData when view appears
            cardManager.syncWithSwiftData(persistedCards)
        }
        .onChange(of: persistedCards) { _, newCards in
            // Sync CardManager whenever SwiftData cards change
            cardManager.syncWithSwiftData(newCards)
        }
    }
    
    /// Returns the title for a card, respecting current locale
    private func cardTitle(for card: Card) -> String {
        if !card.name.isEmpty {
            return card.name
        } else {
            let localizedType = card.localizedCardTypeName()
            return "\(localizedType) \(card.id)"
        }
    }

    private func addCard() {
        withAnimation {
            let newCard = Card()
            cardManager.addCard(newCard)
            modelContext.insert(newCard)
            
            // Save changes to persist to disk
            do {
                try modelContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    private func deleteCards(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let card = persistedCards[index]
                modelContext.delete(card)
            }
            
            // Save changes to persist to disk
            do {
                try modelContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
