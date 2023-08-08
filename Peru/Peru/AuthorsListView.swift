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
    
    @Environment(\.managedObjectContext) private var viewContext

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
    
    @State var lastname: String = ""
    @State var firstname: String = ""
    @State var middlenames: String = ""
    
    var anyOfMultiple: [String] {[
        lastname,
        firstname,
        middlenames
    ]}
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack {
                    TextField("Lastname", text: $lastname)
                    TextField("Firstname", text: $firstname)
                    TextField("Middlenames", text: $middlenames)
                }.frame(width: 200)
                    .disabled(self.selectedAuthor == nil)
                Spacer()
                VStack(alignment: .trailing) {
                    Button {
                        if let selectedAuthor = self.selectedAuthor, let item = authorItems.first(where: { $0.id == selectedAuthor }) {
                            item.lastname = item.lastname?.localizedCapitalized ?? ""
                            item.firstname = item.firstname?.localizedCapitalized ?? ""
                            lastname = item.lastname ?? ""
                            firstname = item.firstname ?? ""
                            
                            if item.items?.count ?? 0 > 0 {
                                for anArticle in item.items! {
                                    (anArticle as! Article).updateAuthorsForDisplay()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "textformat")
                    }.buttonStyle(BorderlessButtonStyle())
                    Spacer().frame(height: 30)
                    Button {
                        let author = Authors(context: viewContext)
                        author.lastname = "Lastname"
                        author.firstname = "Firstname"
                        self.selectedAuthor = author.id
                    } label: {
                        Image(systemName: "plus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                    Button {
                        self.deleteAuthor()
                    } label: {
                        Image(systemName: "minus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                        .disabled(self.selectedAuthor == nil)
                }
            }
            ScrollViewReader { proxy in
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
                    self.deleteAuthor()
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
                .onChange(of: selectedAuthor) { newValue in
                    if self.selectedAuthor != nil {
                        if let item = authorItems.first(where: { $0.id == selectedAuthor }) {
                            self.lastname = item.lastname ?? ""
                            self.firstname = item.firstname ?? ""
                            self.middlenames = item.middlenames ?? ""
                            proxy.scrollTo(self.selectedAuthor!, anchor: .center)
                        }
                    }
                    else {
                        self.lastname = ""
                        self.firstname = ""
                        self.middlenames = ""
                    }
                }
            }
            .onChange(of: anyOfMultiple, perform: { newValue in
                if self.selectedAuthor != nil {
                    if let item = authorItems.first(where: { $0.id == selectedAuthor }) {
                        item.lastname = self.lastname
                        item.firstname = self.firstname
                        item.middlenames = self.middlenames
                    }
                }
            })
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    self.authorItems.nsPredicate = self.searchControl.originalPredicate
                    self.searchControl.originalPredicate = nil
                }
                self.selectedAuthor = nil
            }.frame(width: 500, height: 500)
        }.padding()
    }
    
    private func deleteAuthor() {
        guard let selectedAuthor = selectedAuthor else {
            return
        }
        if let item = authorItems.first(where: { $0.id == selectedAuthor }) {
            if item.items?.count ?? 0 > 0 || item.editorItems?.count ?? 0 > 0 {
                NSSound.beep()
                return
            }
            viewContext.delete(item)
            self.selectedAuthor = nil
        }
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
