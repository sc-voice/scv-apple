//
//  SuttaView.swift
//  scv-apple
//
//  Created by Visakha on 25/10/2025.
//

import SwiftUI

struct SuttaView: View {
  @Bindable var card: Card
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var suttaData: MLDocument?
  
  var body: some View {
    VStack(spacing: 0) {
      // Sutta reference input section
      suttaInputBar
      
      Divider()
      
      // Content section
      if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = errorMessage {
        errorView(error)
      } else if let sutta = suttaData {
        suttaContentView(sutta)
      } else if card.suttaReference.isEmpty {
        placeholderView
      } else {
        emptyView
      }
    }
    .onAppear {
      // Auto-load if we have a reference
      if !card.suttaReference.isEmpty && suttaData == nil {
        loadSutta()
      }
    }
  }
  
  // MARK: - Input Bar
  
  private var suttaInputBar: some View {
    HStack {
      TextField("sutta.reference.placeholder".localized, text: $card.suttaReference)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          loadSutta()
        }
        .accessibilityIdentifier("suttaTextField")
        .accessibilityLabel("sutta.reference.accessibility.label".localized)

      Button(action: loadSutta) {
        Label("sutta.load.button".localized, systemImage: "book")
      }
      .disabled(card.suttaReference.isEmpty || isLoading)
      .accessibilityIdentifier("loadSuttaButton")
      .accessibilityLabel("sutta.load.button.accessibility.label".localized)
    }
    .padding()
  }
  
  // MARK: - Sutta Content View
  
  private func suttaContentView(_ sutta: MLDocument) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Header
        headerSection(sutta)
        
        Divider()
        
        // Segments
        segmentsSection(sutta)
      }
      .padding()
    }
  }
  
  private func headerSection(_ sutta: MLDocument) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "book")
          .font(.title)
          .foregroundColor(.blue)
        
        VStack(alignment: .leading) {
          Text(sutta.suttaCode)
            .font(.title)
            .fontWeight(.bold)
          
          Text(sutta.blurb)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      
      // Stats
      HStack(spacing: 16) {
        Label("\(sutta.stats.nSegments) segments", systemImage: "text.alignleft")
        Label("\(sutta.stats.nSections) sections", systemImage: "list.bullet")
        
        if sutta.stats.seconds > 0 {
          Label(formatDuration(sutta.stats.seconds), systemImage: "clock")
        }
      }
      .font(.caption)
      .foregroundColor(.secondary)
    }
  }
  
  private func segmentsSection(_ sutta: MLDocument) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      // Sort segments by scid to maintain proper order
      let sortedSegments = sutta.segMap.sorted { $0.key < $1.key }
      
      ForEach(sortedSegments, id: \.key) { key, segment in
        segmentView(segment)
      }
    }
  }
  
  private func segmentView(_ segment: Segment) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      // Segment ID
      Text(segment.scid)
        .font(.caption2)
        .foregroundColor(.secondary)
        .textSelection(.enabled)
      
      // English translation
      if let en = segment.en, !en.isEmpty {
        Text(en)
          .font(.body)
          .textSelection(.enabled)
      }
      
      // Pali text
      if let pli = segment.pli, !pli.isEmpty {
        Text(pli)
          .font(.callout)
          .foregroundColor(.secondary)
          .italic()
          .textSelection(.enabled)
      }
      
      // Reference (if it's a heading or special segment)
      if let ref = segment.ref, !ref.isEmpty, segment.en == nil || segment.en?.isEmpty == true {
        Text(ref)
          .font(.headline)
          .textSelection(.enabled)
      }
    }
    .padding(.vertical, 8)
  }
  
  // MARK: - Placeholder & Error Views
  
  private var placeholderView: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed")
        .font(.system(size: 60))
        .foregroundColor(.secondary)
      
      Text("sutta.placeholder.title".localized)
        .font(.title2)
        .accessibilityIdentifier("suttaPlaceholderTitle")
      
      Text("sutta.placeholder.message".localized)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("sutta.examples.title".localized)
          .font(.caption)
          .foregroundColor(.secondary)
        
        Text("mn1, sn1.1, dn1, an1.1")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()
      .background(Color.secondary.opacity(0.1))
      .cornerRadius(8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  private var emptyView: some View {
    VStack(spacing: 16) {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.system(size: 60))
        .foregroundColor(.secondary)
      
      Text("sutta.empty.title".localized)
        .font(.title2)
      
      Text("sutta.empty.message".localized)
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
      
      Text("sutta.error.title".localized)
        .font(.title2)
      
      Text(error)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      Button(action: loadSutta) {
        Label("sutta.retry".localized, systemImage: "arrow.clockwise")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  // MARK: - Loading Logic
  
  private func loadSutta() {
    guard !card.suttaReference.isEmpty else { return }
    
    isLoading = true
    errorMessage = nil
    
    // Normalize the sutta reference (remove spaces, lowercase)
    let normalizedRef = card.suttaReference
      .trimmingCharacters(in: .whitespaces)
      .lowercased()
    
    // TODO: Replace with actual API endpoint for fetching suttas
    guard let encodedRef = normalizedRef.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "https://sc-voice.github.io/api/scv/search/\(encodedRef)") else {
      errorMessage = "Invalid sutta reference"
      isLoading = false
      return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
      DispatchQueue.main.async {
        isLoading = false
        
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
          let searchResponse = try decoder.decode(SearchResponse.self, from: data)
          
          // Extract the first document as the sutta
          if let firstDoc = searchResponse.mlDocs.first {
            suttaData = firstDoc
            errorMessage = nil
          } else {
            errorMessage = "Sutta not found"
          }
        } catch {
          errorMessage = "Failed to load sutta: \(error.localizedDescription)"
        }
      }
    }.resume()
  }
  
  // MARK: - Helper Methods
  
  private func formatDuration(_ seconds: Double) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    
    if minutes > 0 {
      return "\(minutes)m \(remainingSeconds)s"
    } else {
      return "\(remainingSeconds)s"
    }
  }
}

// MARK: - Preview

#Preview {
  let card = Card(
    cardType: .sutta,
    typeId: 1,
    suttaReference: "mn1"
  )
  
  return SuttaView(card: card)
}

