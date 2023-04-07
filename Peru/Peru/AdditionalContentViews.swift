//
//  AdditionalContentViews.swift
//  Peru
//
//  Created by Volker Runkel on 25.03.23.
//

import SwiftUI
import CoreData
import AQUI
import UniformTypeIdentifiers

struct articleDetailsView: View {
    @ObservedObject var article: Article
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    @State var abstractIsExpanded: Bool = false
    @State private var showKeywordsPopover: Bool = false

    var body: some View {
        return GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 10) {
                    Group {
                        Text(article.type ?? "--")
                            .font(.subheadline)
                        Text(((article.authors ?? NSOrderedSet()).array as! [Authors]).map{ $0.lastname ?? "-" }.joined(separator: ", "))
                            .padding(.top, 5)
                        Text(article.title ?? "--")
                            .font(.headline)
                            .padding(.top, 5)
                        Text(article.subtitle ?? "--")
                            .font(.subheadline)
                        
                        Text(article.journal?.name ?? "--")
                            .font(.caption)
                        LazyHStack{
                            Text("vol. " + (article.volume ?? "-"))
                            Text("(" + (article.issue ?? "-") + ")")
                            Text("pages " + (article.pages ?? "-"))
                        }
                        .font(.caption)
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    
                    Spacer()
                    
                    HStack {
                        Button {
                            self.showKeywordsPopover.toggle()
                        } label: {
                            Image(systemName: "tag")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        Text(((article.keywords ?? NSSet()).allObjects as! [Keywords]).map{ $0.keyword ?? "-" }.joined(separator: ", "))
                    }.popover(
                        isPresented: self.$showKeywordsPopover,
                        arrowEdge: .bottom
                    ) { KeywordsPopoverContent(Binding($article.keywords, replacingNilWith: NSSet()))}
                        .padding(.bottom,10)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "text.alignleft")
                        Text(article.abstract ?? "no abstract")
                            .onTapGesture {
                                self.abstractIsExpanded.toggle()
                            }
                            .lineLimit(self.abstractIsExpanded ? nil: 5)
                            .foregroundColor(article.abstract == nil ? Color.gray : Color.primary)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "calendar")
                        Text(article.published ?? Date(), style: .date)
                            .opacity((article.published == nil ? 0.1: 1))
                    }
                    HStack(alignment: .top) {
                        Image(systemName: "link")
                        Text(article.doi?.description ?? "https://doi...")
                    }
                    Spacer()
                }
                .padding(10)
                .frame(width: geometry.size.width)
            }
        }
        .padding(10)
    }
}

struct articleEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Journal.name, ascending: true)], animation: .default)
    private var journals: FetchedResults<Journal>
    
    @ObservedObject var article: Article
    
    @State private var showAuthorsPopover: Bool = false
    @State private var dragging: Authors?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text("Added")
                        .fontWeight(.thin)
                    Text(article.added ?? Date(), style: .date)
                        .fontWeight(.thin)
                }
                TextField("Title", text: Binding($article.title, replacingNilWith: ""), axis: .vertical)
                    .font(.headline)
                    .lineLimit(_:5)
                TextField("Subtitle", text: Binding($article.subtitle, replacingNilWith: ""), axis: .vertical)
                
                DatePicker("Published", selection: Binding($article.published, replacingNilWith: Date()), displayedComponents: [.date])
                    .frame(maxWidth: 180)
                    .opacity((article.published == nil ? 0.33: 1))
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 4)], spacing: 0) {
                    ForEach((article.authors ?? NSOrderedSet()).array as! [Authors],id: \.self) { author in
                        Text(author.lastname ?? "---")
                            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .background(Color.white)
                            .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(.gray, lineWidth: 3)
                                )
                            .cornerRadius(5.0)
                            .lineLimit(1)
                            .onDrag {
                                self.dragging = author
                                return NSItemProvider(object: String(author.objectID.uriRepresentation().absoluteString) as NSString)
                            }
                            .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: author, listData: Binding($article.authors, replacingNilWith: NSOrderedSet()), current: $dragging))
                    }
                    Button {
                        self.showAuthorsPopover = true
                    } label: {
                        Image(systemName: "person.fill.badge.plus")
                    }
                    .popover(
                        isPresented: self.$showAuthorsPopover,
                        arrowEdge: .bottom
                    ) { AuthorsPopoverContent(Binding($article.authors, replacingNilWith: NSOrderedSet()))}
                        .padding(4)
                }.animation(.default, value: article.authors)
                Picker("Journal", selection: $article.journal) {
                    ForEach(journals, id: \.self) { journal in
                        Text(journal.name ?? "---").tag(journal as Journal?)
                    }
                }
                TextField("City", text: Binding($article.city, replacingNilWith: ""))
                Text("Abstract")
                    .font(.caption)
                    .padding(.top)
                ScrollView {
                    TextEditor(text: Binding($article.abstract, replacingNilWith: ""))
                }
                Spacer()
            }
        }.padding()
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: Authors
    @Binding var listData: NSOrderedSet//[Authors]
    @Binding var current: Authors?

    func dropEntered(info: DropInfo) {
        if item != current {
            let to = listData.index(of: item)//listData.firstIndex(of: item)!
            
            if listData[to] as! Authors != current! {
                let mutableSet = NSMutableOrderedSet(orderedSet: listData)
                mutableSet.remove(current as Any)
                mutableSet.insert(current as Any, at: to)
                listData = NSOrderedSet(orderedSet: mutableSet)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}

struct SwiftUIComboBox : NSViewRepresentable {

    typealias NSViewType = NSComboBox

    var content : [String]
    var nbLines : Int
    @Binding var selected : Int

    final class Coordinator : NSObject, NSComboBoxDelegate {

        var selected : Binding<Int>

        init(selected : Binding<Int>) {
            self.selected = selected
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            print ("entering coordinator selection did change")
            if let combo = notification.object as? NSComboBox, selected.wrappedValue != combo.indexOfSelectedItem {
                selected.wrappedValue = combo.indexOfSelectedItem
            }
        }
    }

    func makeCoordinator() -> SwiftUIComboBox.Coordinator {
        return Coordinator(selected: $selected)
    }

    func makeNSView(context: NSViewRepresentableContext<SwiftUIComboBox>) -> NSComboBox {
        let returned = NSComboBox()
        returned.numberOfVisibleItems = nbLines
        returned.hasVerticalScroller = true
        returned.usesDataSource = false
        returned.delegate = context.coordinator // Important : not forget to define delegate
        for key in content {
            returned.addItem(withObjectValue: key)
        }
        return returned
    }

    func updateNSView(_ combo: NSComboBox, context:  NSViewRepresentableContext<SwiftUIComboBox>) {
        if selected != combo.indexOfSelectedItem {
            DispatchQueue.main.async {
                combo.selectItem(at: self.selected)
                print("populating index change \(self.selected) to Combo : \(String(describing: combo.objectValue))")
            }
        }
    }
}
