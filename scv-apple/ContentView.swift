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
    @State private var selectedCards: Set<Card.ID> = []

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCards) {
                ForEach(persistedCards) { card in
                    HStack {
                        NavigationLink {
                            Text(cardTitle(for: card))
                        } label: {
                            Text(cardTitle(for: card))
                        }
                        
                        Spacer()
                        
                        if selectedCards.contains(card.id) {
                            Button(action: {
                                deleteCard(card)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
#if os(iOS)
                .onDelete(perform: deleteCards)
#endif
            }
            .focusable()
            .onKeyPress(.delete) {
                deleteSelectedCards()
                return .handled
            }
            .onKeyPress { keyPress in
                // Handle delete, backspace, and DEL keys
                if keyPress.key == .delete || 
                   keyPress.characters == "\u{7F}" || 
                   keyPress.characters == "" {
                    deleteSelectedCards()
                    return .handled
                }
                
                return .ignored
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
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
    
    private func deleteCard(_ card: Card) {
        withAnimation {
            modelContext.delete(card)
            
            // Remove from selection
            selectedCards.remove(card.id)
            
            // Save changes to persist to disk
            do {
                try modelContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    private func deleteSelectedCards() {
        guard !selectedCards.isEmpty else { 
            return 
        }
        
        withAnimation {
            for cardId in selectedCards {
                if let card = persistedCards.first(where: { $0.id == cardId }) {
                    modelContext.delete(card)
                }
            }
            
            // Clear selection after deletion
            selectedCards.removeAll()
            
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
