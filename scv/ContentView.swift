//
//  ContentView.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var cardManager = CardManager.shared
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Card.createdAt, order: .forward) private var persistedCards:
    [Card]
  @Environment(\.locale) private var locale
  @State private var selectedCards: Set<Card.ID> = []
  @State private var selectedCard: Card?
  @FocusState private var focusedCardId: Card.ID?

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
              .accessibilityLabel("close.card".localized)
            }
          }
          .tag(card)
          .focused($focusedCardId, equals: card.id)
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
        if keyPress.key == .delete || keyPress.characters == "\u{7F}"
          || keyPress.characters == ""
        {
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
        focusedCardId = newSelectedCard.id  // Set focus to the selected card
        saveSelectedCard(newSelectedCard.id)
      } else {
        selectedCards = []
        focusedCardId = nil  // Clear focus when no card is selected
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
      focusedCardId = card.id  // Restore focus to the saved card
    }
  }

  private func addCard() {
    withAnimation {
      // Determine card type: alternating between search and sutta
      let cardType: CardType = persistedCards.count % 2 == 0 ? .search : .sutta
      let cardWithId = cardManager.addCard(cardType: cardType, name: "")
      modelContext.insert(cardWithId)

      // Save changes to persist to disk first
      do {
        try modelContext.save()

        // Select the newly created card after it's saved
        selectedCard = cardWithId
        selectedCards = [cardWithId.id]
        focusedCardId = cardWithId.id  // Set focus to the new card
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
        focusedCardId = nil

        // Try to select the next available card
        if let nextCard = findNextCard(after: card) {
          selectedCard = nextCard
          selectedCards = [nextCard.id]
          focusedCardId = nextCard.id  // Set focus to the next card
        }
      }

      // Save changes to persist to disk
      do {
        try modelContext.save()
      } catch {
        print("Failed to save context: \(error)")
      }
    }
  }

  /// Finds the next card to select after deleting a card
  private func findNextCard(after deletedCard: Card) -> Card? {
    let remainingCards = persistedCards.filter { $0.id != deletedCard.id }

    // If no cards remain, return nil
    guard !remainingCards.isEmpty else { return nil }

    // Sort cards by creation date to maintain order
    let sortedCards = remainingCards.sorted { $0.createdAt < $1.createdAt }

    // Find the card that was created after the deleted card
    if let nextIndex = sortedCards.firstIndex(where: {
      $0.createdAt > deletedCard.createdAt
    }) {
      return sortedCards[nextIndex]
    }

    // If no card was created after the deleted card, select the last card
    return sortedCards.last
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
          let nextIndex =
            currentIndex < updatedCards.count
            ? currentIndex : max(0, updatedCards.count - 1)
          if nextIndex >= 0, nextIndex < updatedCards.count {
            let nextCard = updatedCards[nextIndex]
            selectedCard = nextCard
            selectedCards = [nextCard.id]
            focusedCardId = nextCard.id  // Set focus to the next card
          } else {
            selectedCard = nil
            selectedCards = []
            focusedCardId = nil  // Clear focus when no cards remain
          }
        } else {
          selectedCard = nil
          selectedCards = []
          focusedCardId = nil  // Clear focus when no cards remain
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
      focusedCardId = nil  // Clear focus after deletion

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
