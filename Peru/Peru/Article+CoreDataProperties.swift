//
//  Article+CoreDataProperties.swift
//  Peru
//
//  Created by Volker Runkel on 28.04.23.
//
//

import Foundation
import CoreData


extension Article {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Article> {
        return NSFetchRequest<Article>(entityName: "Article")
    }

    @NSManaged public var abstract: String?
    @NSManaged public var accepted: Date?
    @NSManaged public var added: Date?
    @NSManaged public var citeKey: String?
    @NSManaged public var city: String?
    @NSManaged public var doi: URL?
    @NSManaged public var edition: String?
    @NSManaged public var isbn: String?
    @NSManaged public var issue: String?
    @NSManaged public var pages: String?
    @NSManaged public var published: Date?
    @NSManaged public var publishedBy: String?
    @NSManaged public var relatedFile: URL?
    @NSManaged public var submitted: Date?
    @NSManaged public var subtitle: String?
    @NSManaged public var supplementURI: URL?
    @NSManaged public var title: String?
    @NSManaged public var type: String?
    @NSManaged public var uuid: String?
    @NSManaged public var volume: String?
    @NSManaged public var year: Int16
    @NSManaged public var authorsForDisplay: String?
    @NSManaged public var authors: NSOrderedSet?
    @NSManaged public var collections: NSSet?
    @NSManaged public var editors: NSOrderedSet?
    @NSManaged public var journal: Journal?
    @NSManaged public var keywords: NSSet?
    @NSManaged public var notes: Notes?

}

// MARK: Generated accessors for authors
extension Article {

    @objc(insertObject:inAuthorsAtIndex:)
    @NSManaged public func insertIntoAuthors(_ value: Authors, at idx: Int)

    @objc(removeObjectFromAuthorsAtIndex:)
    @NSManaged public func removeFromAuthors(at idx: Int)

    @objc(insertAuthors:atIndexes:)
    @NSManaged public func insertIntoAuthors(_ values: [Authors], at indexes: NSIndexSet)

    @objc(removeAuthorsAtIndexes:)
    @NSManaged public func removeFromAuthors(at indexes: NSIndexSet)

    @objc(replaceObjectInAuthorsAtIndex:withObject:)
    @NSManaged public func replaceAuthors(at idx: Int, with value: Authors)

    @objc(replaceAuthorsAtIndexes:withAuthors:)
    @NSManaged public func replaceAuthors(at indexes: NSIndexSet, with values: [Authors])

    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: Authors)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: Authors)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSOrderedSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSOrderedSet)

}

// MARK: Generated accessors for collections
extension Article {

    @objc(addCollectionsObject:)
    @NSManaged public func addToCollections(_ value: Collections)

    @objc(removeCollectionsObject:)
    @NSManaged public func removeFromCollections(_ value: Collections)

    @objc(addCollections:)
    @NSManaged public func addToCollections(_ values: NSSet)

    @objc(removeCollections:)
    @NSManaged public func removeFromCollections(_ values: NSSet)

}

// MARK: Generated accessors for editors
extension Article {

    @objc(insertObject:inEditorsAtIndex:)
    @NSManaged public func insertIntoEditors(_ value: Authors, at idx: Int)

    @objc(removeObjectFromEditorsAtIndex:)
    @NSManaged public func removeFromEditors(at idx: Int)

    @objc(insertEditors:atIndexes:)
    @NSManaged public func insertIntoEditors(_ values: [Authors], at indexes: NSIndexSet)

    @objc(removeEditorsAtIndexes:)
    @NSManaged public func removeFromEditors(at indexes: NSIndexSet)

    @objc(replaceObjectInEditorsAtIndex:withObject:)
    @NSManaged public func replaceEditors(at idx: Int, with value: Authors)

    @objc(replaceEditorsAtIndexes:withEditors:)
    @NSManaged public func replaceEditors(at indexes: NSIndexSet, with values: [Authors])

    @objc(addEditorsObject:)
    @NSManaged public func addToEditors(_ value: Authors)

    @objc(removeEditorsObject:)
    @NSManaged public func removeFromEditors(_ value: Authors)

    @objc(addEditors:)
    @NSManaged public func addToEditors(_ values: NSOrderedSet)

    @objc(removeEditors:)
    @NSManaged public func removeFromEditors(_ values: NSOrderedSet)

}

// MARK: Generated accessors for keywords
extension Article {

    @objc(addKeywordsObject:)
    @NSManaged public func addToKeywords(_ value: Keywords)

    @objc(removeKeywordsObject:)
    @NSManaged public func removeFromKeywords(_ value: Keywords)

    @objc(addKeywords:)
    @NSManaged public func addToKeywords(_ values: NSSet)

    @objc(removeKeywords:)
    @NSManaged public func removeFromKeywords(_ values: NSSet)

}
