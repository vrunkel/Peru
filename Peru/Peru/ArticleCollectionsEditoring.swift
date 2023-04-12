//
//  EditingArticleCollections.swift
//  Peru
//
//  Created by Volker Runkel on 11.04.23.
//

import SwiftUI
import CoreData
import AQUI
import WrappingHStack
import UniformTypeIdentifiers

struct CollectionsPopoverContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collections.name, ascending: true)], predicate: NSPredicate(format: "parent.type == %d", 0), animation: .default)
    
    private var collectionItems: FetchedResults<Collections>
    
    @Binding var collectionsSet: NSSet
    
    init(_ collectionsSet: Binding<NSSet>) {
        self._collectionsSet = collectionsSet
    }
    
    @State private var isOn = false
    
    func getToggleState(collection: Collections) -> Binding<Bool> {
        return Binding(get: {self.collectionsSet.contains(collection)}, set: {
            if $0 {
                let newSet = NSMutableSet(set: self.collectionsSet)
                newSet.add(collection)
                self.collectionsSet = NSSet(set: newSet)
            } else {
                let newSet = NSMutableSet(set: self.collectionsSet)
                newSet.remove(collection)
                self.collectionsSet = NSSet(set: newSet)
            }
        })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Article collections")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            WrappingHStack(collectionsSet.allObjects as! [Collections],id: \.self,  alignment: .leading, spacing: .constant(0)) {
                Text($0.name ?? "---")
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.gray, lineWidth: 3)
                    )
            }
            
            ScrollViewReader { proxy in
                List() {
                    ForEach(collectionItems, id: \.self) { collection in
                        HStack {
                            Text(collection.name ?? "---")
                            Spacer()
                            Toggle(isOn: getToggleState(collection: collection)) {
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 250, idealWidth: 250, maxWidth: 300, minHeight: 250, idealHeight: 350, maxHeight: 500, alignment: .leading)
        .padding()
    }
    
}
