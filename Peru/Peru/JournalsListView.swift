//
//  JournalsListView.swift
//  Peru
//
//  Created by Volker Runkel on 08.08.23.
//

import SwiftUI
import Combine
import PDFKit
import Get
import GenericJSON

struct JournalsList: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    var searchControl = SearchControl()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Journal.name, ascending: true)], animation: .default)
    private var journalItems: FetchedResults<Journal>
    
    @State private var selectedJournal: Journal.ID? = nil
    
    @State private var searchText: String = ""
    enum JournalSearchScope: String, CaseIterable {
        case name
        case abbrev
        case issn
    }
    @State private var searchScope: JournalSearchScope = .name
    
    @State var name: String = ""
    @State var abbrev: String = ""
    @State var issn: String = ""
    
    var anyOfMultiple: [String] {[
        name,
        issn,
        abbrev
    ]}
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack {
                    TextField("Name", text: $name)
                    TextField("Abbrev", text: $abbrev)
                    TextField("ISSN", text: $issn)
                }.frame(width: 400)
                    .disabled(self.selectedJournal == nil)
                Spacer()
                VStack(alignment: .trailing) {
                    Button {
                        if let selectedJournal = self.selectedJournal, let item = journalItems.first(where: { $0.id == selectedJournal }) {
                            item.name = item.name?.localizedCapitalized ?? ""
                            name = item.name ?? ""
                        }
                    } label: {
                        Image(systemName: "textformat")
                    }.buttonStyle(BorderlessButtonStyle())
                    Spacer().frame(height: 30)
                    Button {
                        let journal = Journal(context: viewContext)
                        journal.name = "Name"
                        journal.abbrev = "Abbrev"
                        self.selectedJournal = journal.id
                    } label: {
                        Image(systemName: "plus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                    Button {
                        self.deleteJournal()
                    } label: {
                        Image(systemName: "minus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                        .disabled(self.selectedJournal == nil)
                }
            }
            ScrollViewReader { proxy in
                Table(journalItems, selection: $selectedJournal, sortOrder: $journalItems.sortDescriptors) {
                    TableColumn("Name", value: \.name!).width(min:60, ideal:100, max:300)
                    TableColumn("Abbrev") {journal in
                        Text(journal.abbrev ?? "")
                    }.width(min:60, ideal:80, max:300)
                    TableColumn("ISSN") {journal in
                        Text(journal.issn ?? "")
                    }.width(min:60, ideal:80, max:300)
                    TableColumn("Articles") { journal in
                        Text("\(journal.myArticles?.count ?? 0)")
                    }.width(min:25, ideal:50, max:100)
                }.onDeleteCommand {
                    self.deleteJournal()
                }
                .searchable(text: self.$searchText)
                .searchScopes($searchScope) {
                    ForEach(JournalSearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue.capitalized)
                    }
                }
                .onSubmit(of: .search) {
                    searchPredicate(query: searchText)
                }
                .onChange(of: selectedJournal) { newValue in
                    if self.selectedJournal != nil {
                        if let item = journalItems.first(where: { $0.id == selectedJournal }) {
                            self.name = item.name ?? ""
                            self.abbrev = item.abbrev ?? ""
                            self.issn = item.issn ?? ""
                            proxy.scrollTo(self.selectedJournal!, anchor: .center)
                        }
                    }
                    else {
                        self.name = ""
                        self.abbrev = ""
                        self.issn = ""
                    }
                }
            }
            .onChange(of: anyOfMultiple, perform: { newValue in
                if self.selectedJournal != nil {
                    if let item = journalItems.first(where: { $0.id == selectedJournal }) {
                        item.name = self.name
                        item.abbrev = self.abbrev
                        item.issn = self.issn
                    }
                }
            })
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    self.journalItems.nsPredicate = self.searchControl.originalPredicate
                    self.searchControl.originalPredicate = nil
                }
                self.selectedJournal = nil
            }.frame(width: 500, height: 500)
        }.padding()
    }
    
    private func deleteJournal() {
        guard let selectedJournal = selectedJournal else {
            return
        }
        if let item = journalItems.first(where: { $0.id == selectedJournal }) {
            viewContext.delete(item)
            self.selectedJournal = nil
        }
    }
    
    private func searchPredicate(query: String) {
        if self.searchControl.originalPredicate == nil {
            self.searchControl.originalPredicate = journalItems.nsPredicate
            if journalItems.nsPredicate == nil {
                self.searchControl.originalPredicate = NSPredicate(format: "TRUEPREDICATE")
            }
        }
        var predicate: NSPredicate?
        if self.searchScope == .name {
            predicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Journal.name), self.searchText)
        } else if searchScope == .abbrev {
            predicate = NSPredicate(format: "abbrev CONTAINS[cd] %@", self.searchText)
        } else if searchScope == .issn {
            predicate = NSPredicate(format: "issn CONTAINS[cd] %@" , self.searchText)
        }
        
        self.journalItems.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [self.searchControl.originalPredicate ?? NSPredicate(format: "TRUEPREDICATE"), predicate!])
    }
    
}
