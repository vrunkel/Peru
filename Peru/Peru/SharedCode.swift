//
//  SharedCode.swift
//  Peru
//
//  Created by Volker Runkel on 03.05.23.
//

import SwiftUI
import SwiftyXMLParser

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

func doiMatch(doi: String) async -> [MatchingItem]? {
    
    do {
        
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://doi.crossref.org/servlet/query?pid=runkel@ecoobs.de&format=unixref**&id="+doi)!)
        if let xml = try? XML.parse(String(data: data, encoding: .utf8)!) {
            print(xml["crossref_result", "query_result"].element!.childElements)
            
            var itemForMatch = MatchingItem()
            /*
             journal_metadata
             journal_issue
             journal_article
             */
            
            if let journalTitleString =  xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_metadata"].full_title.text {
                itemForMatch.journal = journalTitleString
            }
            
            if let journalIssueString =  xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_issue"].issue.text {
                itemForMatch.issue = journalIssueString
            }
            
            if let journalVolumeString =  xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_issue"].journal_volume.volume.text {
                itemForMatch.volume = journalVolumeString
            }
            
            for anElement in xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_article"] {
                
                if let titleString =  anElement.titles.title.text {
                    itemForMatch.title = titleString
                }
                
                for author in anElement.contributors.person_name {
                    var authorString = (author.surname.text ?? "") + ", "
                    authorString += author.given_name.text ?? ""
                    itemForMatch.authors.append(authorString)
                }
                
                if let abstractString =  anElement["jats:abstract"][0]["jats:p"].text {
                    itemForMatch.abstract = abstractString
                }
                
                if let abstractString = anElement["jats:abstract"][1]["jats:p"].text {
                    itemForMatch.abstract = abstractString
                }
                
                if let doiString =  anElement.doi_data.doi.text {
                    itemForMatch.DOI = doiString
                }
                
                if let yearString =  anElement.publication_date.first.year.text {
                    itemForMatch.year = yearString
                }
                
                if let monthString =  anElement.publication_date.first.month.text {
                    itemForMatch.month = monthString
                }
                
                if let dayString =  anElement.publication_date.first.day.text {
                    itemForMatch.day = dayString
                }
                
                if let pagesString =  anElement.pages.first_page.text {
                    itemForMatch.pages = pagesString
                }
                
                if let pagesString =  anElement.pages.last_page.text {
                    if itemForMatch.pages != nil {
                        itemForMatch.pages! += "-" + pagesString
                    }
                }
            }
            
            return [itemForMatch]
        }
    }
    catch let error {
        print(error)
    }
    return nil
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

