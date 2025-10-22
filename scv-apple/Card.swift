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
    var cardType: CardType
    var name: String
    
    init(createdAt: Date = Date(), cardType: CardType = .search, name: String = "") {
        self.createdAt = createdAt
        self.cardType = cardType
        self.name = name
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
    
    /// Returns the display title for the card
    func title() -> String {
        if !name.isEmpty {
            return name
        } else {
            return "card.at.createdAt".localized(createdAt.formatted(date: .numeric, time: .standard))
        }
    }
}

/// Singleton manager for Card instances
@Observable
class CardManager {
    static let shared = CardManager()
    
    private var cards: [Card] = []
    private var cardCounts: [CardType: Int] = [:]
    
    private init() {
        // Initialize counts for all card types
        for cardType in CardType.allCases {
            cardCounts[cardType] = 0
        }
    }
    
    /// Returns all cards
    var allCards: [Card] {
        return cards
    }
    
    /// Returns count for a specific card type
    func count(for cardType: CardType) -> Int {
        return cardCounts[cardType] ?? 0
    }
    
    /// Returns total count of all cards
    var totalCount: Int {
        return cards.count
    }
    
    /// Adds a new card and updates counts
    func addCard(_ card: Card) {
        cards.append(card)
        cardCounts[card.cardType, default: 0] += 1
    }
    
    /// Removes a card and updates counts
    func removeCard(_ card: Card) {
        if let index = cards.firstIndex(where: { $0 === card }) {
            cards.remove(at: index)
            cardCounts[card.cardType, default: 0] = max(0, (cardCounts[card.cardType] ?? 0) - 1)
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
