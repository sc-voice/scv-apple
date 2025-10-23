//
//  scv_UITests.swift
//  scv_UITests
//
//  Created by Visakha on 22/10/2025.
//

import XCTest

final class scv_UITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testCardSelectionMovesFocus() throws {
        // Launch the app
        let app = XCUIApplication()
        app.launch()
        
        // Wait for the app to load
        let list = app.tables.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5.0))
        
        // Add some test cards by clicking the "Add Card" button
        let addButton = app.buttons["add.card"]
        if addButton.exists {
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5) // Allow time for card to be added
            
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5) // Add second card
        }
        
        // Get the list of cards
        let cards = list.cells
        XCTAssertGreaterThan(cards.count, 0, "Should have at least one card")
        
        if cards.count >= 2 {
            // Test selecting first card
            let firstCard = cards.element(boundBy: 0)
            firstCard.tap()
            
            // Verify the card is selected (should show close button)
            let closeButton = firstCard.buttons["close.card"]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 2.0), "Close button should appear when card is selected")
            
            // Test selecting second card
            let secondCard = cards.element(boundBy: 1)
            secondCard.tap()
            
            // Verify focus moved to second card
            let secondCloseButton = secondCard.buttons["close.card"]
            XCTAssertTrue(secondCloseButton.waitForExistence(timeout: 2.0), "Close button should appear on second card when selected")
            
            // Verify first card is no longer selected (close button should disappear)
            XCTAssertFalse(closeButton.exists, "Close button should disappear from first card when second card is selected")
        }
    }
}
