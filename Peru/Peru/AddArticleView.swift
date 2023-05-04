//
//  AddArticleView.swift
//  Peru
//
//  Created by Volker Runkel on 29.04.23.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddArticleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Journal.name, ascending: true)], animation: .default)
    private var journals: FetchedResults<Journal>
    
    @ObservedObject var article: Article
    @ObservedObject private var autocomplete = AutocompleteObject(journals: [""])
    
    @State private var showAuthorsPopover: Bool = false
    @State private var dragging: Authors?
    
    @State private var newJournalName: String = ""
    
    @FocusState private var isAbstractFocused: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                Group {
                    Picker("Reference type", selection: Binding($article.type, replacingNilWith: referenceTypes.first!)) {
                        ForEach(referenceTypes, id:\.self) {
                            Text($0).font(.subheadline)
                        }
                    }
                    .font(.subheadline)
                    TextField("Title", text: Binding($article.title, replacingNilWith: ""), axis: .vertical)
                        .font(.headline)
                        .lineLimit(_:5)
                    TextField("Subtitle", text: Binding($article.subtitle, replacingNilWith: ""), axis: .vertical)
                }
                
                DatePicker("Published", selection: Binding($article.published, replacingNilWith: Date()), displayedComponents: [.date])
                    .frame(maxWidth: 180)
                    .opacity((article.published == nil ? 0.33: 1))
                Divider()
                if article.authors?.count ?? 0 > 0 {
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
                    }
                }
                else {
                    Text("Add existing authors from the left - or add new authors on the left")
                        .foregroundColor(Color(NSColor.placeholderTextColor))
                }
                Group {
                    Divider()
                    Text("Choose a journal from the picker or type a name to add a new journal or select from list")
                        .foregroundColor(Color(NSColor.placeholderTextColor))
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
                    HStack {
                        TextField("Search or add journal", text: $newJournalName)
                            .disableAutocorrection(true)
                            .onChange(of: newJournalName) { newValue in
                                autocomplete.autocomplete(newJournalName)
                            }
                        Spacer()
                        Button {
                            if !newJournalName.isEmpty {
                                let newJournal = Journal(context: context)
                                newJournal.name = newJournalName
                                article.journal = newJournal
                                newJournalName = ""
                            }
                        } label: {
                            Image(systemName: "plus.rectangle.portrait.fill")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    List(autocomplete.suggestions, id: \.self) { suggestion in
                        ZStack {
                            Text(suggestion)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .onTapGesture {
                            newJournalName = suggestion
                        }
                    }
                    Divider()
                }
                
                TextField("City", text: Binding($article.city, replacingNilWith: ""))
                TextField("https://doi", text: Binding($article.doi, replacingNilWith: "https://doi"))
                Text("Abstract")
                    .font(.caption)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: Binding($article.abstract, replacingNilWith: ""))
                            .lineSpacing(6)
                            .focused($isAbstractFocused)
                        if !isAbstractFocused && (article.abstract?.isEmpty ?? true) {
                            Text("Enter abstract here")
                                .foregroundColor(Color(NSColor.placeholderTextColor))
                                .padding(.top, 10)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            AuthorsPopoverContent(Binding($article.authors, replacingNilWith: NSOrderedSet()))
        }
        .toolbar {
            Button("Cancel") {
                /*context.perform {
                 context.rollback()
                 }*/
                dismiss()
            }
        }
        .toolbar {
            Button("Save") {
                if article.title == nil {
                    article.title = ""
                }
                if article.authorsForDisplay?.count ?? 0 < 1 {
                    article.authorsForDisplay = "---"
                }
                context.perform {
                    try? context.save()
                }
                dismiss()
            }
        }
        .padding(20)
        .onAppear {
            self.autocomplete.reloadCache(journals: journals.map{ $0.name ?? "" })
        }
    }
}
