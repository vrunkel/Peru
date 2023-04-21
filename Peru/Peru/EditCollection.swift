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
    
    @ObservedObject var currentCollection: Collections
    
    var body: some View {
        Text("Collection name")
        TextField("New collection", text: Binding($currentCollection.name, replacingNilWith: ""))
            .frame(width: 200)
    }
}
