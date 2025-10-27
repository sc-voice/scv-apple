//
//  Search.swift
//  SC-Voice
//
//  Created by Visakha on 25/10/2025.
//

import Foundation

/// Base class for executing search queries and returning results
open class Search {
  
  // MARK: - Factory Methods
  
  /// Creates a mock search instance that returns results from MockResponse.json
  /// - Returns: A Search instance configured for mock responses
  public static func createMockSearch() -> Search {
    return MockSearch()
  }
  
  // MARK: - Public Methods
  
  /// Searches for the given query and returns a SearchResponse
  /// - Parameter query: The search query string
  /// - Returns: A SearchResponse object containing the search results or error information
  open func search(query: String) -> SearchResponse {
    fatalError("Subclasses must override search(query:)")
  }
}

// MARK: - MockSearch

/// Mock search implementation that loads results from MockResponse.json
private class MockSearch: Search {
  
  // MARK: - Properties
  
  private static let mockResponseFileName = "MockResponse"
  
  // MARK: - Public Methods
  
  /// Searches for the given query and returns a SearchResponse from the mock data
  /// - Parameter query: The search query string
  /// - Returns: A SearchResponse object containing the search results or error information
  override func search(query: String) -> SearchResponse {
    // For "root of suffering" query, return the mock response
    if query.lowercased().contains("root of suffering") {
      return loadMockResponse(pattern: query)
    }
    
    // For other queries, return an error response
    return SearchResponse.failure(
      code: "query_not_supported",
      message: "Search queries other than 'root of suffering' are not yet supported.",
      suggestion: "Try searching for 'root of suffering' or check back later for expanded search capabilities.",
      pattern: query
    )
  }
  
  // MARK: - Private Methods
  
  /// Loads the mock response from the MockResponse.json file
  /// - Parameter pattern: The search pattern to use in error responses
  /// - Returns: A SearchResponse object decoded from the JSON file or an error response
  private func loadMockResponse(pattern: String) -> SearchResponse {
    guard let url = Bundle.main.url(
      forResource: MockSearch.mockResponseFileName,
      withExtension: "json"
    ) else {
      return SearchResponse.failure(
        code: "file_not_found",
        message: "The mock response file (MockResponse.json) was not found in the bundle.",
        suggestion: "Ensure the MockResponse.json file is included in the app bundle.",
        pattern: pattern
      )
    }
    
    do {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      var searchResponse = try decoder.decode(SearchResponse.self, from: data)
      
      // Add the error fields (they won't be in the JSON file)
      searchResponse = SearchResponse(
        author: searchResponse.author,
        lang: searchResponse.lang,
        searchLang: searchResponse.searchLang,
        minLang: searchResponse.minLang,
        maxDoc: searchResponse.maxDoc,
        maxResults: searchResponse.maxResults,
        pattern: searchResponse.pattern,
        method: searchResponse.method,
        resultPattern: searchResponse.resultPattern,
        segsMatched: searchResponse.segsMatched,
        bilaraPaths: searchResponse.bilaraPaths,
        suttaRefs: searchResponse.suttaRefs,
        mlDocs: searchResponse.mlDocs,
        searchError: nil,
        searchSuggestion: nil
      )
      
      return searchResponse
    } catch let decodingError as DecodingError {
      return SearchResponse.failure(
        code: "decoding_failed",
        message: "Failed to decode the search response: \(decodingError.localizedDescription)",
        suggestion: "The JSON file may be corrupted or in an unexpected format.",
        pattern: pattern
      )
    } catch {
      return SearchResponse.failure(
        code: "file_read_failed",
        message: "Failed to read the mock response file: \(error.localizedDescription)",
        suggestion: "Check file permissions and ensure the file is accessible.",
        pattern: pattern
      )
    }
  }
}
