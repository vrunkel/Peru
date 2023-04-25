//
//  PeruApp.swift
//  Peru
//
//  Created by Volker Runkel on 07.10.22.
//

import SwiftUI
import PDFKit

@main

struct PeruApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.appSupportPDFs, AppSupportPDFURL.defaultValue)
                .frame(minWidth: 1280, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
        }
        WindowGroup(id: "PDFPreview", for: URL.self) { $pdfURL in
            if let url = pdfURL, let pdfDocument = PDFDocument(url: url) {
                PDFPreview(pdfDocument: pdfDocument)
                    .frame(minWidth: 800, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
            }
        }
    }
}

private struct AppSupportPDFURL: EnvironmentKey {
    static let defaultValue: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("de.ecoObs.Peru").appendingPathComponent("PDFs")
}

extension EnvironmentValues {
    var appSupportPDFs: URL {
        get { self[AppSupportPDFURL.self] }
        set { self[AppSupportPDFURL.self] = newValue }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows" : false])
        
        if !FileManager.default.fileExists(atPath: AppSupportPDFURL.defaultValue.path) {
            self.createAppSupportFolder()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        try? PersistenceController.shared.container.viewContext.save()
    }
    
    func createAppSupportFolder() {
        do
        {
          //  Find Application Support directory
          let fileManager = FileManager.default
          let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
          //  Create subdirectory
          let directoryURL = appSupportURL.appendingPathComponent("de.ecoObs.Peru")
          try fileManager.createDirectory (at: directoryURL, withIntermediateDirectories: true, attributes: nil)
         //  Create pdf rep
          let pdfURL = directoryURL.appendingPathComponent ("PDFs")
            try fileManager.createDirectory (at: pdfURL, withIntermediateDirectories: true, attributes: nil)
        }
        catch
        {
          print("An error occured")
        }
    }
}
