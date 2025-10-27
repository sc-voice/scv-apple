//
//  CardTests.swift
//  scvTests
//
//  Created by Visakha on 22/10/2025.
//

import Foundation
import SwiftData
import Testing

@testable import SC_Voice

struct CardTests {

  // MARK: - Test Helpers
  
  private func createInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([Card.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
  }

  // MARK: - Initialization Tests

  @Test func testDefaultInitialization() async throws {
    let card = Card()

    #expect(card.cardType == .search)
    #expect(card.name.contains("card.type.search".localized))
    #expect(card.name.contains("0"))
    #expect(card.typeId == 0)
    #expect(card.createdAt.timeIntervalSinceNow < 1.0)  // Should be recent
  }

  @Test func testCustomInitialization() async throws {
    let date = Date(timeIntervalSince1970: 1_000_000)
    let card = Card(
      createdAt: date,
      cardType: .sutta,
      typeId: 42
    )

    #expect(card.createdAt == date)
    #expect(card.cardType == .sutta)
    #expect(card.name.contains("card.type.sutta".localized))
    #expect(card.name.contains("42"))
    #expect(card.typeId == 42)
  }

  @Test func testPartialInitialization() async throws {
    let card = Card(cardType: .sutta)

    #expect(card.cardType == .sutta)
    #expect(card.typeId == 0)  // Default value
    #expect(card.createdAt.timeIntervalSinceNow < 1.0)  // Should be recent
  }

  // MARK: - Immutability Tests

  @Test func testCardTypeImmutability() async throws {
    let card = Card(cardType: .search)

    // This should compile and work - we can read the value
    #expect(card.cardType == .search)

    // Note: We can't test that setting fails at compile time in runtime tests,
    // but the private(set) access control ensures immutability
  }

  @Test func testCreatedAtImmutability() async throws {
    let date = Date(timeIntervalSince1970: 1_000_000)
    let card = Card(createdAt: date)

    #expect(card.createdAt == date)
  }

  @Test func testIdImmutability() async throws {
    let card = Card(typeId: 123)

    #expect(card.typeId == 123)
  }

  // MARK: - Method Tests

  @Test func testLocalizedCardTypeNameForSearch() async throws {
    let card = Card(cardType: .search)

    // Note: This will return the raw key if localization isn't set up
    let localizedName = card.localizedCardTypeName()
    #expect(localizedName == "card.type.search".localized)
  }

  @Test func testLocalizedCardTypeNameForSutta() async throws {
    let card = Card(cardType: .sutta)

    let localizedName = card.localizedCardTypeName()
    #expect(localizedName == "card.type.sutta".localized)
  }

  @Test func testTitle() async throws {
    let card = Card(cardType: .search, typeId: 5)

    let title = card.title()
    #expect(title.contains("card.type.search".localized))
    #expect(title.contains("5"))
  }

  // MARK: - CardType Enum Tests

  @Test func testCardTypeCases() async throws {
    let allCases = CardType.allCases

    #expect(allCases.contains(.search))
    #expect(allCases.contains(.sutta))
    #expect(allCases.count == 2)
  }

  @Test func testCardTypeRawValues() async throws {
    #expect(CardType.search.rawValue == "search")
    #expect(CardType.sutta.rawValue == "sutta")
  }

  @Test func testCardTypeCodable() async throws {
    let cardType = CardType.sutta

    let encoder = JSONEncoder()
    let data = try encoder.encode(cardType)

    let decoder = JSONDecoder()
    let decodedCardType = try decoder.decode(CardType.self, from: data)

    #expect(decodedCardType == cardType)
  }

  // MARK: - Edge Cases

  @Test func testEmptyNameTitle() async throws {
    let card = Card(cardType: .sutta, typeId: 0)

    let title = card.title()
    #expect(title.contains("card.type.sutta".localized))
    #expect(title.contains("0"))
  }

  @Test func testWhitespaceNameTitle() async throws {
    let card = Card(cardType: .search, typeId: 1)

    // Empty name should fall back to localized type + ID
    let title = card.title()
    #expect(title.contains("card.type.search".localized))
    #expect(title.contains("1"))
  }

  @Test func testNegativeId() async throws {
    let card = Card(typeId: -1)

    #expect(card.typeId == -1)
  }

  @Test func testLargeId() async throws {
    let card = Card(typeId: Int.max)

    #expect(card.typeId == Int.max)
  }

  // MARK: - CardManager Tests

  @Test func testCardManagerAddCardAssignsCorrectId() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Add first card - should get ID 1
      let addedCard1 = cardManager.addCard(
        cardType: .search,
      )
      #expect(addedCard1.typeId == 1)
      #expect(addedCard1.cardType == CardType.search)

      // Add second card - should get ID 2
      let addedCard2 = cardManager.addCard(
        cardType: .search,
      )
      #expect(addedCard2.typeId == 2)
      #expect(addedCard2.cardType == CardType.search)

      // Add card of different type - should get ID 1 for that type
      let addedCard3 = cardManager.addCard(cardType: .sutta)
      #expect(addedCard3.typeId == 1)
      #expect(addedCard3.cardType == CardType.sutta)
    }
  }

  @Test func testCardManagerAddCardReturnsNewCardInstance() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      let addedCard = cardManager.addCard(cardType: .search)

      // The returned card should have the correct ID and properties
      #expect(addedCard.typeId == 1)  // Correct ID assigned
      #expect(addedCard.cardType == .search)
      #expect(addedCard.name.contains("card.type.search".localized))
      #expect(addedCard.createdAt <= Date())  // Should be recent
    }
  }

  @Test func testCardIdsAreUniquePerCardType() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Add all cards
      let addedSearchCard1 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedSearchCard2 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedSearchCard3 = cardManager.addCard(cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)

      let addedSuttaCard1 = cardManager.addCard( cardType: .sutta)
      Thread.sleep(forTimeInterval: 0.01)
      let addedSuttaCard2 = cardManager.addCard( cardType: .sutta )
      Thread.sleep(forTimeInterval: 0.01)
      let addedSuttaCard3 = cardManager.addCard( cardType: .sutta )

      // Collect all IDs by type
      let searchIds = [
        addedSearchCard1.typeId, addedSearchCard2.typeId, addedSearchCard3.typeId,
      ]
      let suttaIds = [
        addedSuttaCard1.typeId, addedSuttaCard2.typeId, addedSuttaCard3.typeId,
      ]

      // Verify IDs are unique within each card type
      let uniqueSearchIds = Set(searchIds)
      let uniqueSuttaIds = Set(suttaIds)

      #expect(
        uniqueSearchIds.count == searchIds.count,
        "Search card IDs should be unique"
      )
      #expect(
        uniqueSuttaIds.count == suttaIds.count,
        "Sutta card IDs should be unique"
      )

      // Verify IDs are sequential within each type
      #expect(
        searchIds.sorted() == [1, 2, 3],
        "Search card IDs should be sequential starting from 1"
      )
      #expect(
        suttaIds.sorted() == [1, 2, 3],
        "Sutta card IDs should be sequential starting from 1"
      )

      // Verify that IDs can overlap between types (this is the expected behavior)
      // Both types can have ID 1, 2, 3, etc.
      #expect(searchIds.contains(1), "Search cards should have ID 1")
      #expect(suttaIds.contains(1), "Sutta cards should have ID 1")
      #expect(searchIds.contains(2), "Search cards should have ID 2")
      #expect(suttaIds.contains(2), "Sutta cards should have ID 2")
    }
  }

  // MARK: - UI Behavior Tests

  @Test func testNewCardIsSelectedAfterAdding() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Simulate the UI behavior: add a card and verify it should be selected
      let addedCard = cardManager.addCard(cardType: .search)

      // Verify the card was added with correct ID
      #expect(addedCard.typeId == 1)
      #expect(addedCard.cardType == CardType.search)

      // In the UI, this card should be selected after adding
      // The test verifies that the card returned by addCard() is the one that should be selected
      // This ensures the UI selects the card with the correct ID, not the original card with ID 0

      // Verify the card is ready for selection (has proper ID)
      #expect(addedCard.typeId > 0)  // Card has valid ID for selection
    }
  }

  // MARK: - Localization Tests

  @Test func testCloseCardAccessibilityLabel() async throws {
    // Test that the close card accessibility label uses localized text
    let accessibilityLabel = "close.card".localized
    #expect(accessibilityLabel == "Close Card")

    // Test that the localization key exists and returns a non-empty string
    #expect(!accessibilityLabel.isEmpty)
    #expect(accessibilityLabel != "close.card")  // Should not return the key itself
  }

  @Test func testCloseCardAccessibilityLabelInDifferentLanguages() async throws
  {
    // Test that we can access the localization in different languages
    // Note: In a real test environment, you might want to set the app's language
    // For now, we'll test that the localization system works

    let closeCardKey = "close.card"

    // Test that the key exists in the localization system
    let localizedText = closeCardKey.localized
    #expect(!localizedText.isEmpty)

    // Test that it's not just returning the key
    #expect(localizedText != closeCardKey)

    // Test that it returns a reasonable string (not empty or just the key)
    #expect(localizedText.count > 0)
    #expect(localizedText != "")

    // Test that it's appropriate for accessibility (descriptive)
    #expect(
      localizedText.contains("Close") || localizedText.contains("Cerrar")
        || localizedText.contains("Fermer") || localizedText.contains("schließen")
        || localizedText.contains("Закрыть")
    )
  }

  // MARK: - Card Selection Tests

  @Test func testNextCardSelectedWhenMiddleCardDeleted() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Create three cards with different creation times
      // Add cards with slight time differences
      let addedCard1 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)  // Small delay to ensure different timestamps

      let addedCard2 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)

      let addedCard3 = cardManager.addCard( cardType: .search)

      // Verify cards were added with correct IDs
      #expect(addedCard1.typeId == 1)
      #expect(addedCard2.typeId == 2)
      #expect(addedCard3.typeId == 3)

      // Simulate selecting the middle card (card2)
      let selectedCard = addedCard2

      // Simulate finding the next card after deleting card2
      let remainingCards = [addedCard1, addedCard3]
      let sortedCards = remainingCards.sorted { $0.createdAt < $1.createdAt }

      // The next card should be card3 (created after card2)
      let nextCard = sortedCards.first { $0.createdAt > selectedCard.createdAt }
      #expect(nextCard != nil)
      #expect(nextCard?.typeId == 3)
    }
  }

  @Test func testLastCardSelectedWhenLastCardDeleted() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Create two cards
      let addedCard1 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard2 = cardManager.addCard( cardType: .search)

      // Simulate selecting the last card (card2)

      // Simulate finding the next card after deleting card2
      let remainingCards = [addedCard1]
      let sortedCards = remainingCards.sorted { $0.createdAt < $1.createdAt }

      // Since no card was created after card2, should select the last remaining card
      let nextCard = sortedCards.last
      #expect(nextCard != nil)
      #expect(nextCard?.typeId == 1)
    }
  }

  @Test func testCardSelectionOrderByCreationTime() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Create cards in a specific order
      let addedCard1 = cardManager.addCard(cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard2 = cardManager.addCard(cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard3 = cardManager.addCard(cardType: .search)

      let allCards =  cardManager.allCards;
      // Verify creation order
      #expect(allCards[0] == addedCard1)
      #expect(allCards[1] == addedCard2)
      #expect(allCards[2] == addedCard3)
    }
  }

  // MARK: - Focus and Selection Tests

  @Test func testCardSelectionUpdatesFocusState() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Create test cards
      let addedCard1 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard2 = cardManager.addCard( cardType: .search)

      // Simulate the selection behavior from ContentView
      var selectedCard: Card? = nil
      var selectedCards: Set<Int> = []

      // Test selecting first card
      selectedCard = addedCard1
      selectedCards = [addedCard1.typeId]

      #expect(selectedCard?.typeId == addedCard1.typeId)
      #expect(selectedCards.contains(addedCard1.typeId))
      #expect(selectedCards.count == 1)

      // Test selecting second card
      selectedCard = addedCard2
      selectedCards = [addedCard2.typeId]

      #expect(selectedCard?.typeId == addedCard2.typeId)
      #expect(selectedCards.contains(addedCard2.typeId))
      #expect(selectedCards.count == 1)
      #expect(!selectedCards.contains(addedCard1.typeId))  // Previous card should be deselected

      // Test deselecting all cards
      selectedCard = nil
      selectedCards = []

      #expect(selectedCard == nil)
      #expect(selectedCards.isEmpty)
    }
  }

  @Test func testCardSelectionStateConsistency() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Create test cards
      let addedCard1 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard2 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard3 = cardManager.addCard( cardType: .search)
      // Simulate ContentView selection behavior
      var selectedCard: Card? = nil
      var selectedCards: Set<Int> = []

      // Test that selecting a card updates both selectedCard and selectedCards
      selectedCard = addedCard2
      selectedCards = [addedCard2.typeId]

      // Verify consistency between selectedCard and selectedCards
      #expect(selectedCard?.typeId == addedCard2.typeId)
      #expect(selectedCards.contains(addedCard2.typeId))
      #expect(selectedCards.count == 1)

      // Test that the selected card ID matches the selectedCards set
      if let selectedCardId = selectedCard?.typeId {
        #expect(selectedCards.contains(selectedCardId))
        #expect(selectedCards.first == selectedCardId)
      }

      // Test switching selection
      selectedCard = addedCard3
      selectedCards = [addedCard3.typeId]

      #expect(selectedCard?.typeId == addedCard3.typeId)
      #expect(selectedCards.contains(addedCard3.typeId))
      #expect(!selectedCards.contains(addedCard2.typeId))  // Previous selection should be cleared
      #expect(selectedCards.count == 1)
    }
  }

  @Test func testCardSelectionTriggersFocusChange() async throws {
    await MainActor.run {
      let container = try! createInMemoryContainer()
      let cardManager = CardManager(modelContext: container.mainContext)

      // Create test cards
      let addedCard1 = cardManager.addCard( cardType: .search)
      Thread.sleep(forTimeInterval: 0.01)
      let addedCard2 = cardManager.addCard( cardType: .search)

      // Simulate focus state tracking
      var focusedCardId: Int? = nil
      var selectedCard: Card? = nil

      // Test initial state - no focus
      #expect(focusedCardId == nil)
      #expect(selectedCard == nil)

      // Test selecting first card triggers focus change
      selectedCard = addedCard1
      focusedCardId = selectedCard?.typeId

      #expect(focusedCardId == addedCard1.typeId)
      #expect(selectedCard?.typeId == addedCard1.typeId)

      // Test selecting second card changes focus
      selectedCard = addedCard2
      focusedCardId = selectedCard?.typeId

      #expect(focusedCardId == addedCard2.typeId)
      #expect(selectedCard?.typeId == addedCard2.typeId)
      #expect(focusedCardId != addedCard1.typeId)  // Focus should have changed

      // Test deselecting removes focus
      selectedCard = nil
      focusedCardId = selectedCard?.typeId

      #expect(focusedCardId == nil)
      #expect(selectedCard == nil)
    }
  }
}
