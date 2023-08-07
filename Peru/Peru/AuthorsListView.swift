//
//  AuthorsListView.swift
//  Peru
//
//  Created by Volker Runkel on 04.08.23.
//

import SwiftUI
import Combine
import PDFKit
import Get
import GenericJSON

struct AuthorsList: View {
    
    //@Environment(\.managedObjectContext) private var viewContext
    
    var searchControl = SearchControl()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Authors.lastname, ascending: true)], animation: .default)
    private var authorItems: FetchedResults<Authors>
    
    @State private var selectedAuthor: Authors.ID? = nil
    
    @State private var searchText: String = ""
    enum AuthorsSearchScope: String, CaseIterable {
        case name
        case articleCount
        case editCount
    }
    @State private var searchScope: AuthorsSearchScope = .name
    
    var body: some View {
        Table(authorItems, selection: $selectedAuthor, sortOrder: $authorItems.sortDescriptors) {
            TableColumn("Lastname", value: \.lastname!).width(min:60, ideal:100, max:300)
            TableColumn("Firstname", value: \.firstname!).width(min:60, ideal:100, max:300)
            TableColumn("Middlenames") {author in
                Text(author.middlenames ?? "")
            }.width(min:60, ideal:80, max:300)
            TableColumn("Articles") { author in
                Text("\(author.items?.count ?? 0)")
            }.width(min:25, ideal:50, max:100)
            TableColumn("Editor") { author in
                Text("\(author.editorItems?.count ?? 0)")
            }.width(min:25, ideal:50, max:100)
        }.onDeleteCommand {
            //self.deleteArticles()
        }
        .searchable(text: self.$searchText)
        .searchScopes($searchScope) {
            ForEach(AuthorsSearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue.capitalized)
            }
        }
        .onSubmit(of: .search) {
            searchPredicate(query: searchText)
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                self.authorItems.nsPredicate = self.searchControl.originalPredicate
                self.searchControl.originalPredicate = nil
            }
            self.selectedAuthor = nil
        }.frame(width: 500, height: 500)
    }
    
    private func searchPredicate(query: String) {
        if self.searchControl.originalPredicate == nil {
            self.searchControl.originalPredicate = authorItems.nsPredicate
            if authorItems.nsPredicate == nil {
                self.searchControl.originalPredicate = NSPredicate(format: "TRUEPREDICATE")
            }
        }
        var predicate: NSPredicate?
        if self.searchScope == .name {
            predicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Authors.lastname), self.searchText)
        } else if searchScope == .articleCount {
            predicate = NSPredicate(format: "items.@count == %d", Int(self.searchText) ?? 0)
        } else if searchScope == .editCount {
            predicate = NSPredicate(format: "ANY keywords.keyword CONTAINS[cd] %@" , self.searchText)
        }
        
        self.authorItems.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [self.searchControl.originalPredicate ?? NSPredicate(format: "TRUEPREDICATE"), predicate!])
    }
    
}
