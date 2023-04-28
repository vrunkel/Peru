//
//  ContentView.swift
//  Peru
//
//  Created by Volker Runkel on 07.10.22.
//

import SwiftUI
import CoreData
import AQUI
import UniformTypeIdentifiers

class SearchControl {
    var originalPredicate: NSPredicate?
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.appSupportPDFs) private var appSupportPDFURL
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collections.type, ascending: true)],
        predicate: NSPredicate(format: "parent == nil"),
        animation: .default)
    private var collections: FetchedResults<Collections>
    @State private var selectedFolder: Collections?
    @State private var manualCollectionPopoverIsShown: Bool = false
    
    var searchControl = SearchControl()
    
    @FetchRequest(
        entity: Article.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Article.year, ascending: false)], predicate: NSPredicate(format: "TRUEPREDICATE"), animation: .default)
    private var items: FetchedResults<Article>
    @State private var selection = Set<Article.ID>()
    
    @State private var selectedItem: Article?
    
    @State private var searchText: String = ""
    enum ArticleSearchScope: String, CaseIterable {
        case authors
        case title
        case keywords
    }
    @State private var searchScope: ArticleSearchScope = .authors
    
    @State private var visibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            self.collectionsList
                .navigationTitle("Sidebar")
                .onAppear() {
                    DispatchQueue.main.async {
                        self.selectedFolder = self.collections.first!
                    }
                }
                .popover(isPresented: $manualCollectionPopoverIsShown,
                         arrowEdge: .trailing) {
                    EditCollectionsPopoverContent(currentCollection: selectedFolder!)
                        .padding(10)
                }
            
        } content: {
            self.table
                .navigationTitle(selectedFolder?.name ?? "All articles")
                .navigationSplitViewColumnWidth(min:400, ideal:600, max: 2000)
                .onChange(of: searchText) { newValue in
                    if newValue.isEmpty {
                        self.items.nsPredicate = self.searchControl.originalPredicate
                        self.searchControl.originalPredicate = nil
                    }
                    self.selection = Set()
                }
                .onChange(of: self.selection) { newValue in
                    self.selectedItem = items.filter { self.selection.contains(($0).id) }.first ?? nil
                }
                .searchable(text: self.$searchText)
                .searchScopes($searchScope) {
                    ForEach(ArticleSearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue.capitalized)
                    }
                }
                .onSubmit(of: .search) {
                    searchPredicate(query: searchText)
                }
        } detail: {
            if self.selection.count > 0 && self.items.count > 0 {
                CustomTabView(
                    tabBarPosition: .top,
                    content: [
                        (
                            tabText: "View",
                            tabIconName: "eye",
                            view: AnyView(
                                articleDetailsView(article: items.filter { self.selection.contains(($0).id) }.first ?? Article())
                            )
                        ),
                        (
                            tabText: "Edit",
                            tabIconName: "square.and.pencil",
                            view: AnyView(
                                articleEditView(article: items.filter { self.selection.contains(($0).id) }.first ?? Article())
                                    .background(Color.white)
                            )
                        )
                    ]
                )
                .navigationSplitViewColumnWidth(min:300, ideal:400, max:500)
            } else {
                Text("No selection")
            }
        }.onAppear(perform: fillStore)
            .onChange(of: self.selectedFolder, perform: { newValue in
                self.selection = Set()
                if newValue == nil || newValue?.type == -1 {
                    items.nsPredicate = nil
                } else {
                    if newValue!.type == 0 {
                        items.nsPredicate = NSPredicate(format: "ANY collections == %@", newValue!)
                    }
                    else if newValue!.type == 1 {
                        //items.nsPredicate = NSPredicate(format: "ANY keywords.keyword == %@", newValue!.name!)
                        items.nsPredicate = NSPredicate(format: "ANY keywords == %@", newValue!.keyword!)
                    }
                }
            })
            .toolbar {
                ToolbarItem {
                    Button(action: addCollection) {
                        Label("Add collection", systemImage: "folder.badge.plus")
                    }
                }
                ToolbarItem {
                    Button(action: removeCollection) {
                        Label("Remove collection", systemImage: "folder.badge.minus")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "doc.badge.plus")
                    }
                }
                ToolbarItem {
                    Button(action: importXML) {
                        Label("Import XML", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .onDeleteCommand(perform: { // This works when clicking in the menu
                if selectedFolder != nil {
                    removeCollection()
                }
            })
    }
        
    var collectionsList: some View {
        List(selection: $selectedFolder) {
            ForEach(collections, id: \.self) { collection in
                if collection.type == -1 {
                    NavigationLink(value: collection) {
                        Text(verbatim: collection.name ?? "Name")
                    }
                } else {
                    Section(header: Text(verbatim: collection.name ?? "---")) {
                        if collection.children?.count ?? 0 > 0 {
                            ForEach(collection.sortedChildren!, id: \.self) { aChild in
                                NavigationLink(value: aChild) {
                                    Text(verbatim: aChild.name ?? "Name")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var table: some View {
        Table(items, selection: $selection, sortOrder: $items.sortDescriptors) {
            TableColumn("Authors", value: \.authorsForDisplay).width(min:30, ideal:50, max:200)
            TableColumn("Title", value: \.title!).width(min:100, ideal:300, max:500)
            TableColumn("Year", value: \.year) { article in
                Text(String(article.year))
            }.width(min:50, ideal:50, max:50)
            TableColumn("Journal") { article in
                Text(article.journal?.name ?? "---")
            }.width(min:30, ideal:50, max:200)
            TableColumn("Publisher") { article in
                Text(article.publishedBy ?? "---")
            }.width(min:30, ideal:50, max:200)
        }.onDeleteCommand {
            self.deleteArticles()
        }
    }
    
    private func importXML() {
        
        let openPanel = NSOpenPanel()
        openPanel.message = "Authorize access to folder containing PDF files for your literature"
        openPanel.prompt = "Authorize"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        
        openPanel.begin { result in
            // WARNING: It's absolutely necessary to access NSOpenPanel.url property to get access
            guard result == .OK, let url = openPanel.url else {
                // HANDLE ERROR HERE ...
                return
            }
            if url.startAccessingSecurityScopedResource() {
                self.startXMLImport()
            }
            url.stopAccessingSecurityScopedResource()
        }
    
    }
    
    private func startXMLImport() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.xml]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        if response == .OK {
            let xmlImportParser = ImportXML(moc: viewContext, appSupportURL: appSupportPDFURL)
            xmlImportParser.parseXML(at: openPanel.url!)
            //openPanel.url
        }
        self.rebuildKeywordCollections()
    }
    
    private func searchPredicate(query: String) {
        if self.searchControl.originalPredicate == nil {
            self.searchControl.originalPredicate = items.nsPredicate
            if items.nsPredicate == nil {
                self.searchControl.originalPredicate = NSPredicate(format: "TRUEPREDICATE")
            }
        }
        var predicate: NSPredicate?
        if self.searchScope == .title {
            predicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Article.title), self.searchText)
        } else if searchScope == .authors {
            predicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Article.authorsForDisplay), self.searchText)
        } else if searchScope == .keywords {
            predicate = NSPredicate(format: "ANY keywords.keyword CONTAINS[cd] %@" , self.searchText)
        }
        
        self.items.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [self.searchControl.originalPredicate ?? NSPredicate(format: "TRUEPREDICATE"), predicate!])
    }
    
    private func fillStore() {
        if self.collections.isEmpty {
            
            let sectionAll = Collections(context: viewContext)
            sectionAll.name = "All articles"
            sectionAll.canDelete = false
            sectionAll.isSection = false
            sectionAll.type = -1
            
            let sectionOne = Collections(context: viewContext)
            sectionOne.name = "Collections"
            sectionOne.canDelete = false
            sectionOne.isSection = true
            sectionOne.type = 0
            
            let sectionTwo = Collections(context: viewContext)
            sectionTwo.name = "Keywords"
            sectionTwo.canDelete = false
            sectionTwo.isSection = true
            sectionTwo.type = 1
                        
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func rebuildKeywordCollections() {
        // clever to do at each startup? Should we only do that if we delete/add keywords? YES!
        // but for now we go this way
        var keyWordSection : Collections?
        for aSection in collections {
            if aSection.type == 1 {
                keyWordSection = aSection
                break
            }
        }
        if keyWordSection != nil {
            
        // first remove all keyword collections
            if let childs = keyWordSection?.children {
                for aCild in childs {
                    viewContext.delete(aCild as! Collections)
                }
                keyWordSection?.removeFromChildren(childs)
            }
        
        // go through all keywords and add a collection for each
        
            let keyWordFetchRequest = Keywords.fetchRequest()
            keyWordFetchRequest.sortDescriptors = [NSSortDescriptor(key: "keyword", ascending: true)]
            if let keywordList = try? viewContext.fetch(keyWordFetchRequest) {
                for aKeyword in keywordList {
                    let newCollection = Collections(context: viewContext)
                    newCollection.name = aKeyword.keyword
                    newCollection.keyword = aKeyword
                    newCollection.isSection = false
                    newCollection.canDelete = true
                    newCollection.type = 1
                    keyWordSection!.addToChildren(newCollection)
                }
            }
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func addCollection() {
        withAnimation {
            let newCollection = Collections(context: viewContext)
            newCollection.name = "New collection"
            newCollection.isSection = false
            newCollection.canDelete = true
            newCollection.type = 0
            
            for aSection in collections {
                if aSection.type == 0 {
                    aSection.addToChildren(newCollection)
                    break
                }
            }
            
            self.selectedFolder = newCollection
            do {
                try viewContext.save()
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                    self.selectedFolder = newCollection
                    self.manualCollectionPopoverIsShown = true
                }
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func removeCollection() {
        guard let selectedFolder = self.selectedFolder else { return }
        if !selectedFolder.canDelete { return }
        if self.selectedFolder?.keyword != nil {
            viewContext.delete(self.selectedFolder!.keyword!)
        }
        viewContext.delete(selectedFolder)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Article(context: viewContext)
            newItem.uuid = UUID().uuidString
            newItem.added = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteArticles() {
        let articlesToDelete = self.selection
        self.selection = Set()
        withAnimation {
            items.filter({ article in
                articlesToDelete.contains(article.id)
            }).forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        self.selection = Set()
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
