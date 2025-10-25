//
//  Card.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import Foundation
import SwiftData

// MARK: - CardType Enum

enum CardType: String, CaseIterable, Codable {
  case search = "search"
  case sutta = "sutta"
}

// MARK: - Card Model

@Model
final class Card {
  // MARK: - Properties

  private(set) var createdAt: Date
  private(set) var cardType: CardType
  var name: String {
    return "\(localizedCardTypeName()) \(typeId)"
  }
  private(set) var typeId: Int
  
  // Search card properties
  var searchQuery: String = ""
  var searchResults: Data?
  
  // Sutta card properties
  var suttaReference: String = ""

  // MARK: - Initialization

  init(
    createdAt: Date = Date(),
    cardType: CardType = .search,
    typeId: Int = 0,
    searchQuery: String = "",
    searchResults: Data? = nil,
    suttaReference: String = ""
  ) {
    self.createdAt = createdAt
    self.cardType = cardType
    self.typeId = typeId
    self.searchQuery = searchQuery
    self.searchResults = searchResults
    self.suttaReference = suttaReference
  }

  // MARK: - Public Methods

  /// Returns the appropriate SF Symbol icon name for the card type
  func iconName() -> String {
    switch cardType {
    case .search:
      return "magnifyingglass"
    case .sutta:
      return "book"
    }
  }

  /// Returns the localized name for the card type
  func localizedCardTypeName() -> String {
    switch cardType {
    case .search:
      return "card.type.search".localized
    case .sutta:
      return "card.type.sutta".localized
    }
  }

  /// Returns the display title for the card
  func title() -> String {
    // Always return localized CardType + ID (don't store in name)
    return "\(localizedCardTypeName()) \(typeId)"
  }

}

// MARK: - CardManager

/// Instance-based manager for Card instances with ModelContext integration
@Observable
class CardManager {
  // MARK: - Properties

  private let modelContext: ModelContext

  // MARK: - Initialization

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  // MARK: - Public Properties

  /// Returns all cards sorted by createdAt in ascending order
  var allCards: [Card] {
    let fetchDescriptor = FetchDescriptor<Card>(sortBy: [
      SortDescriptor(\.createdAt, order: .forward)
    ])
    do {
      return try modelContext.fetch(fetchDescriptor)
    } catch {
      print("Failed to fetch cards: \(error)")
      return []
    }
  }

  /// Returns total count of all cards
  var totalCount: Int {
    return allCards.count
  }

  // MARK: - Public Methods

  /// Returns count for a specific card type
  func count(for cardType: CardType) -> Int {
    return allCards.filter { $0.cardType == cardType }.count
  }

  /// Returns the largest ID for a specific card type, or 0 if no cards exist
  func largestId(for cardType: CardType) -> Int {
    let cardsOfType = allCards.filter { $0.cardType == cardType }
    return cardsOfType.map { $0.typeId }.max() ?? 0
  }

  /// Adds a new card and returns the card with the assigned ID
  @discardableResult
  func addCard(cardType: CardType = .search) -> Card {
    // Create a new card with the correct ID
    let newCard = Card(
      createdAt: Date(),
      cardType: cardType,
      typeId: largestId(for: cardType) + 1
    )

    modelContext.insert(newCard)

    do {
      try modelContext.save()
    } catch {
      print("Failed to save card: \(error)")
    }

    return newCard
  }

  /// Removes a card (counts are never decremented)
  func removeCard(_ card: Card) {
    modelContext.delete(card)

    do {
      try modelContext.save()
    } catch {
      print("Failed to delete card: \(error)")
    }
  }

  /// Removes cards at specified indices
  func removeCards(at indices: IndexSet) {
    let cards = allCards
    for index in indices {
      if index < cards.count {
        let card = cards[index]
        removeCard(card)
      }
    }
  }
}
