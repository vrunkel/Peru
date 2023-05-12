//
//  PDFPreview.swift
//  Peru
//
//  Created by Volker Runkel on 25.04.23.
//

import SwiftUI
import Combine
import PDFKit
import Get
import GenericJSON

struct PDFPreview: View {
    
    let pdfDocument: PDFDocument?
    let actionPublisher = PassthroughSubject<PDFKitView.Action, Never>()
    let current = CurrentValueSubject<PDFSelection?, Never>(nil)
    
    @State var searchPos: Int = 0
    
    @State private var searchText: String = ""
    @State private var searchResults: [PDFSelection]?
    
    var body: some View {
        if self.pdfDocument != nil {
            PDFKitView(actionPublisher: actionPublisher, currentSearch: current, pdfDocument: self.pdfDocument!)
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem() {
                        Button {
                            actionPublisher.send(.zoomIn)
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                    }
                    ToolbarItem() {
                        Button {
                            actionPublisher.send(.zoomOut)
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }

                    }
                    ToolbarItem () {
                        HStack {
                            Divider().frame(height: 32)
                        }
                    }
                    ToolbarItem() {
                        Button {
                            if (self.searchResults?.count ?? 0) > 0 && searchPos > 1 {
                                searchPos -= 1
                                current.send(self.searchResults![searchPos])
                            }
                            
                        } label: {
                            Image(systemName: "arrow.left.circle")
                        }
                    }
                    ToolbarItem() {
                        Button {
                            if searchPos < (self.searchResults?.count ?? 0) - 2 {
                                searchPos += 1
                                current.send(self.searchResults![searchPos])
                            }
                            
                        } label: {
                            Image(systemName: "arrow.right.circle")
                        }
                    }
                }
                .onChange(of: searchText) { newValue in
                    self.searchResults = self.pdfDocument?.findString(newValue, withOptions: .caseInsensitive)
                    if self.searchResults != nil {
                        searchPos = 0
                        current.send(self.searchResults!.first)
                    }
                }
                .onAppear {
                    /*if let pdfDocument = self.pdfDocument {
                        let metaMatcher = MetaDataQuery()
                        metaMatcher.pdfDocument = pdfDocument
                        if let doi = metaMatcher.doiFromPDFDocument() {
                            Task {
                                if let matchingItems = await metaMatcher.doiMatchWithCrossref(doi: doi), !matchingItems.isEmpty {
                                    print(matchingItems.first!)
                                }
                            }
                        }
                    }
                     */
                }
        }
        else {
            Text("No PDF")
        }
    }
    /*
    private func doiMatch() async {
        if let pdfDocument = self.pdfDocument {
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
                        
                        do {
                            
                            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://doi.crossref.org/servlet/query?pid=runkel@ecoobs.de&format=unixref**&id="+lineString)!)
                            if let xml = try? XML.parse(String(data: data, encoding: .utf8)!) {
                                print(xml["crossref_result", "query_result"].element!.childElements)
                                
                                var itemForMatch = MatchingItem()
                                /*
                                 journal_metadata
                                 journal_issue
                                 journal_article
                                 */
                                for anElement in xml["crossref_result", "query_result", "body", "query", "doi_record", "crossref", "journal", "journal_article"] {
                                    
                                    
                                    if let titleString =  anElement.titles.title.text {
                                        itemForMatch.title = titleString
                                    }
                                    
                                    for author in anElement.contributors.person_name {
                                        var authorString = (author.surname.text ?? "") + ", "
                                        authorString += author.given_name.text ?? ""
                                        itemForMatch.authors.append(authorString)
                                    }
                                    
                                    if let abstractString =  anElement["jats:abstract"][1]["jats:p"].text {
                                        itemForMatch.abstract = abstractString
                                    }
                                }
                                print(itemForMatch)
                                print(itemForMatch.abstract)
                                print(itemForMatch.authors)
                            }
                           
                            
                            //print(String(data: data, encoding: .utf8))
                        }
                        catch let error {
                            print(error)
                        }
                        
                        /*let client = APIClient(baseURL: URL(string: "https://api.crossref.org"))
                        
                        do {
                            var request = Request(path: "/works/"+lineString)
                            request.headers?.updateValue("Peru/0.1 (https://github.com/vrunkel/Peru; mailto:runkel@ecoobs.de)", forKey: "User-Agent")
                            let result = try await client.send(request).data
                            let resultString = String(data: result, encoding: .utf8 )
                            let decode = try JSONDecoder().decode(JSON.self, from: result)
                            print(decode)
                        }
                        catch let error {
                            print(error)
                        }
                         */
                    }
                }
                /*let client = APIClient(baseURL: URL(string: "https://api.crossref.org"))
                
                do {
                    var request = Request(path: "/works/10.1126/sciadv.abf1367")
                    request.headers?.updateValue("Peru/0.1 (https://github.com/vrunkel/Peru; mailto:runkel@ecoobs.de)", forKey: "User-Agent")
                    let result = try await client.send(request).data
                    let resultString = String(data: result, encoding: .utf8 )
                    let decode = try JSONDecoder().decode(JSON.self, from: result)
                    print(decode)
                }
                catch let error {
                    print(error)
                }*/
            }
        }
    }
     */
    
}

struct PDFKitView: NSViewRepresentable {
    
    enum Action {
        case zoomIn
        case zoomOut
    }
    
    let actionPublisher: any Publisher<Action, Never>
    let currentSearch : CurrentValueSubject<PDFSelection?, Never>
    
    class Coordinator: NSObject {
        var actionSubscriber: Cancellable?
        var valueSubscriber: Cancellable?
    }
    
    typealias NSViewType = PDFView
    
    let pdfDocument: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        
        context.coordinator.actionSubscriber = actionPublisher.sink { action in
            switch action {
            case .zoomIn:
                pdfView.zoomIn(nil)
            case .zoomOut:
                pdfView.zoomOut(nil)
            }
        }
        
        context.coordinator.valueSubscriber = currentSearch.sink { value in
            pdfView.setCurrentSelection(value, animate: true)
            pdfView.scrollSelectionToVisible(nil)
        }
        
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
}
