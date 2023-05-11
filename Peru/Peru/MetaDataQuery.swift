//
//  MetaDataQuery.swift
//  Peru
//
//  Created by Volker Runkel on 06.05.23.
//

import Foundation
import SwiftyXMLParser
import PDFKit

class MetaDataQuery {
    
    var pdfDocumentURL: URL? = nil {
        didSet {
            if pdfDocumentURL != nil {
                self.pdfDocument = PDFDocument(url: self.pdfDocumentURL!)
            }
        }
    }
    var pdfDocument: PDFDocument? = nil
    
    func doiFromPDFDocument() -> String? {
        guard let pdfDocument = self.pdfDocument else {
            return nil
        }
        let doiSearch = pdfDocument.findString("doi", withOptions: .caseInsensitive)
        if !doiSearch.isEmpty {
            let searchRes = doiSearch.first!
            searchRes.extendForLineBoundaries()
            if var lineString = searchRes.string?.lowercased() {
                print(lineString)
                if let range: Range<String.Index> = lineString.range(of: "doi") {
                    let index: Int = lineString.distance(from: lineString.startIndex, to: range.lowerBound)
                    lineString.removeSubrange(lineString.startIndex..<lineString.index(lineString.startIndex, offsetBy: index+3))
                    if lineString.hasPrefix(":") {
                        lineString.remove(at: lineString.startIndex)
                    }
                    lineString = lineString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if lineString.hasPrefix("10") {
                        return lineString
                    }
                }
            }
        }
        return nil
    }
    
    func doiMatchWithCrossref(doi: String) async -> [MatchingItem]? {
        // https://doi.crossref.org/servlet/query?pid=runkel@ecoobs.de&format=unixref**&id=10.1111/acv.12200
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://doi.crossref.org/servlet/query?pid=runkel@ecoobs.de&format=unixref**&id="+doi)!)
            if let xml = try? XML.parse(String(data: data, encoding: .utf8)!) {
                print(xml["crossref_result", "query_result"].element!.childElements)
                
                var itemForMatch = MatchingItem()
                
                if let journalTitleString =  xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_metadata"].full_title.text {
                    itemForMatch.journal = journalTitleString
                }
                
                if let journalAbbrevString =  xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_metadata"].abbrev_title.text {
                    itemForMatch.journal_abbrev = journalAbbrevString
                }
                
                if let journalISSNString =  xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_metadata"].issn.text {
                    itemForMatch.journalISSN = journalISSNString
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
}
