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
    
    private var appSupportPDFURL: URL?
    
    private var moc: NSManagedObjectContext!
    
    var xml: XML.Accessor?
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    init(moc: NSManagedObjectContext, appSupportURL: URL) {
        self.moc = moc
        self.appSupportPDFURL = appSupportURL
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
        
        let fm = FileManager.default
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en")
        
        /* for now only local check, later we need to check full database */
        var availableAuthors = Dictionary<String, Authors>()
        let authorsRequest = NSFetchRequest<Authors>()
        authorsRequest.entity = Authors.entity()
        if let authorsInDB = try? moc.fetch(authorsRequest) {
            for author in authorsInDB {
                availableAuthors.updateValue(author, forKey: author.lastname!)
            }
        }
        var availableJournals = Dictionary<String, Journal>()
        let journalRequest = NSFetchRequest<Journal>()
        journalRequest.entity = Journal.entity()
        if let journalsInDB = try? moc.fetch(journalRequest) {
            for journal in journalsInDB {
                availableJournals.updateValue(journal, forKey: journal.name!)
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
            article.uuid = UUID().uuidString
            article.added = Date()
            if let attribString = try? AttributedString(markdown: (hit.titles.title.text ?? "Title")) {
                article.title = String(attribString.characters)
            } else {
                article.title = hit.titles.title.text ?? "Title"
            }
                    
            let authorSet = NSMutableOrderedSet()
            for author in hit.contributors.authors[0].author {
                if let fullname = author.text, !fullname.isEmpty {
                    let nameComponents  = fullname.components(separatedBy: ", ")
                    let key = nameComponents.first!
                    if let author = availableAuthors[key] {
                        authorSet.add(author)
                    }
                    else {
                        let author = Authors(context: moc)
                        author.lastname = key
                        if nameComponents.count > 1 {
                            author.firstname = nameComponents[1].components(separatedBy: " ").first
                            if nameComponents[1].components(separatedBy: " ").count > 2 {
                                author.middlenames = nameComponents[1].components(separatedBy: " ")[1]
                            }
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
            
            // authors[1] exist only for Books = Editor!
            let editorsSet = NSMutableOrderedSet()
            for author in hit.contributors.authors[1].author {
                if let fullname = author.text, !fullname.isEmpty {
                    let nameComponents  = fullname.components(separatedBy: ", ")
                    let key = nameComponents.first!
                    if let author = availableAuthors[key] {
                        editorsSet.add(author)
                    }
                    else {
                        let author = Authors(context: moc)
                        author.lastname = key
                        if nameComponents.count > 1 {
                            author.firstname = nameComponents[1].components(separatedBy: " ").first
                            if nameComponents[1].components(separatedBy: " ").count > 2 {
                                author.middlenames = nameComponents[1].components(separatedBy: " ")[1]
                            }
                        }
                        
                        editorsSet.add(author)
                        availableAuthors.updateValue(author, forKey: key)
                    }
                }
            }
            if editorsSet.count > 0 {
                article.editors = NSOrderedSet(orderedSet: editorsSet)
            }
            
            // secondary-authors can hold the editors optionally
            if editorsSet.set.isEmpty {
                for author in hit.contributors["secondary-authors"].author {
                    if let fullname = author.text, !fullname.isEmpty {
                        let nameComponents  = fullname.components(separatedBy: ", ")
                        let key = nameComponents.first!
                        if let author = availableAuthors[key] {
                            editorsSet.add(author)
                        }
                        else {
                            let author = Authors(context: moc)
                            author.lastname = key
                            if nameComponents.count > 1 {
                                author.firstname = nameComponents[1].components(separatedBy: " ").first
                                if nameComponents[1].components(separatedBy: " ").count > 2 {
                                    author.middlenames = nameComponents[1].components(separatedBy: " ")[1]
                                }
                            }
                            
                            editorsSet.add(author)
                            availableAuthors.updateValue(author, forKey: key)
                        }
                    }
                }
                if editorsSet.count > 0 {
                    article.editors = NSOrderedSet(orderedSet: editorsSet)
                }
            }
            
            if let yearString = hit.dates.year.text {
                article.year = Int16(yearString) ?? 0
                
                if let dateString = hit.dates["pub-dates", "date"].text {
                    if let date = dateFormatter.date(from: dateString + " " + yearString) {
                        article.published = date
                    }
                }
            }
            
            
            if let doiURL = hit.urls["related-urls", "url"].text {
                article.doi = URL(string:doiURL)
            }
            
            if let pdfURL = hit.urls["pdf-urls", "url"].text {
                if let sourceURL = URL(string: pdfURL), fm.fileExists(atPath: sourceURL.path) {
                    do {
                        var destinationURL = appSupportPDFURL!.appendingPathComponent(article.uuid!)
                        if !fm.fileExists(atPath: destinationURL.path) {
                            try fm.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                        }
                        destinationURL.appendPathComponent(sourceURL.lastPathComponent)
                        
                        try fm.copyItem(at: sourceURL, to: destinationURL)
                        article.relatedFile = destinationURL
                    }
                    catch let error {
                        print(error)
                    }
                }
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
            
            if let issue = hit.number.text {
                article.issue = issue
            }
            
            if let edition = hit.edition.text {
                article.edition = edition
            }
            
            if let isbn = hit.isbn.text {
                article.isbn = isbn
            }
            
            if let number = hit.number.text {
                article.edition = number
            }
            
            if let abstract = hit.abstract.text {
                article.abstract = abstract
            }
            
            if let city = hit["pub-location"].text {
                article.city = city
            }
            
            if let publisher = hit["publisher"].text {
                article.publishedBy = publisher
            }
            
            for journal in hit.periodical {
                if let fullTitle = journal["full-title"].text {
                    if let journal = availableJournals[fullTitle] {
                        article.journal = journal
                    } else {
                        let newJournal = Journal(context: moc)
                        newJournal.name = fullTitle
                        if let abbrev = journal["abbr-1"].text {
                            newJournal.abbrev = abbrev
                        }
                        article.journal = newJournal
                        availableJournals.updateValue(newJournal, forKey: fullTitle)
                    }
                }
            }
            
            article.subtitle = hit["titles","secondary-title"].text
            if article.subtitle == article.journal?.name ?? "" {
                article.subtitle = nil
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
                        availableKeywords.updateValue(newKeyword, forKey: myKeyword)
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

