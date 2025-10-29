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
  @FocusState private var focusedCardId: Card.ID?

  private let selectedCardKey = "SelectedCardID"

  private var selectedCard: Card? {
    cardManager?.selectedCard
  }
  
  private var allCards: [Card] {
    cardManager?.allCards ?? []
  }

  var body: some View {
    NavigationSplitView {
      List {
        ForEach(allCards) { card in
          HStack {
            Image(systemName: card.iconName())
              .foregroundColor(.blue)
              .frame(width: 20)
              .accessibilityIdentifier("icon_\(card.cardType.rawValue)_\(card.typeId)")

            Text(cardTitle(for: card))
              .accessibilityIdentifier("card_\(card.cardType.rawValue)_\(card.typeId)")

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
          .contentShape(Rectangle())
          .onTapGesture {
            cardManager?.selectCard(card)
            selectedCards = [card.id]
            focusedCardId = card.id
          }
          .focused($focusedCardId, equals: card.id)
          .background(
            selectedCard?.id == card.id
              ? Color.blue.opacity(0.2)
              : Color.clear
          )
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
            Image(systemName: "plus")
              .accessibilityHidden(true)
          }
          .accessibilityIdentifier("addCardButton")
          .accessibilityLabel("add.card".localized)
        }
      }
      .toolbarBackground(Color(red: 0.239, green: 0.204, blue: 0.188), for: .automatic)
      .toolbarBackground(.visible, for: .automatic)
      .foregroundColor(.white)
      #if os(macOS)
      .navigationSplitViewColumnWidth(min: 180, ideal: 200)
      #endif
    } detail: {
      if let selectedCard = selectedCard {
        switch selectedCard.cardType {
        case .search:
          SearchView(card: selectedCard)
        case .sutta:
          SuttaView(card: selectedCard)
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
      cardManager?.selectCard(card)
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
        cardManager?.selectCard(cardWithId)
        selectedCards = [cardWithId.id]
        focusedCardId = cardWithId.id  // Set focus to the new card
      }
    }

    // Post notification to trigger title animation
    NotificationCenter.default.post(name: NSNotification.Name("onCardContextChange"), object: nil)
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

      // Delete the card using CardManager
      // CardManager will handle updating selection if the deleted card was selected
      cardManager?.removeCard(card)

      // Update selectedCards to reflect the new selection from CardManager
      if let selectedCard = selectedCard {
        selectedCards = [selectedCard.id]
        focusedCardId = selectedCard.id
      }
    }
  }

  private func deleteCurrentSelectedCard() {
    guard let cardToDelete = selectedCard else {
      return
    }

    withAnimation {
      // Delete the card using CardManager
      // CardManager will handle updating selection
      cardManager?.removeCard(cardToDelete)

      // Update selectedCards to reflect the new selection from CardManager
      if let selectedCard = selectedCard {
        selectedCards = [selectedCard.id]
        focusedCardId = selectedCard.id
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

      // Clear selection after deletion, but CardManager ensures a card is always selected
      selectedCards.removeAll()
      // Update selectedCards to reflect the new selection from CardManager
      if let selectedCard = selectedCard {
        selectedCards = [selectedCard.id]
        focusedCardId = selectedCard.id
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Card.self, inMemory: true)
}
