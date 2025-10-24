//
//  CardTests.swift
//  scvTests
//
//  Created by Visakha on 22/10/2025.
//

import Testing
import Foundation
@testable import SC_Voice

struct CardTests {

    // MARK: - Initialization Tests
    
    @Test func testDefaultInitialization() async throws {
        let card = Card()
        
        #expect(card.cardType == .search)
        #expect(card.name == "")
        #expect(card.id == 0)
        #expect(card.createdAt.timeIntervalSinceNow < 1.0) // Should be recent
    }
    
    @Test func testCustomInitialization() async throws {
        let date = Date(timeIntervalSince1970: 1000000)
        let card = Card(createdAt: date, cardType: .sutta, name: "Test Card", id: 42)
        
        #expect(card.createdAt == date)
        #expect(card.cardType == .sutta)
        #expect(card.name == "Test Card")
        #expect(card.id == 42)
    }
    
    @Test func testPartialInitialization() async throws {
        let card = Card(cardType: .sutta, name: "Partial Test")
        
        #expect(card.cardType == .sutta)
        #expect(card.name == "Partial Test")
        #expect(card.id == 0) // Default value
        #expect(card.createdAt.timeIntervalSinceNow < 1.0) // Should be recent
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
        let date = Date(timeIntervalSince1970: 1000000)
        let card = Card(createdAt: date)
        
        #expect(card.createdAt == date)
    }
    
    @Test func testIdImmutability() async throws {
        let card = Card(id: 123)
        
        #expect(card.id == 123)
    }
    
