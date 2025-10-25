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
  var name: String
  private(set) var id: Int

  // MARK: - Initialization

  init(
    createdAt: Date = Date(),
    cardType: CardType = .search,
    name: String = "",
    id: Int = 0
  ) {
    self.createdAt = createdAt
    self.cardType = cardType
    self.name = name
    self.id = id
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
    if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return name
    } else {
      // Always return localized CardType + ID (don't store in name)
      return "\(localizedCardTypeName()) \(id)"
    }
  }

  /// Returns the card's unique ID
  func getId() -> Int {
    return id
  }
}

// MARK: - CardManager

/// Singleton manager for Card instances
@Observable
class CardManager {
  // MARK: - Properties

  static let shared = CardManager()

  private var cards: [Card] = []

  // MARK: - Initialization

  private init() {
    // No initialization needed
  }

  // MARK: - Public Properties

  /// Returns all cards sorted by createdAt in ascending order
  var allCards: [Card] {
    return cards.sorted { $0.createdAt < $1.createdAt }
  }

  /// Returns total count of all cards
  var totalCount: Int {
    return cards.count
  }

  // MARK: - Public Methods

  /// Syncs CardManager with SwiftData cards
  func syncWithSwiftData(_ swiftDataCards: [Card]) {
    cards = swiftDataCards.sorted { $0.createdAt < $1.createdAt }
  }

  /// Returns count for a specific card type
  func count(for cardType: CardType) -> Int {
    return cards.filter { $0.cardType == cardType }.count
  }

  /// Returns the largest ID for a specific card type, or 0 if no cards exist
  func largestId(for cardType: CardType) -> Int {
    let cardsOfType = cards.filter { $0.cardType == cardType }
    return cardsOfType.map { $0.id }.max() ?? 0
  }

  /// Adds a new card and returns the card with the assigned ID
  @discardableResult
  func addCard(cardType: CardType = .search, name: String = "") -> Card {
    // Create a new card with the correct ID
    let newCard = Card(
      createdAt: Date(),
      cardType: cardType,
      name: name,
      id: largestId(for: cardType) + 1
    )

    cards.append(newCard)

    // Sort cards after adding to maintain ascending createdAt order
    cards.sort { $0.createdAt < $1.createdAt }

    return newCard
  }

  /// Removes a card (counts are never decremented)
  func removeCard(_ card: Card) {
    if let index = cards.firstIndex(where: { $0 === card }) {
      cards.remove(at: index)
      // Counts are never decremented - they only track total created
    }
  }

  /// Removes cards at specified indices
  func removeCards(at indices: IndexSet) {
    for index in indices.reversed() {
      if index < cards.count {
        let card = cards[index]
        removeCard(card)
      }
    }
  }
}
