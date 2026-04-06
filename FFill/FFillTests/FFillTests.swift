//
//  FFillTests.swift
//  FFillTests
//
//  Unit tests for FormItem and Folder SwiftData models.
//  Covers: CRUD, relationships, sortOrder.
//

import Testing
import Foundation
import SwiftData
@testable import FFill

// MARK: - Helpers

/// Creates an in-memory ModelContainer for isolated testing.
private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([FormItem.self, Folder.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - FormItem Tests

@Suite("FormItem")
struct FormItemTests {

    @Test("init sets all properties correctly")
    func initProperties() throws {
        let item = FormItem(key: "First Name", value: "John", sortOrder: 2, isRichText: true)
        #expect(item.key == "First Name")
        #expect(item.value == "John")
        #expect(item.sortOrder == 2)
        #expect(item.isRichText == true)
        #expect(item.folder == nil)
    }

    @Test("default sortOrder and isRichText")
    func initDefaults() throws {
        let item = FormItem(key: "Email", value: "a@b.com")
        #expect(item.sortOrder == 0)
        #expect(item.isRichText == false)
    }

    @Test("insert and fetch from context")
    func insertAndFetch() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let item = FormItem(key: "Phone", value: "+1 555 0000")
        context.insert(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>())
        #expect(fetched.count == 1)
        #expect(fetched[0].key == "Phone")
        #expect(fetched[0].value == "+1 555 0000")
    }

    @Test("update persists changes")
    func update() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let item = FormItem(key: "Old Key", value: "Old Value")
        context.insert(item)
        try context.save()

        item.key = "New Key"
        item.value = "New Value"
        item.updatedAt = Date()
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>())
        #expect(fetched[0].key == "New Key")
        #expect(fetched[0].value == "New Value")
    }

    @Test("delete removes item from context")
    func delete() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let item = FormItem(key: "ToDelete", value: "bye")
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>())
        #expect(fetched.isEmpty)
    }

    @Test("sortOrder is preserved after fetch")
    func sortOrderPreserved() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(FormItem(key: "C", value: "", sortOrder: 2))
        context.insert(FormItem(key: "A", value: "", sortOrder: 0))
        context.insert(FormItem(key: "B", value: "", sortOrder: 1))
        try context.save()

        let descriptor = FetchDescriptor<FormItem>(sortBy: [SortDescriptor(\.sortOrder)])
        let fetched = try context.fetch(descriptor)
        #expect(fetched.map(\.key) == ["A", "B", "C"])
    }

    @Test("each item gets a unique id")
    func uniqueIDs() throws {
        let a = FormItem(key: "A", value: "")
        let b = FormItem(key: "B", value: "")
        #expect(a.id != b.id)
    }
}

// MARK: - Folder Tests

@Suite("Folder")
struct FolderTests {

    @Test("init sets all properties correctly")
    func initProperties() throws {
        let folder = Folder(name: "Personal", sortOrder: 1)
        #expect(folder.name == "Personal")
        #expect(folder.sortOrder == 1)
        #expect(folder.items.isEmpty)
    }

    @Test("default sortOrder")
    func initDefaults() throws {
        let folder = Folder(name: "Work")
        #expect(folder.sortOrder == 0)
    }

    @Test("insert and fetch from context")
    func insertAndFetch() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(Folder(name: "Personal"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Folder>())
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "Personal")
    }

    @Test("delete folder nullifies items' folder reference")
    func deleteFolderNullifiesItems() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let folder = Folder(name: "Work")
        let item = FormItem(key: "Work Email", value: "w@w.com")
        item.folder = folder
        context.insert(folder)
        context.insert(item)
        try context.save()

        context.delete(folder)
        try context.save()

        let folders = try context.fetch(FetchDescriptor<Folder>())
        #expect(folders.isEmpty)

        // Item should still exist but with folder set to nil
        let items = try context.fetch(FetchDescriptor<FormItem>())
        #expect(items.count == 1)
        #expect(items[0].folder == nil)
    }

    @Test("folder sortOrder preserved after fetch")
    func sortOrderPreserved() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(Folder(name: "Z", sortOrder: 2))
        context.insert(Folder(name: "A", sortOrder: 0))
        context.insert(Folder(name: "M", sortOrder: 1))
        try context.save()

        let descriptor = FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.sortOrder)])
        let fetched = try context.fetch(descriptor)
        #expect(fetched.map(\.name) == ["A", "M", "Z"])
    }
}

// MARK: - Relationship Tests

@Suite("FormItem-Folder Relationship")
struct RelationshipTests {

    @Test("assigning folder creates relationship")
    func assignFolder() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let folder = Folder(name: "Personal")
        let item = FormItem(key: "Address", value: "123 Main St")
        item.folder = folder
        context.insert(folder)
        context.insert(item)
        try context.save()

        let fetchedItems = try context.fetch(FetchDescriptor<FormItem>())
        #expect(fetchedItems[0].folder?.name == "Personal")

        let fetchedFolders = try context.fetch(FetchDescriptor<Folder>())
        #expect(fetchedFolders[0].items.count == 1)
        #expect(fetchedFolders[0].items[0].key == "Address")
    }

    @Test("multiple items can belong to the same folder")
    func multipleItemsInFolder() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let folder = Folder(name: "Work")
        let item1 = FormItem(key: "Work Email", value: "a@work.com", sortOrder: 0)
        let item2 = FormItem(key: "Work Phone", value: "+1 555 0001", sortOrder: 1)
        item1.folder = folder
        item2.folder = folder
        context.insert(folder)
        context.insert(item1)
        context.insert(item2)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Folder>())
        #expect(fetched[0].items.count == 2)
    }

    @Test("item can be moved from one folder to another")
    func moveItemBetweenFolders() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let personal = Folder(name: "Personal")
        let work = Folder(name: "Work")
        let item = FormItem(key: "Email", value: "me@me.com")
        item.folder = personal
        context.insert(personal)
        context.insert(work)
        context.insert(item)
        try context.save()

        item.folder = work
        try context.save()

        let fetchedItem = try context.fetch(FetchDescriptor<FormItem>())
        #expect(fetchedItem[0].folder?.name == "Work")
    }

    @Test("item folder can be set to nil (unassigned)")
    func unassignFolder() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let folder = Folder(name: "Personal")
        let item = FormItem(key: "Name", value: "John")
        item.folder = folder
        context.insert(folder)
        context.insert(item)
        try context.save()

        item.folder = nil
        try context.save()

        let fetchedItem = try context.fetch(FetchDescriptor<FormItem>())
        #expect(fetchedItem[0].folder == nil)
    }
}
