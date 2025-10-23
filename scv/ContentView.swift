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
    @State private var selectedCard: Card?
    
    private let selectedCardKey = "SelectedCardID"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCard) {
                ForEach(persistedCards) { card in
                    HStack {
                        Image(systemName: card.iconName())
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(cardTitle(for: card))
                        
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
                    .tag(card)
                }
#if os(iOS)
                .onDelete(perform: deleteCards)
#endif
            }
            .focusable()
            .onKeyPress(.delete) {
                deleteCurrentSelectedCard()
                return .handled
            }
            .onKeyPress { keyPress in
                // Handle delete, backspace, and DEL keys
                if keyPress.key == .delete || 
                   keyPress.characters == "\u{7F}" || 
                   keyPress.characters == "" {
                    deleteCurrentSelectedCard()
                    return .handled
                }
                return .ignored
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addCard) {
                        Label("add.card".localized, systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedCard = selectedCard {
                Text(cardTitle(for: selectedCard))
            } else {
                Text("select.card".localized)
            }
        }
        .onAppear {
            // Sync CardManager with SwiftData when view appears
            cardManager.syncWithSwiftData(persistedCards)
        }
        .onChange(of: persistedCards) { _, newCards in
            // Sync CardManager whenever SwiftData cards change
            cardManager.syncWithSwiftData(newCards)
        }
            .onChange(of: selectedCard) { _, newSelectedCard in
                // Sync selectedCards with selectedCard for "X" button display
                if let newSelectedCard = newSelectedCard {
                    selectedCards = [newSelectedCard.id]
                    saveSelectedCard(newSelectedCard.id)
                } else {
                    selectedCards = []
                    saveSelectedCard(nil)
                }
            }
            .onAppear {
                restoreSelectedCard()
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
    
    /// Save the selected card ID to UserDefaults
    private func saveSelectedCard(_ cardId: Int?) {
        if let cardId = cardId {
            UserDefaults.standard.set(cardId, forKey: selectedCardKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedCardKey)
        }
    }
    
    /// Restore the selected card from UserDefaults
    private func restoreSelectedCard() {
        let savedCardId = UserDefaults.standard.integer(forKey: selectedCardKey)
        guard savedCardId != 0 else { return }
        
        // Find the card with the saved ID
        if let card = persistedCards.first(where: { $0.id == savedCardId }) {
            selectedCard = card
            selectedCards = [card.id]
        }
    }

    private func addCard() {
        withAnimation {
            let newCard = Card()
            cardManager.addCard(newCard)
            modelContext.insert(newCard)
          
          // Save changes to persist to disk first
            do {
                try modelContext.save()
                
                // Select the newly created card after it's saved
                selectedCard = newCard
                selectedCards = [newCard.id]
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
            
            // Clear selectedCard if it's the one being deleted
            if selectedCard?.id == card.id {
                selectedCard = nil
            }
            
            // Save changes to persist to disk
            do {
                try modelContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    private func deleteCurrentSelectedCard() {
        guard let cardToDelete = selectedCard else { 
            return 
        }
        
        withAnimation {
            // Find the next card to select after deletion
            let sortedCards = persistedCards.sorted { $0.createdAt < $1.createdAt }
            let currentIndex = sortedCards.firstIndex { $0.id == cardToDelete.id }
            
            modelContext.delete(cardToDelete)
            
            // Save changes first to update the persisted cards
            do {
                try modelContext.save()
                
                // Now select the next card from the updated list
                let updatedCards = persistedCards.sorted { $0.createdAt < $1.createdAt }
                
                if let currentIndex = currentIndex, !updatedCards.isEmpty {
                    let nextIndex = currentIndex < updatedCards.count ? currentIndex : max(0, updatedCards.count - 1)
                    if nextIndex >= 0 && nextIndex < updatedCards.count {
                        let nextCard = updatedCards[nextIndex]
                        selectedCard = nextCard
                        selectedCards = [nextCard.id]
                    } else {
                        selectedCard = nil
                        selectedCards = []
                    }
                } else {
                    selectedCard = nil
                    selectedCards = []
                }
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
            selectedCard = nil
            
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
