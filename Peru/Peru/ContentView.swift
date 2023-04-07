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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.year, ascending: false)], animation: .default)
    private var items: FetchedResults<Article>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collections.name, ascending: true)],
        predicate: NSPredicate(format: "parent == nil"),
        animation: .default)
    private var collections: FetchedResults<Collections>
    
    @State private var selection = Set<Article.ID>()
    @State private var sortOrder = [KeyPathComparator(\Article.year)]
    @State var sorting: [KeyPathComparator<Article>] = [
             .init(\.year, order: SortOrder.forward)
           ]
    
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var selectedFolder: Collections?
    @State private var selectedItem: Article?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedFolder) {
                ForEach(collections, id: \.self) { collection in
                    Section(header: Text(verbatim: collection.name ?? "---")) {
                        if collection.children?.count ?? 0 > 0 {
                            ForEach(Array(collection.children!) as! Array<Collections>, id: \.self) { aChild in
                                NavigationLink(value: aChild) {
                                    Text(verbatim: aChild.name ?? "Name")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sidebar")
        } content: {
            self.table
                .navigationTitle(selectedFolder?.name ?? "All articles")
                .navigationSplitViewColumnWidth(min:400, ideal:600, max: 2000)
                .onChange(of: self.selection) { newValue in
                    self.selectedItem = items.filter { self.selection.contains(($0).id) }.first ?? nil
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
                                articleDetailsView(article: items.filter { self.selection.contains(($0).id) }.first!)
                            )
                        ),
                        (
                            tabText: "Edit",
                            tabIconName: "square.and.pencil",
                            view: AnyView(
                                articleEditView(article: items.filter { self.selection.contains(($0).id) }.first!)
                                    .background(Color.white)
                            )
                        )
                    ]
                )
                .navigationSplitViewColumnWidth(min:300, ideal:400, max:500)
            }
        }//.onAppear(perform: fillStore)
        .toolbar {
            ToolbarItem {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button(action: importXML) {
                    Label("Import XML", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
    
    var table: some View {
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
    }}
    
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
    
    /*private func fillStore() {
        let sectionOne = Collections(context: viewContext)
        sectionOne.name = "Collections"
        sectionOne.canDelete = false
        sectionOne.isSection = true
        
        let newCollection1 = Collections(context: viewContext)
        newCollection1.name = "Collection1"
        newCollection1.canDelete = true
        newCollection1.isSection = false
        newCollection1.parent = sectionOne
        
        let newCollection2 = Collections(context: viewContext)
        newCollection2.name = "Collection2"
        newCollection2.canDelete = true
        newCollection2.isSection = false
        newCollection2.parent = sectionOne
        
        let newCollection3 = Collections(context: viewContext)
        newCollection3.name = "Collection3"
        newCollection3.canDelete = true
        newCollection3.isSection = false
        newCollection3.parent = sectionOne
        
        let author1 = Authors(context: viewContext)
        author1.lastname = "Runkel"
        author1.firstname = "Volker"
        
        let author2 = Authors(context: viewContext)
        author2.lastname = "Voigt"
        author2.firstname = "C.C."
        
        let author3 = Authors(context: viewContext)
        author3.lastname = "Scherer"
        author3.firstname = "Cedric"
        
        let article1 = Article(context: viewContext)
        article1.added = Date()
        article1.year = 2022
        article1.authors = [author2, author3, author1]
        article1.title = "Modeling the power of acoustic monitoring to predict bat fatalities at wind turbines"
        var string = ""
        for anAuthor in article1.authors! {
            string.append(", ")
            string.append((anAuthor as! Authors).lastname!)
        }
        
        string.removeFirst(2)
        article1.authorsForDisplay = string
        article1.journal = "Conservation Science and Practice"
        article1.abstract = "Large numbers of bats are killed at wind turbines worldwide. To formulate mitigation measures such as curtailment, recent approaches relate the acoustic activity of bats around reference turbines to casualties to extrapolate fatality rates at turbines where only acoustic surveys are conducted. Here, we modeled how sensitive this approach is when spatial distributions of bats vary within the rotor-swept zone, and when the coverage of acoustic monitoring deteriorates, for example, with increasing turbine size. The predictive power of acoustic surveys was high for uniform or random distributions of bats. A concentration of bat passes around the nacelle or at the lower portion of the risk zone caused an overestimation of bat activity when ultrasonic microphones were pointed downwards at the nacelle. Conversely, a concentration of bat passes at the edge or at the top portion of the risk zone caused an underestimation of bat activity. These effects increased as the coverage of the acoustic monitoring decreased. Extrapolated fatality rates may not necessarily match with real conditions without knowledge of the spatial distribution of bats, particularly when the risk zone is poorly covered by acoustic monitoring, when spatial distributions are skewed and when turbines are large or frequencies of echolocating bats high. We argue that the predictive power of acoustic surveys is sufficiently strong for nonrandom or nonuniform distributions when validated by carcass searches and by complementary studies on the spatial distribution of bats at turbines."
        article1.doi = URL(string: "https://doi.org/10.1111/csp2.12841")
        
        let article2 = Article(context: viewContext)
        article2.added = Date()
        article2.year = 2021
        article2.authors = [author2, author1]
        article2.title = "Limitations of acoustic monitoring at wind turbines to evaluate fatality risk of bats"
        string = ""
        for anAuthor in article2.authors! {
            string.append(", ")
            string.append((anAuthor as! Authors).lastname!)
        }
        string.removeFirst(2)
        article2.authorsForDisplay = string
        article2.journal = "Mammal Review"
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }*/
    
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
