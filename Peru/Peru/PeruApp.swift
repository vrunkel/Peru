//
//  PeruApp.swift
//  Peru
//
//  Created by Volker Runkel on 07.10.22.
//

import SwiftUI

@main
struct PeruApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
    func applicationWillTerminate(_ notification: Notification) {
        try? PersistenceController.shared.container.viewContext.save()
    }
}
