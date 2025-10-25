//
//  SearchView.swift
//  scv-apple
//
//  Created by Visakha on 25/10/2025.
//

import SwiftUI

struct SearchView: View {
  @Bindable var card: Card
  @State private var isSearching = false
  @State private var errorMessage: String?
  @State private var searchResponse: SearchResponse?
  
  var body: some View {
    VStack(spacing: 0) {
      // Search input section
      searchBar
      
      Divider()
      
      // Results section
      if isSearching {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = errorMessage {
        errorView(error)
      } else if let response = searchResponse {
        resultsView(response)
      } else if card.searchQuery.isEmpty {
        placeholderView
      } else {
        emptyResultsView
      }
    }
    .onAppear {
      loadCachedResults()
    }
  }
  
  // MARK: - Search Bar
  
  private var searchBar: some View {
    HStack {
      TextField("search.placeholder".localized, text: $card.searchQuery)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          performSearch()
        }
        .accessibilityIdentifier("searchTextField")
      
      Button(action: performSearch) {
        Label("search.button".localized, systemImage: "magnifyingglass")
      }
      .disabled(card.searchQuery.isEmpty || isSearching)
      .accessibilityIdentifier("searchButton")
    }
    .padding()
  }
  
  // MARK: - Results View
  
  private func resultsView(_ response: SearchResponse) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Search summary
        summarySection(response)
        
        Divider()
        
        // Documents with matched segments
        ForEach(response.mlDocs.indices, id: \.self) { index in
          documentSection(response.mlDocs[index])
        }
      }
      .padding()
    }
  }
  
  private func summarySection(_ response: SearchResponse) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("search.results.summary".localized)
        .font(.headline)
      
      HStack {
        Label("\(response.segsMatched) segments", systemImage: "text.alignleft")
        Spacer()
        Label("\(response.totalDocuments) documents", systemImage: "doc.text")
      }
      .font(.subheadline)
      .foregroundColor(.secondary)
      
      if !response.pattern.isEmpty {
        Text("Pattern: \(response.pattern)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
  
  private func documentSection(_ document: MLDocument) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      // Document header
      HStack {
        Image(systemName: "book")
          .foregroundColor(.blue)
        
        VStack(alignment: .leading) {
          Text(document.suttaCode)
            .font(.headline)
          
          Text(document.blurb)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }
      
      // Matched segments
      VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(document.matchedSegments.enumerated()), id: \.offset) { _, segment in
          segmentRow(segment)
        }
      }
      .padding(.leading, 28)
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(8)
  }
  
  private func segmentRow(_ segment: Segment) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(segment.scid)
        .font(.caption2)
        .foregroundColor(.secondary)
      
      if let en = segment.en {
        Text(en)
          .font(.body)
      }
      
      if let pli = segment.pli, !pli.isEmpty {
        Text(pli)
          .font(.caption)
          .foregroundColor(.secondary)
          .italic()
      }
    }
    .padding(.vertical, 4)
  }
  
  // MARK: - Placeholder & Error Views
  
  private var placeholderView: some View {
    VStack(spacing: 16) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 60))
        .foregroundColor(.secondary)
      
      Text("search.placeholder.title".localized)
        .font(.title2)
        .accessibilityIdentifier("searchPlaceholderTitle")
      
      Text("search.placeholder.message".localized)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  private var emptyResultsView: some View {
    VStack(spacing: 16) {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.system(size: 60))
        .foregroundColor(.secondary)
      
      Text("search.empty.title".localized)
        .font(.title2)
      
      Text("search.empty.message".localized)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  private func errorView(_ error: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 60))
        .foregroundColor(.red)
      
      Text("search.error.title".localized)
        .font(.title2)
      
      Text(error)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      Button(action: performSearch) {
        Label("search.retry".localized, systemImage: "arrow.clockwise")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  // MARK: - Search Logic
  
  private func performSearch() {
    guard !card.searchQuery.isEmpty else { return }
    
    isSearching = true
    errorMessage = nil
    
    // TODO: Replace with actual API endpoint
    let urlString = "https://sc-voice.github.io/api/scv/search/\(card.searchQuery)"
    
    guard let encodedQuery = card.searchQuery.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "https://sc-voice.github.io/api/scv/search/\(encodedQuery)") else {
      errorMessage = "Invalid search query"
      isSearching = false
      return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
      DispatchQueue.main.async {
        isSearching = false
        
        if let error = error {
          errorMessage = error.localizedDescription
          return
        }
        
        guard let data = data else {
          errorMessage = "No data received"
          return
        }
        
        do {
          let decoder = JSONDecoder()
          let response = try decoder.decode(SearchResponse.self, from: data)
          searchResponse = response
          
          // Cache results in card
          card.searchResults = data
          errorMessage = nil
        } catch {
          errorMessage = "Failed to parse search results: \(error.localizedDescription)"
        }
      }
    }.resume()
  }
  
  private func loadCachedResults() {
    guard let cachedData = card.searchResults else { return }
    
    do {
      let decoder = JSONDecoder()
      searchResponse = try decoder.decode(SearchResponse.self, from: cachedData)
    } catch {
      // If cached data is invalid, clear it
      card.searchResults = nil
    }
  }
}

// MARK: - Preview

#Preview {
  let card = Card(
    cardType: .search,
    typeId: 1,
    searchQuery: "root of suffering"
  )
  
  return SearchView(card: card)
}

