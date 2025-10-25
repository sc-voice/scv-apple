//
//  scvUISuttaViewTest.swift
//  scvUITests
//
//  Created by Visakha on 25/10/2025.
//

import XCTest

final class scvUISuttaViewTest: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testSuttaViewAppearsWhenSuttaCardSelected() throws {
    let app = XCUIApplication()
    app.launch()

    // Add first card (search card)
    let addButton = app.buttons["addCardButton"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 2))
    addButton.tap()
    
    // Wait for first card to be created and selected
    Thread.sleep(forTimeInterval: 0.5)

    // Add second card (should be a sutta card based on alternating logic)
    addButton.tap()
    
    // Wait for second card to be created
    Thread.sleep(forTimeInterval: 1.0)

    // Find the sutta card text element
    let suttaCardText = app.staticTexts["card_sutta_1"]
    XCTAssertTrue(suttaCardText.waitForExistence(timeout: 3), "Sutta card should appear in the sidebar")

    // Tap the sutta card text to select it
    suttaCardText.tap()
    
    // Wait for the detail view to fully render
    Thread.sleep(forTimeInterval: 1.0)

    // Verify SuttaView elements are visible
    let suttaTextField = app.textFields["suttaTextField"]
    XCTAssertTrue(suttaTextField.waitForExistence(timeout: 5), "Sutta reference text field should be visible")

    let loadButton = app.buttons["loadSuttaButton"]
    XCTAssertTrue(loadButton.waitForExistence(timeout: 2), "Load Sutta button should be visible")

    // Verify placeholder content appears
    let placeholderTitle = app.staticTexts["suttaPlaceholderTitle"]
    XCTAssertTrue(placeholderTitle.waitForExistence(timeout: 2), "Sutta placeholder title should be visible")
  }

  func testSuttaViewPersistsReference() throws {
    let app = XCUIApplication()
    app.launch()

    // Add search card
    let addButton = app.buttons["addCardButton"]
    addButton.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Add sutta card
    addButton.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Select the sutta card using its identifier
    let suttaCard = app.staticTexts["card_sutta_1"]
    XCTAssertTrue(suttaCard.waitForExistence(timeout: 3))
    suttaCard.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Enter a sutta reference
    let suttaTextField = app.textFields["suttaTextField"]
    XCTAssertTrue(suttaTextField.waitForExistence(timeout: 3))
    suttaTextField.tap()
    suttaTextField.typeText("mn1")

    // Add another card
    addButton.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Reselect the first sutta card using its identifier
    let firstSuttaCard = app.staticTexts["card_sutta_1"]
    XCTAssertTrue(firstSuttaCard.waitForExistence(timeout: 3))
    firstSuttaCard.tap()
    
    // Give the UI a moment to update after card selection
    Thread.sleep(forTimeInterval: 0.5)

    // Re-query the text field to get its updated value after reselecting the card
    let requeriedSuttaTextField = app.textFields["suttaTextField"]
    XCTAssertTrue(requeriedSuttaTextField.waitForExistence(timeout: 3))
    
    // Verify the reference persisted
    XCTAssertEqual(requeriedSuttaTextField.value as? String, "mn1", "Sutta reference should persist in the card")
  }
}

