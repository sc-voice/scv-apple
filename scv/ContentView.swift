//
//  ContentView.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var cardManager: CardManager?
  @Environment(\.modelContext) private var modelContext
  @Environment(\.locale) private var locale
  @State private var selectedCards: Set<Card.ID> = []
  @State private var selectedCard: Card?
  @FocusState private var focusedCardId: Card.ID?

  private let selectedCardKey = "SelectedCardID"
  
  private var allCards: [Card] {
    cardManager?.allCards ?? []
  }

  var body: some View {
    NavigationSplitView {
      List(selection: $selectedCard) {
        ForEach(allCards) { card in
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
        switch selectedCard.cardType {
        case .search:
          SearchView(card: Binding(
            get: { selectedCard },
            set: { newValue in
              // Update the selected card
              self.selectedCard = newValue
            }
          ))
        case .sutta:
          SuttaView(card: Binding(
            get: { selectedCard },
            set: { newValue in
              // Update the selected card
              self.selectedCard = newValue
            }
          ))
        }
      } else {
        Text("select.card".localized)
      }
    }
    .onAppear {
      // Initialize CardManager with ModelContext
      if cardManager == nil {
        cardManager = CardManager(modelContext: modelContext)
      }
      restoreSelectedCard()
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
  }

  /// Returns the title for a card, respecting current locale
  private func cardTitle(for card: Card) -> String {
    if !card.name.isEmpty {
      return card.name
    } else {
      let localizedType = card.localizedCardTypeName()
      return "\(localizedType) \(card.typeId)"
    }
  }

  /// Save the selected card ID to UserDefaults
  private func saveSelectedCard(_ cardId: PersistentIdentifier?) {
    if let cardId = cardId {
      if let data = try? JSONEncoder().encode(cardId) {
        UserDefaults.standard.set(data, forKey: selectedCardKey)
      }
    } else {
      UserDefaults.standard.removeObject(forKey: selectedCardKey)
    }
  }

  /// Restore the selected card from UserDefaults
  private func restoreSelectedCard() {
    guard let data = UserDefaults.standard.data(forKey: selectedCardKey),
          let savedCardId = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) else { return }

    // Find the card with the saved ID
    if let card = allCards.first(where: { $0.id == savedCardId }) {
      selectedCard = card
      selectedCards = [card.id]
      focusedCardId = card.id  // Restore focus to the saved card
    }
  }

  private func addCard() {
    withAnimation {
      // Determine card type: alternating between search and sutta
      let cardType: CardType = allCards.count % 2 == 0 ? .search : .sutta
      let cardWithId = cardManager?.addCard(cardType: cardType)

      // Select the newly created card after it's saved
      if let cardWithId = cardWithId {
        selectedCard = cardWithId
        selectedCards = [cardWithId.id]
        focusedCardId = cardWithId.id  // Set focus to the new card
      }
    }
  }

  private func deleteCards(offsets: IndexSet) {
    withAnimation {
      cardManager?.removeCards(at: offsets)
    }
  }

  private func deleteCard(_ card: Card) {
    withAnimation {
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

      // Delete the card using CardManager
      cardManager?.removeCard(card)
    }
  }

  /// Finds the next card to select after deleting a card
  private func findNextCard(after deletedCard: Card) -> Card? {
    let remainingCards = allCards.filter { $0.id != deletedCard.id }

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
      let sortedCards = allCards.sorted { $0.createdAt < $1.createdAt }
      let currentIndex = sortedCards.firstIndex { $0.id == cardToDelete.id }

      // Delete the card using CardManager
      cardManager?.removeCard(cardToDelete)

      // Now select the next card from the updated list
      let updatedCards = allCards.sorted { $0.createdAt < $1.createdAt }

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
    }
  }

  private func deleteSelectedCards() {
    guard !selectedCards.isEmpty else {
      return
    }

    withAnimation {
      for cardId in selectedCards {
        if let card = allCards.first(where: { $0.id == cardId }) {
          cardManager?.removeCard(card)
        }
      }

      // Clear selection after deletion
      selectedCards.removeAll()
      selectedCard = nil
      focusedCardId = nil  // Clear focus after deletion
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Card.self, inMemory: true)
}
