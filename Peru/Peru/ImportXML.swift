//
//  ImportXML.swift
//  Peru
//
//  Created by Volker Runkel on 02.04.23.
//

import Foundation
import SwiftyXMLParser
import SwiftUI

class ImportXML {
    
    private var moc: NSManagedObjectContext!
    
    var xml: XML.Accessor?
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    func parseXML(at url: URL) {
        guard var xmlStr = try? String(contentsOf: url, encoding: .utf8) else {
            print("Error str reading")
            return
        }
        
        xmlStr = xmlStr.replacingOccurrences(of: "<style face=\"normal\" font=\"default\" size=\"100%\">", with: "")
        xmlStr = xmlStr.replacingOccurrences(of: "</style>", with: "")
        
        guard let xml = try? XML.parse(xmlStr) else {
            print("Error xml parsing")
            return
        }
        self.xml = xml
        self.databaseImport()
    }
    
    func databaseImport() {
        guard let xml = self.xml else {
            return
        }
        
        /* for now only local check, later we need to check full database */
        var availableAuthors = Dictionary<String, Authors>()
        let authorsRequest = NSFetchRequest<Authors>()
        authorsRequest.entity = Authors.entity()
        if let authorsInDB = try? moc.fetch(authorsRequest) {
            for author in authorsInDB {
                availableAuthors.updateValue(author, forKey: author.lastname!)
            }
        }
        var availableJournals = [String]()
        let journalRequest = NSFetchRequest<Journal>()
        journalRequest.entity = Journal.entity()
        if let journalsInDB = try? moc.fetch(journalRequest) {
            for journal in journalsInDB {
                availableJournals.append(journal.name!)
            }
        }
        
        var availableKeywords = Dictionary<String, Keywords>()
        let keywordRequest = NSFetchRequest<Keywords>()
        keywordRequest.entity = Keywords.entity()
        if let keywordsInDB = try? moc.fetch(keywordRequest) {
            for aKeyword in keywordsInDB {
                if aKeyword.keyword != nil {
                    availableKeywords.updateValue(aKeyword, forKey: aKeyword.keyword!)
                }
            }
        }
        
        var count = 0
        for hit in xml["xml", "records", "record"] {
            let article = Article(context: moc)
            //article.title = CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (hit.titles.title.text ?? "Title") as CFString, nil) as String?
            if let attribString = try? AttributedString(markdown: (hit.titles.title.text ?? "Title")) {
                article.title = String(attribString.characters)
            } else {
                article.title = hit.titles.title.text ?? "Title"
            }
            article.subtitle = hit["titles","secondary-title"].text
            
            let authorSet = NSMutableOrderedSet()
            for author in hit.contributors.authors.author {
                if let fullname = author.text, !fullname.isEmpty {
                    let nameComponents  = fullname.components(separatedBy: " ")
                    let key = nameComponents.first!.replacingOccurrences(of: ",", with: "")
                    if let author = availableAuthors[key] {
                        authorSet.add(author)
                    }
                    else {
                        let author = Authors(context: moc)
                        author.lastname = key
                        if nameComponents.count > 1 {
                            author.firstname = nameComponents [1]
                        }
                        if nameComponents.count > 2 {
                            author.middlenames = nameComponents [2]
                        }
                        authorSet.add(author)
                        availableAuthors.updateValue(author, forKey: key)
                    }
                }
            }
            
            if authorSet.count > 0 {
                article.authors = NSOrderedSet(orderedSet: authorSet)
                var string = ""
                for anAuthor in article.authors! {
                    string.append(", ")
                    string.append((anAuthor as! Authors).lastname!)
                }
                string.removeFirst(2)
                article.authorsForDisplay = string
            }
            
            if let yearString = hit.dates.year.text {
                article.year = Int16(yearString) ?? 0
                // missing exact date, which is stored as well
            }
            
            if let doiURL = hit.urls["related-urls", "url"].text {
                article.doi = URL(string:doiURL)
                // pdf URLS for pdf import
            }
            
            let type = hit["ref-type"].attributes
            if let name = type["name"] {
                article.type = name
            }
            
            if let pages = hit.pages.text {
                article.pages = pages
            }
            
            if let volume = hit.volume.text {
                article.volume = volume
            }
            
            if let number = hit.number.text {
                article.edition = number
            }
            
            if let abstract = hit.abstract.text {
                article.abstract = abstract
            }
            
            for journal in hit.periodical {
                if let fullTitle = journal["full-title"].text {
                    if availableJournals.contains(fullTitle) {
                        article.journal = fullTitle
                    } else {
                        article.journal = fullTitle
                        let newJournal = Journal(context: moc)
                        newJournal.name = fullTitle
                        if let abbrev = journal["abbr-1"].text {
                            newJournal.abbrev = abbrev
                        }
                    }
                }
            }
            
            for aKeyword in hit["keywords", "keyword"] {
                if let myKeyword = aKeyword.text {
                    if let keyword = availableKeywords[myKeyword] {
                        article.addToKeywords(keyword)
                    }
                    else {
                        let newKeyword = Keywords(context: moc)
                        newKeyword.keyword = myKeyword
                        article.addToKeywords(newKeyword)
                    }
                }
            }
            
            count += 1
            //if count > 200 { break }
        }
        do {
            try moc.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}

