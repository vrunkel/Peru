//
//  AuthorsEditoring.swift
//  Peru
//
//  Created by Volker Runkel on 01.04.23.
//

import SwiftUI
import CoreData
import AQUI

struct AuthorsPopoverContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Authors.lastname, ascending: true)], animation: .default)
    private var authorItems: FetchedResults<Authors>
    
    @Binding var authorsSet: NSOrderedSet
    
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
            HStack(alignment: .bottom) {
                VStack {
                    TextField("Lastname", text: $lastname)
                    TextField("Firstname", text: $firstname)
                    TextField("Middlenames", text: $middlenames)
                }.frame(width: 200)
                    .disabled(self.selectedAuthor == nil)
                Spacer()
                VStack(alignment: .trailing) {
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
            List(selection: $selectedAuthor) {
                ForEach(authorItems, id: \.self) { author in
                    HStack {
                        Text(author.lastname ?? "---")
                        Text(",")
                        Text(author.firstname ?? "---")
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
                self.selectedAuthor!.lastname = self.lastname
                self.selectedAuthor!.firstname = self.firstname
                self.selectedAuthor!.middlenames = self.middlenames
            }
        })
        .frame(minWidth: 250, idealWidth: 250, maxWidth: 300, minHeight: 250, idealHeight: 350, maxHeight: 500, alignment: .leading)
        .padding()
    }
}
