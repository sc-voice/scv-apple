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
    let fetchDescriptor = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
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
