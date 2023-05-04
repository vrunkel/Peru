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
    
    @Environment(\.openWindow) var openWindow
    
    @ObservedObject var article: Article
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    @State var abstractIsExpanded: Bool = false
    @State private var showKeywordsPopover: Bool = false
    @State private var showCollectionsPopover: Bool = false
    
    var body: some View {
        return GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 10) {
                    Group {
                        Picker("Reference type", selection: Binding($article.type, replacingNilWith: referenceTypes.first!)) {
                            ForEach(referenceTypes, id:\.self) {
                                Text($0).font(.subheadline)
                            }
                        }
                        .font(.subheadline)
                        //Text(article.type ?? "--")
                        //    .font(.subheadline)
                        Text(((article.authors ?? NSOrderedSet()).array as! [Authors]).map{ $0.lastname ?? "-" }.joined(separator: ", "))
                            .padding(.top, 5)
                        Text(article.title ?? "--")
                            .font(.headline)
                            .padding(.top, 5)
                        Text(article.subtitle ?? "--")
                            .font(.subheadline)
                        
                        Text(article.journal?.name ?? "--")
                            .font(.caption)
                        LazyHStack {
                            Text("vol. " + (article.volume ?? "-"))
                            Text("(" + (article.issue ?? "-") + ")")
                            Text("pages " + (article.pages ?? "-"))
                            Spacer()
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
                    
                    HStack {
                        Button {
                            self.showCollectionsPopover.toggle()
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        Text(((article.collections ?? NSSet()).allObjects as! [Collections]).map{ $0.name ?? "-" }.joined(separator: ", "))
                    }.popover(
                        isPresented: self.$showCollectionsPopover,
                        arrowEdge: .bottom
                    ) { CollectionsPopoverContent(Binding($article.collections, replacingNilWith: NSSet()))}
                        .padding(.bottom,10)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "text.alignleft")
                        VStack(alignment: .trailing) {
                            Text(article.abstract ?? "no abstract")
                                .onTapGesture {
                                    self.abstractIsExpanded.toggle()
                                }
                                .lineLimit(self.abstractIsExpanded ? nil: 5)
                                .lineSpacing(4)
                                .foregroundColor(article.abstract == nil ? Color.gray : Color.primary)
                            Button {
                                self.abstractIsExpanded.toggle()
                            } label: {
                                Text(self.abstractIsExpanded ? "Less" : "More...")
                                    .opacity((article.abstract?.count ?? 0) > 0 ? 1 : 0)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "calendar")
                        Text(article.published ?? Date(), style: .date)
                            .opacity((article.published == nil ? 0.1: 1))
                    }
                    HStack(alignment: .top) {
                        Image(systemName: "link")
                        Text(article.doi ?? "https://doi...")
                    }
                    HStack(alignment: .top) {
                        Image(systemName: "doc.text")
                            .onTapGesture {
                                if let _ = article.relatedFile {
                                    openWindow(id: "PDFPreview", value: article.id)
                                }
                            }
                        Text(article.relatedFile?.description ?? "no file linked")
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
    
    @ObservedObject private var autocomplete = AutocompleteObject(journals: [""])
    @State private var newJournalName: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text("Added")
                        .fontWeight(.thin)
                    Text(article.added ?? Date(), style: .date)
                        .fontWeight(.thin)
                }
                Group {
                    TextField("Title", text: Binding($article.title, replacingNilWith: ""), axis: .vertical)
                        .font(.headline)
                        .lineLimit(_:5)
                    TextField("Subtitle", text: Binding($article.subtitle, replacingNilWith: ""), axis: .vertical)
                }
                Divider()
                
                DatePicker("Published", selection: Binding($article.published, replacingNilWith: Date()), displayedComponents: [.date])
                    .frame(maxWidth: 180)
                    .opacity((article.published == nil ? 0.33: 1))
                
                Divider()
                Group {
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
                }
                Group {
                    Divider()
                    Picker("Journal", selection: $article.journal) {
                        ForEach(journals, id: \.self) { journal in
                            Text(journal.name ?? "---").tag(journal as Journal?)
                        }
                    }
                    Group {
                        LazyHStack{
                            TextField("vol. ", text: Binding($article.volume, replacingNilWith: ""))
                            TextField("issue", text: Binding($article.issue, replacingNilWith: ""))
                            TextField("pages", text: Binding($article.pages, replacingNilWith: ""))
                            Text("volume - issue - pages").foregroundColor(Color(NSColor.placeholderTextColor))
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    TextField("Add journal", text: $newJournalName)
                        .disableAutocorrection(true)
                        .onChange(of: newJournalName) { newValue in
                            autocomplete.autocomplete(newJournalName)
                        }
                    Divider()
                }
                Group {
                    TextField("City", text: Binding($article.city, replacingNilWith: ""))
                    TextField("https://doi", text: Binding($article.doi, replacingNilWith: "https://doi"))
                    Text("Abstract")
                        .font(.caption)
                        .padding(.top)
                    ScrollView {
                        TextEditor(text: Binding($article.abstract, replacingNilWith: ""))
                            .lineSpacing(6)
                    }
                    
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
