//
//  SharedCode.swift
//  Peru
//
//  Created by Volker Runkel on 03.05.23.
//

import SwiftUI

let referenceTypes = ["Journal Article", "Book", "Edited Book", "Book Chapter", "Book Section", "Artwork", "Blog", "Company Report", "Computer Program", "Conference Paper", "Conference Presentation", "Conference Proceedings", "Dataset", "EU Directive", "Film", "Government Document", "Government Publication", "Law Report", "Legal Rule or Regulation", "Manuscript", "Map", "Newspaper Article", "Personal Communication", "Report", "Statute or Act", "Thesis", "Web Page"]

actor JournalsCache {
   
    var allJournals: [String]
    
    init(source: [String]) {
        self.allJournals = source
    }
    
    var journals: [String] {
        if let journals = cachedJournals {
            return journals
        }
        
        let journals = allJournals
        cachedJournals = journals
        
        return journals
    }
    
    private var cachedJournals: [String]?
}

extension JournalsCache {

    func lookup(prefix: String) -> [String] {
        let lowercasedPrefix = prefix.lowercased()
        return journals.filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
    }
    
}

@MainActor
final class AutocompleteObject: ObservableObject {
    
    let delay: TimeInterval = 0.3

    @Published var suggestions: [String] = []

    private var journalsCache: JournalsCache?
    
    init(journals: [String]) {
        self.journalsCache = JournalsCache(source: journals)
    }
    
    func reloadCache(journals: [String]) {
        self.journalsCache = JournalsCache(source: journals)
    }
    
    private var task: Task<Void, Never>?
    
    func autocomplete(_ text: String) {
        guard !text.isEmpty else {
            suggestions = []
            task?.cancel()
            return
        }

        task?.cancel()

        task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))
                guard !Task.isCancelled else {
                    return
                }

                let newSuggestions = await journalsCache!.lookup(prefix: text)

                if isSuggestion(in: suggestions, equalTo: text) {
                    // Do not offer only one suggestion same as the input
                    suggestions = []
                } else {
                    suggestions = newSuggestions
                }
            }
            catch {
                return
            }

        }
    }

    private func isSuggestion(in suggestions: [String], equalTo text: String) -> Bool {
        guard let suggestion = suggestions.first, suggestions.count == 1 else {
            return false
        }

        return suggestion.lowercased() == text.lowercased()
    }
}
