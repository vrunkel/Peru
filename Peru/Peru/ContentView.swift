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
                    //EditCollectionsPopoverContent(currentCollection: Binding($selectedFolder)!)
                }
                .onDeleteCommand {
                    print("Delete")
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
            if self.selection.count > 0 {
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
                    items.nsPredicate = NSPredicate(format: "ANY collections == %@", newValue!)
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
    }
    
    /*var table: some View {
     Table(selection: $selection, sortOrder: $items.sortDescriptors) {
     TableColumn("Authors", value: \.authorsForDisplay!).width(min:30, ideal:50, max:200)
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
     }
     rows: {
     ForEach(items) { article in
     TableRow(article)
     }
     }}*/
    
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
                            ForEach(Array(collection.children!) as! Array<Collections>, id: \.self) { aChild in
                                NavigationLink(value: aChild) {
                                    Text(verbatim: aChild.name ?? "Name")
                                }
                            }.onDelete { indexSet in
                                print(indexSet)
                            }
                        }
                    }
                }
            }
        }
    }
    
    var table: some View {
        Table(items, selection: $selection, sortOrder: $items.sortDescriptors) {
            TableColumn("Authors", value: \.authorsForDisplay!).width(min:30, ideal:50, max:200)
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
        }
    }
    
    private func importXML() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.xml]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        if response == .OK {
            let xmlImportParser = ImportXML(moc: viewContext)
            xmlImportParser.parseXML(at: openPanel.url!)
            //openPanel.url
        }
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
            
            let sectionKeywords = Collections(context: viewContext)
            sectionKeywords.name = "Keywords"
            sectionKeywords.canDelete = false
            sectionKeywords.isSection = true
            sectionKeywords.type = 1
            
            let sectionSmart = Collections(context: viewContext)
            sectionSmart.name = "Smart Collections"
            sectionSmart.canDelete = false
            sectionSmart.isSection = true
            sectionSmart.type = 2
            
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
        viewContext.delete(selectedFolder)
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Article(context: viewContext)
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
