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
        if key == "authors" && !self.isDeleted{
            self.willChangeValue(forKey: "authors")
            self.updateAuthorsForDisplay()
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
            for anAuthor in self.authors! {
                string.append(", ")
                string.append((anAuthor as! Authors).lastname!)
            }
            string.removeFirst(2)
            self.authorsForDisplay = string
        }
    }
}
