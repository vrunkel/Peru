//
//  Article+CoreDataClass.swift
//  Peru
//
//  Created by Volker Runkel on 28.04.23.
//
//

import Foundation
import CoreData

@objc(Article)
public class Article: NSManagedObject {

    override public func didChangeValue(forKey key: String) {
        if key == "authors" && !self.isDeleted {
            self.willChangeValue(forKey: "authors")
            self.updateAuthorsForDisplay()
        }
        if key == "published" && !self.isDeleted {
            self.updateYear()
        }
        else {
            super.willChangeValue(forKey: key)
        }
    }
    
    func updateAuthorsForDisplay() {
        if self.authors?.count ?? 0 < 1 {
            self.authorsForDisplay = "---"
        } else {
            var string = ""
            if self.authors!.count < 3 {
                for anAuthor in self.authors! {
                    string.append(" & ")
                    string.append((anAuthor as! Authors).lastname!)
                }
                string.removeFirst(3)
                self.authorsForDisplay = string
            } else {
                var string = ""
                string += (self.authors!.firstObject as! Authors).lastname ?? "---"
                string += " et al."
                self.authorsForDisplay = string
            }
        }
    }
    
    func updateYear() {
        if let date = self.published {
            if let year = NSCalendar(identifier: .gregorian)?.component(.year, from: date) {
                self.year = Int16(year)
            }
        }
    }
        
    func articleLongReference() -> String {
        var referenceString = ""
        for anAuthor in self.authors! {
            if !referenceString.isEmpty {
                referenceString.append(", ")
            }
            referenceString.append((anAuthor as! Authors).lastname!)
            referenceString.append(", ")
            referenceString.append((anAuthor as! Authors).firstname ?? "")
        }
        
        referenceString += " (\(self.year))"
        referenceString += ": "
        referenceString += self.title ?? "-"
        referenceString += ". "
        
        if let journal = self.journal {
            referenceString += journal.name ?? "-"
        }
        
        if let doi = self.doi {
            referenceString += ". " + doi
        }
        
        return referenceString
    }
}
