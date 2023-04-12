//
//  EditCollection.swift
//  Peru
//
//  Created by Volker Runkel on 10.04.23.
//

import SwiftUI
import CoreData
import AQUI
import WrappingHStack
import UniformTypeIdentifiers

struct EditCollectionsPopoverContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var currentCollection: Collections
    
    init(_ inputCollection: Binding<Collections>) {
        self._currentCollection = inputCollection
    }
    
    var body: some View {
        Text("Edit collection")
        TextField("New collection", text: Binding($currentCollection.name,replacingNilWith: ""))
    }
}
