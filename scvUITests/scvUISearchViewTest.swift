//
//  scvUISearchViewTest.swift
//  scvUITests
//
//  Created by Visakha on 25/10/2025.
//

import XCTest

final class scvUISearchViewTest: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testSearchViewAppearsWhenSearchCardSelected() throws {
    let app = XCUIApplication()
    app.launch()

    // Add a new card (first card should be a search card based on alternating logic)
    let addButton = app.buttons["addCardButton"]
    addButton.tap()
    
    // Wait for card creation
    Thread.sleep(forTimeInterval: 0.5)

    // Find the search card using its specific identifier
    let searchCard = app.staticTexts["card_search_1"]
    XCTAssertTrue(searchCard.waitForExistence(timeout: 3), "Search card should appear in the sidebar")

    // Tap the search card to select it
    searchCard.tap()
    
    // Give the UI a moment to update the detail view
    Thread.sleep(forTimeInterval: 0.5)

    // Verify SearchView elements are visible
    let searchTextField = app.textFields["searchTextField"]
    XCTAssertTrue(searchTextField.waitForExistence(timeout: 3), "Search text field should be visible")

    let searchButton = app.buttons["searchButton"]
    XCTAssertTrue(searchButton.waitForExistence(timeout: 2), "Search button should be visible")

    // Verify placeholder content appears
    let placeholderTitle = app.staticTexts["searchPlaceholderTitle"]
    XCTAssertTrue(placeholderTitle.waitForExistence(timeout: 2), "Search placeholder title should be visible")
  }

  func testSearchViewPersistsQuery() throws {
    let app = XCUIApplication()
    app.launch()

    // Add a search card
    let addButton = app.buttons["addCardButton"]
    addButton.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Select the search card using its identifier
    let searchCard = app.staticTexts["card_search_1"]
    XCTAssertTrue(searchCard.waitForExistence(timeout: 3))
    searchCard.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Enter a search query
    let searchTextField = app.textFields["searchTextField"]
    XCTAssertTrue(searchTextField.waitForExistence(timeout: 3))
    searchTextField.tap()
    searchTextField.typeText("suffering")

    // Add another card
    addButton.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Reselect the first search card using its identifier
    let firstSearchCard = app.staticTexts["card_search_1"]
    XCTAssertTrue(firstSearchCard.waitForExistence(timeout: 3))
    firstSearchCard.tap()
    
    // Give the UI a moment to update after card selection
    Thread.sleep(forTimeInterval: 0.5)

    // Re-query the text field to get its updated value after reselecting the card
    let requeriedSearchTextField = app.textFields["searchTextField"]
    XCTAssertTrue(requeriedSearchTextField.waitForExistence(timeout: 3))
    
    // Verify the query persisted
    XCTAssertEqual(requeriedSearchTextField.value as? String, "suffering", "Search query should persist in the card")
  }
}

