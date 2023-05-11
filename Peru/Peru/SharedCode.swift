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

struct MatchingItem: Decodable {
    var publisher_location: String?
    var journal: String?
    var journal_abbrev: String?
    var journalISSN: String?
    var edition_number: String?
    var publisher: String?
    var issue: String?
    var year: String?
    var month: String?
    var day: String?
    var DOI: String?
    var type: String?
    var pages: String?
    var title: String?
    var volume: String?
    var authors: [String] = Array()
    var abstract: String?
}



/* not used - generic json favoured
 struct CrossRefData: Decodable {
    let status: String
    let message_type: String?
    let message_version: String?
    let message: CrossRefDataItem?
    
    enum CodingKeys : String, CodingKey {
        case status = "status"
        case message_type = "message-type"
        case message_version = "message-version"
        case message = "message"
    }
}

struct CrossRefDataItem: Decodable {
    let posted: String?
    let publisher_location: String?
    let update_to: String?
    let edition_number: String?
    let publisher: String?
    let issue: String?
    let DOI: String?
    let type: String?
    let page: String?
    let title: [String]?
    let volume: String?
    let author: [[String:String]]?
    
    enum CodingKeys : String, CodingKey {
        case posted = "posted"
        case publisher_location = "publisher-location"
        case update_to = "update-to"
        case edition_number = "edition-number"
        case publisher = "publisher"
        case issue = "issue"
        case DOI = "DOI"
        case type = "type"
        case page = "page"
        case title = "title"
        case volume = "volume"
        case author = "author"
    }
} */

