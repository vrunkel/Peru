//
//  PDFPreview.swift
//  Peru
//
//  Created by Volker Runkel on 25.04.23.
//

import SwiftUI
import Combine
import PDFKit

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
        }
        else {
            Text("No PDF")
        }
    }
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
