//
//  Card.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import Foundation
import SwiftData
import SwiftUI

enum CardType: String, CaseIterable, Codable {
    case search = "search"
    case sutta = "sutta"
}

@Model
final class Card {
    var createdAt: Date
    let cardType: CardType
    var name: String
    var id: Int
    
    init(createdAt: Date = Date(), cardType: CardType = .search, name: String = "") {
        self.createdAt = createdAt
        self.cardType = cardType
        self.name = name
        // ID will be set to 1 + largest existing ID for this card type, or 1 if none exist
        self.id = CardManager.shared.largestId(for: cardType) + 1
    }
    
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
        if !name.isEmpty {
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

/// Singleton manager for Card instances
@Observable
class CardManager {
    static let shared = CardManager()
    
    private var cards: [Card] = []
    
    private init() {
        // No initialization needed
    }
    
    /// Syncs CardManager with SwiftData cards
    func syncWithSwiftData(_ swiftDataCards: [Card]) {
        cards = swiftDataCards.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// Returns all cards sorted by createdAt in ascending order
    var allCards: [Card] {
        return cards.sorted { $0.createdAt < $1.createdAt }
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
    
    /// Returns total count of all cards
    var totalCount: Int {
        return cards.count
    }
    
    /// Adds a new card
    func addCard(_ card: Card) {
        cards.append(card)
        // Sort cards after adding to maintain ascending createdAt order
        cards.sort { $0.createdAt < $1.createdAt }
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
    
    /// Creates and adds a new card with specified type
    func createCard(cardType: CardType = .search, name: String = "") -> Card {
        let newCard = Card(cardType: cardType, name: name)
        addCard(newCard)
        return newCard
    }
}
