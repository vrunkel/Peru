//
//  PeruCommands.swift
//  Peru
//
//  Created by Volker Runkel on 25.04.23.
//

import SwiftUI

struct PeruCommands: Commands {
    
    @Environment(\.openWindow) var openWindow
    
    var body: some Commands {
        SidebarCommands()
        CommandGroup(after: .windowList) {
            Divider()
            Button("Show author list") {
                openWindow(id: "Authors")
            }
            Button("Show journal list") {
                openWindow(id: "Journals")
            }
        }
    }
}