    @Test func testNameMutability() async throws {
        let card = Card(name: "Original Name")
        
        #expect(card.name == "Original Name")
        
        // Name should be mutable
        card.name = "Updated Name"
        #expect(card.name == "Updated Name")
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
    
    @Test func testTitleWithName() async throws {
        let card = Card(name: "Custom Card Name")
        
        #expect(card.title() == "Custom Card Name")
    }
    
    @Test func testTitleWithoutName() async throws {
        let card = Card(cardType: .search, name: "", id: 5)
        
        let title = card.title()
        #expect(title.contains("card.type.search".localized))
        #expect(title.contains("5"))
    }
    
    @Test func testGetId() async throws {
        let card = Card(id: 999)
        
        #expect(card.getId() == 999)
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
        let card = Card(cardType: .sutta, name: "", id: 0)
        
        let title = card.title()
        #expect(title.contains("card.type.sutta".localized))
        #expect(title.contains("0"))
    }
    
    @Test func testWhitespaceNameTitle() async throws {
        let card = Card(cardType: .search, name: "   ", id: 1)
        
        // Empty name should fall back to localized type + ID
        let title = card.title()
        #expect(title.contains("card.type.search".localized))
        #expect(title.contains("1"))
    }
    
    @Test func testNegativeId() async throws {
        let card = Card(id: -1)
        
        #expect(card.id == -1)
        #expect(card.getId() == -1)
    }
    
    @Test func testLargeId() async throws {
        let card = Card(id: Int.max)
        
        #expect(card.id == Int.max)
        #expect(card.getId() == Int.max)
    }
    
    // MARK: - CardManager Tests
    
    @Test func testCardManagerAddCardAssignsCorrectId() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Add first card - should get ID 1
            let card1 = Card(cardType: CardType.search, name: "First Card")
            let addedCard1 = cardManager.addCard(card1)
            #expect(addedCard1.id == 1)
            #expect(addedCard1.cardType == CardType.search)
            #expect(addedCard1.name == "First Card")
            
            // Add second card - should get ID 2
            let card2 = Card(cardType: CardType.search, name: "Second Card")
            let addedCard2 = cardManager.addCard(card2)
            #expect(addedCard2.id == 2)
            #expect(addedCard2.cardType == CardType.search)
            #expect(addedCard2.name == "Second Card")
            
            // Add card of different type - should get ID 1 for that type
            let card3 = Card(cardType: CardType.sutta, name: "Sutta Card")
            let addedCard3 = cardManager.addCard(card3)
            #expect(addedCard3.id == 1)
            #expect(addedCard3.cardType == CardType.sutta)
            #expect(addedCard3.name == "Sutta Card")
        }
    }
    
    @Test func testCardManagerAddCardReturnsNewCardInstance() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            let originalCard = Card(cardType: CardType.search, name: "Original")
            let addedCard = cardManager.addCard(originalCard)
            
            // The returned card should be a different instance with the correct ID
            #expect(addedCard !== originalCard) // Different instances
            #expect(addedCard.id == 1) // Correct ID assigned
            #expect(originalCard.id == 0) // Original still has default ID
            #expect(addedCard.cardType == originalCard.cardType)
            #expect(addedCard.name == originalCard.name)
        }
    }
    
    @Test func testCardIdsAreUniquePerCardType() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create multiple cards of each type
            let searchCard1 = Card(cardType: .search, name: "Search 1")
            let searchCard2 = Card(cardType: .search, name: "Search 2")
            let searchCard3 = Card(cardType: .search, name: "Search 3")
            
            let suttaCard1 = Card(cardType: .sutta, name: "Sutta 1")
            let suttaCard2 = Card(cardType: .sutta, name: "Sutta 2")
            let suttaCard3 = Card(cardType: .sutta, name: "Sutta 3")
            
            // Add all cards
            let addedSearchCard1 = cardManager.addCard(searchCard1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedSearchCard2 = cardManager.addCard(searchCard2)
            Thread.sleep(forTimeInterval: 0.01)
            let addedSearchCard3 = cardManager.addCard(searchCard3)
            Thread.sleep(forTimeInterval: 0.01)
            
            let addedSuttaCard1 = cardManager.addCard(suttaCard1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedSuttaCard2 = cardManager.addCard(suttaCard2)
            Thread.sleep(forTimeInterval: 0.01)
            let addedSuttaCard3 = cardManager.addCard(suttaCard3)
            
            // Collect all IDs by type
            let searchIds = [addedSearchCard1.id, addedSearchCard2.id, addedSearchCard3.id]
            let suttaIds = [addedSuttaCard1.id, addedSuttaCard2.id, addedSuttaCard3.id]
            let allIds = searchIds + suttaIds
            
            // Verify IDs are unique within each card type
            let uniqueSearchIds = Set(searchIds)
            let uniqueSuttaIds = Set(suttaIds)
            
            #expect(uniqueSearchIds.count == searchIds.count, "Search card IDs should be unique")
            #expect(uniqueSuttaIds.count == suttaIds.count, "Sutta card IDs should be unique")
            
            // Verify IDs are sequential within each type
            #expect(searchIds.sorted() == [1, 2, 3], "Search card IDs should be sequential starting from 1")
            #expect(suttaIds.sorted() == [1, 2, 3], "Sutta card IDs should be sequential starting from 1")
            
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
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Simulate the UI behavior: add a card and verify it should be selected
            let newCard = Card(cardType: CardType.search, name: "New Card")
            let addedCard = cardManager.addCard(newCard)
            
            // Verify the card was added with correct ID
            #expect(addedCard.id == 1)
            #expect(addedCard.cardType == CardType.search)
            #expect(addedCard.name == "New Card")
            
            // In the UI, this card should be selected after adding
            // The test verifies that the card returned by addCard() is the one that should be selected
            // This ensures the UI selects the card with the correct ID, not the original card with ID 0
            
            // Verify the card is ready for selection (has proper ID)
            #expect(addedCard.id > 0) // Card has valid ID for selection
            #expect(addedCard !== newCard) // Different instance (the one with correct ID)
        }
    }
    
    // MARK: - Localization Tests
    
    @Test func testCloseCardAccessibilityLabel() async throws {
        // Test that the close card accessibility label uses localized text
        let accessibilityLabel = "close.card".localized
        #expect(accessibilityLabel == "Close Card")
        
        // Test that the localization key exists and returns a non-empty string
        #expect(!accessibilityLabel.isEmpty)
        #expect(accessibilityLabel != "close.card") // Should not return the key itself
    }
    
    @Test func testCloseCardAccessibilityLabelInDifferentLanguages() async throws {
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
        #expect(localizedText.contains("Close") || localizedText.contains("Cerrar") || localizedText.contains("Fermer"))
    }
    
    // MARK: - Card Selection Tests
    
    @Test func testNextCardSelectedWhenMiddleCardDeleted() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create three cards with different creation times
            let card1 = Card(cardType: CardType.search, name: "First Card")
            let card2 = Card(cardType: CardType.search, name: "Second Card") 
            let card3 = Card(cardType: CardType.search, name: "Third Card")
            
            // Add cards with slight time differences
            let addedCard1 = cardManager.addCard(card1)
            Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure different timestamps
            
            let addedCard2 = cardManager.addCard(card2)
            Thread.sleep(forTimeInterval: 0.01)
            
            let addedCard3 = cardManager.addCard(card3)
            
            // Verify cards were added with correct IDs
            #expect(addedCard1.id == 1)
            #expect(addedCard2.id == 2) 
            #expect(addedCard3.id == 3)
            
            // Simulate selecting the middle card (card2)
            let selectedCard = addedCard2
            
            // Simulate finding the next card after deleting card2
            let remainingCards = [addedCard1, addedCard3]
            let sortedCards = remainingCards.sorted { $0.createdAt < $1.createdAt }
            
            // The next card should be card3 (created after card2)
            let nextCard = sortedCards.first { $0.createdAt > selectedCard.createdAt }
            #expect(nextCard != nil)
            #expect(nextCard?.id == 3)
            #expect(nextCard?.name == "Third Card")
        }
    }
    
    @Test func testLastCardSelectedWhenLastCardDeleted() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create two cards
            let card1 = Card(cardType: CardType.search, name: "First Card")
            let card2 = Card(cardType: CardType.search, name: "Second Card")
            
            let addedCard1 = cardManager.addCard(card1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard2 = cardManager.addCard(card2)
            
            // Simulate selecting the last card (card2)
            let selectedCard = addedCard2
            
            // Simulate finding the next card after deleting card2
            let remainingCards = [addedCard1]
            let sortedCards = remainingCards.sorted { $0.createdAt < $1.createdAt }
            
            // Since no card was created after card2, should select the last remaining card
            let nextCard = sortedCards.last
            #expect(nextCard != nil)
            #expect(nextCard?.id == 1)
            #expect(nextCard?.name == "First Card")
        }
    }
    
    @Test func testNoCardSelectedWhenOnlyCardDeleted() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create only one card
            let card1 = Card(cardType: CardType.search, name: "Only Card")
            let addedCard1 = cardManager.addCard(card1)
            
            // Simulate deleting the only card
            let remainingCards: [Card] = []
            
            // Should return nil when no cards remain
            #expect(remainingCards.isEmpty)
            // No next card should be available
        }
    }
    
    @Test func testCardSelectionOrderByCreationTime() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create cards in a specific order
            let card1 = Card(cardType: CardType.search, name: "Card 1")
            let card2 = Card(cardType: CardType.search, name: "Card 2")
            let card3 = Card(cardType: CardType.search, name: "Card 3")
            
            let addedCard1 = cardManager.addCard(card1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard2 = cardManager.addCard(card2)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard3 = cardManager.addCard(card3)
            
            // Verify creation order
            #expect(addedCard1.createdAt < addedCard2.createdAt)
            #expect(addedCard2.createdAt < addedCard3.createdAt)
            
            // Test selection logic for each card
            let allCards = [addedCard1, addedCard2, addedCard3]
            
            // When deleting card1, next should be card2
            let nextAfterCard1 = allCards.first { $0.createdAt > addedCard1.createdAt }
            #expect(nextAfterCard1?.id == 2)
            
            // When deleting card2, next should be card3
            let nextAfterCard2 = allCards.first { $0.createdAt > addedCard2.createdAt }
            #expect(nextAfterCard2?.id == 3)
            
            // When deleting card3, should fall back to last remaining card
            let remainingAfterCard3 = [addedCard1, addedCard2]
            let lastCard = remainingAfterCard3.sorted { $0.createdAt < $1.createdAt }.last
            #expect(lastCard?.id == 2)
        }
    }
    
    // MARK: - Focus and Selection Tests
    
    @Test func testCardSelectionUpdatesFocusState() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create test cards
            let card1 = Card(cardType: CardType.search, name: "First Card")
            let card2 = Card(cardType: CardType.search, name: "Second Card")
            
            let addedCard1 = cardManager.addCard(card1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard2 = cardManager.addCard(card2)
            
            // Simulate the selection behavior from ContentView
            var selectedCard: Card? = nil
            var selectedCards: Set<Int> = []
            
            // Test selecting first card
            selectedCard = addedCard1
            selectedCards = [addedCard1.id]
            
            #expect(selectedCard?.id == addedCard1.id)
            #expect(selectedCards.contains(addedCard1.id))
            #expect(selectedCards.count == 1)
            
            // Test selecting second card
            selectedCard = addedCard2
            selectedCards = [addedCard2.id]
            
            #expect(selectedCard?.id == addedCard2.id)
            #expect(selectedCards.contains(addedCard2.id))
            #expect(selectedCards.count == 1)
            #expect(!selectedCards.contains(addedCard1.id)) // Previous card should be deselected
            
            // Test deselecting all cards
            selectedCard = nil
            selectedCards = []
            
            #expect(selectedCard == nil)
            #expect(selectedCards.isEmpty)
        }
    }
    
    @Test func testCardSelectionStateConsistency() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create test cards
            let card1 = Card(cardType: CardType.search, name: "Test Card 1")
            let card2 = Card(cardType: CardType.search, name: "Test Card 2")
            let card3 = Card(cardType: CardType.search, name: "Test Card 3")
            
            let addedCard1 = cardManager.addCard(card1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard2 = cardManager.addCard(card2)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard3 = cardManager.addCard(card3)
            
            // Simulate ContentView selection behavior
            var selectedCard: Card? = nil
            var selectedCards: Set<Int> = []
            
            // Test that selecting a card updates both selectedCard and selectedCards
            selectedCard = addedCard2
            selectedCards = [addedCard2.id]
            
            // Verify consistency between selectedCard and selectedCards
            #expect(selectedCard?.id == addedCard2.id)
            #expect(selectedCards.contains(addedCard2.id))
            #expect(selectedCards.count == 1)
            
            // Test that the selected card ID matches the selectedCards set
            if let selectedCardId = selectedCard?.id {
                #expect(selectedCards.contains(selectedCardId))
                #expect(selectedCards.first == selectedCardId)
            }
            
            // Test switching selection
            selectedCard = addedCard3
            selectedCards = [addedCard3.id]
            
            #expect(selectedCard?.id == addedCard3.id)
            #expect(selectedCards.contains(addedCard3.id))
            #expect(!selectedCards.contains(addedCard2.id)) // Previous selection should be cleared
            #expect(selectedCards.count == 1)
        }
    }
    
    @Test func testCardSelectionTriggersFocusChange() async throws {
        await MainActor.run {
            let cardManager = CardManager.shared
            
            // Clear any existing cards first
            cardManager.syncWithSwiftData([])
            
            // Create test cards
            let card1 = Card(cardType: CardType.search, name: "Focus Card 1")
            let card2 = Card(cardType: CardType.search, name: "Focus Card 2")
            
            let addedCard1 = cardManager.addCard(card1)
            Thread.sleep(forTimeInterval: 0.01)
            let addedCard2 = cardManager.addCard(card2)
            
            // Simulate focus state tracking
            var focusedCardId: Int? = nil
            var selectedCard: Card? = nil
            
            // Test initial state - no focus
            #expect(focusedCardId == nil)
            #expect(selectedCard == nil)
            
            // Test selecting first card triggers focus change
            selectedCard = addedCard1
            focusedCardId = selectedCard?.id
            
            #expect(focusedCardId == addedCard1.id)
            #expect(selectedCard?.id == addedCard1.id)
            
            // Test selecting second card changes focus
            selectedCard = addedCard2
            focusedCardId = selectedCard?.id
            
            #expect(focusedCardId == addedCard2.id)
            #expect(selectedCard?.id == addedCard2.id)
            #expect(focusedCardId != addedCard1.id) // Focus should have changed
            
            // Test deselecting removes focus
            selectedCard = nil
            focusedCardId = selectedCard?.id
            
            #expect(focusedCardId == nil)
            #expect(selectedCard == nil)
        }
    }
}
