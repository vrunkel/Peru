//
//  AuthorsEditoring.swift
//  Peru
//
//  Created by Volker Runkel on 01.04.23.
//

import SwiftUI
import CoreData
import AQUI
import UniformTypeIdentifiers

struct AuthorsPopoverContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Authors.lastname, ascending: true)], animation: .default)
    private var authorItems: FetchedResults<Authors>
    
    @Binding var authorsSet: NSOrderedSet
    @State private var dragging: Authors?
    
    init(_ authorsSet: Binding<NSOrderedSet>) {
        self._authorsSet = authorsSet
    }
    
    @State private var selectedAuthor: Authors?
    
    @State var lastname: String = ""
    @State var firstname: String = ""
    @State var middlenames: String = ""
    
    @State private var isOn = false
    
    var anyOfMultiple: [String] {[
        lastname,
        firstname,
        middlenames
    ]}
    
    func getToggleState(author: Authors) -> Binding<Bool> {
        return Binding(get: {self.authorsSet.contains(author)}, set: {
            if $0 {
                let newSet = NSMutableOrderedSet(orderedSet: self.authorsSet)
                newSet.add(author)
                self.authorsSet = NSOrderedSet(orderedSet: newSet)
            } else {
                let newSet = NSMutableOrderedSet(orderedSet: self.authorsSet)
                newSet.remove(author)
                self.authorsSet = NSOrderedSet(orderedSet: newSet)
            }
        })
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Edit authors")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            HStack(alignment: .top) {
                VStack {
                    TextField("Lastname", text: $lastname)
                    TextField("Firstname", text: $firstname)
                    TextField("Middlenames", text: $middlenames)
                    Text("Article count \(self.selectedAuthor?.items?.count ?? 0)")
                        .foregroundColor(.gray)
                        .opacity(self.selectedAuthor == nil ? 0:1)
                }.frame(width: 200)
                    .disabled(self.selectedAuthor == nil)
                Spacer()
                VStack(alignment: .trailing) {
                    Button {
                        if self.selectedAuthor != nil {
                            self.selectedAuthor!.lastname = self.selectedAuthor!.lastname?.localizedCapitalized ?? ""
                            self.selectedAuthor!.firstname = self.selectedAuthor!.firstname?.localizedCapitalized ?? ""
                            
                            if self.selectedAuthor!.items?.count ?? 0 > 0 {
                                for anArticle in self.selectedAuthor!.items! {
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
                        self.selectedAuthor = author
                    } label: {
                        Image(systemName: "plus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                    Button {
                        viewContext.delete(self.selectedAuthor!)
                        self.selectedAuthor = nil
                    } label: {
                        Image(systemName: "minus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                        .disabled(self.selectedAuthor == nil)
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 4)], spacing: 0) {
                ForEach((authorsSet).array as! [Authors],id: \.self) { author in
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
                        .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: author, listData: $authorsSet, current: $dragging))
                        .onTapGesture {
                            self.selectedAuthor = author
                        }
                }
                .padding(4)
            }.animation(.default, value:authorsSet)
            if authorItems.count > 0 {
                ScrollViewReader { proxy in
                    
                    List(selection: $selectedAuthor) {
                        ForEach(authorItems, id: \.self) { author in
                            HStack {
                                Text(author.lastname ?? "---")
                                Text(",")
                                Text(author.firstname ?? "")
                                Spacer()
                                Toggle(isOn: getToggleState(author: author)) {
                                }
                                .toggleStyle(.checkbox)
                            }
                        }
                    }.onChange(of: selectedAuthor) { newValue in
                        if self.selectedAuthor != nil {
                            self.lastname = self.selectedAuthor?.lastname ?? ""
                            self.firstname = self.selectedAuthor?.firstname ?? ""
                            self.middlenames = self.selectedAuthor?.middlenames ?? ""
                            proxy.scrollTo(self.selectedAuthor!, anchor: .center)
                        }
                        else {
                            self.lastname = ""
                            self.firstname = ""
                            self.middlenames = ""
                        }
                    }
                }
            }
            else {
                Text("You still need to create your first author in this database - go ahead and use the small + sign just above here!")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .onChange(of: anyOfMultiple, perform: { newValue in
            if self.selectedAuthor != nil {
                self.selectedAuthor!.lastname = self.lastname
                self.selectedAuthor!.firstname = self.firstname
                self.selectedAuthor!.middlenames = self.middlenames
            }
        })
        .frame(minWidth: 250, idealWidth: 250, maxWidth: 300, minHeight: 350, idealHeight: 550, maxHeight: 700, alignment: .leading)
        .padding()
    }
}
