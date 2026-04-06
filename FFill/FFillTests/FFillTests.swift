//
//  FFillTests.swift
//  FFillTests
//
//  Unit tests for FormItem and Folder SwiftData models.
//  Covers: CRUD, relationships, sortOrder, drag-and-drop reordering.
//

import Testing
import Foundation
import SwiftUI
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

// MARK: - ExtensionDataService Tests

@Suite("ExtensionDataService")
struct ExtensionDataServiceTests {

    @Test("empty store returns empty arrays")
    func emptyStore() throws {
        let container = try makeTestContainer()
        let payload = try ExtensionDataService.buildResponsePayload(using: container)

        let items = try #require(payload["items"] as? [[String: Any]])
        let folders = try #require(payload["folders"] as? [[String: Any]])
        #expect(items.isEmpty)
        #expect(folders.isEmpty)
    }

    @Test("ungrouped items serialised without folderId key")
    func ungroupedItemsHaveNoFolderIdKey() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(FormItem(key: "First Name", value: "John", sortOrder: 0))
        context.insert(FormItem(key: "Email", value: "john@example.com", sortOrder: 1))
        try context.save()

        let payload = try ExtensionDataService.buildResponsePayload(using: container)
        let items = try #require(payload["items"] as? [[String: Any]])

        #expect(items.count == 2)
        // Ungrouped items must NOT have a folderId key at all
        #expect(items[0]["folderId"] == nil)
        #expect(items[1]["folderId"] == nil)
        #expect(items[0]["key"] as? String == "First Name")
        #expect(items[1]["key"] as? String == "Email")
    }

    @Test("items are returned sorted by sortOrder")
    func itemsSortedBySortOrder() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(FormItem(key: "C", value: "", sortOrder: 2))
        context.insert(FormItem(key: "A", value: "", sortOrder: 0))
        context.insert(FormItem(key: "B", value: "", sortOrder: 1))
        try context.save()

        let payload = try ExtensionDataService.buildResponsePayload(using: container)
        let items = try #require(payload["items"] as? [[String: Any]])

        #expect(items.map { $0["key"] as? String } == ["A", "B", "C"])
    }

    @Test("folder item with assigned folder includes folderId")
    func assignedItemIncludesFolderId() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let folder = Folder(name: "Work", sortOrder: 0)
        let item = FormItem(key: "Work Email", value: "w@work.com", sortOrder: 0)
        item.folder = folder
        context.insert(folder)
        context.insert(item)
        try context.save()

        let payload = try ExtensionDataService.buildResponsePayload(using: container)
        let items = try #require(payload["items"] as? [[String: Any]])
        let folders = try #require(payload["folders"] as? [[String: Any]])

        #expect(items.count == 1)
        let folderId = try #require(items[0]["folderId"] as? String)
        #expect(folderId == folder.id.uuidString)

        #expect(folders.count == 1)
        #expect(folders[0]["name"] as? String == "Work")
        let itemIds = try #require(folders[0]["itemIds"] as? [String])
        #expect(itemIds == [item.id.uuidString])
    }

    @Test("folder itemIds are in sortOrder")
    func folderItemIdsAreSorted() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let folder = Folder(name: "Personal", sortOrder: 0)
        let item0 = FormItem(key: "A", value: "", sortOrder: 0)
        let item1 = FormItem(key: "B", value: "", sortOrder: 1)
        let item2 = FormItem(key: "C", value: "", sortOrder: 2)
        item0.folder = folder
        item1.folder = folder
        item2.folder = folder
        context.insert(folder)
        [item0, item1, item2].forEach { context.insert($0) }
        try context.save()

        let payload = try ExtensionDataService.buildResponsePayload(using: container)
        let folders = try #require(payload["folders"] as? [[String: Any]])
        let itemIds = try #require(folders[0]["itemIds"] as? [String])

        #expect(itemIds == [item0.id.uuidString, item1.id.uuidString, item2.id.uuidString])
    }

    @Test("multiple folders returned sorted by sortOrder")
    func foldersSortedBySortOrder() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        context.insert(Folder(name: "Z", sortOrder: 2))
        context.insert(Folder(name: "A", sortOrder: 0))
        context.insert(Folder(name: "M", sortOrder: 1))
        try context.save()

        let payload = try ExtensionDataService.buildResponsePayload(using: container)
        let folders = try #require(payload["folders"] as? [[String: Any]])

        #expect(folders.map { $0["name"] as? String } == ["A", "M", "Z"])
    }
}

// MARK: - SortOrder Reordering Tests

/// Mirrors the move logic used in FormDataListView, FolderListView, and FolderDetailView.
private func applyMove<T: AnyObject & Identifiable>(
    to array: inout [T],
    from source: IndexSet,
    to destination: Int,
    updateSortOrder: (T, Int) -> Void
) {
    array.move(fromOffsets: source, toOffset: destination)
    for (index, item) in array.enumerated() {
        updateSortOrder(item, index)
    }
}

@Suite("SortOrder Reordering")
struct SortOrderReorderingTests {

    // MARK: FormItem reordering

    @Test("move first item to last — sortOrders reassigned correctly")
    func moveFirstToLast() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let a = FormItem(key: "A", value: "", sortOrder: 0)
        let b = FormItem(key: "B", value: "", sortOrder: 1)
        let c = FormItem(key: "C", value: "", sortOrder: 2)
        [a, b, c].forEach { context.insert($0) }
        try context.save()

        var list = [a, b, c]
        applyMove(to: &list, from: IndexSet(integer: 0), to: 3) { $0.sortOrder = $1 }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(fetched.map(\.key) == ["B", "C", "A"])
        #expect(fetched.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("move last item to first — sortOrders reassigned correctly")
    func moveLastToFirst() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let a = FormItem(key: "A", value: "", sortOrder: 0)
        let b = FormItem(key: "B", value: "", sortOrder: 1)
        let c = FormItem(key: "C", value: "", sortOrder: 2)
        [a, b, c].forEach { context.insert($0) }
        try context.save()

        var list = [a, b, c]
        applyMove(to: &list, from: IndexSet(integer: 2), to: 0) { $0.sortOrder = $1 }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(fetched.map(\.key) == ["C", "A", "B"])
        #expect(fetched.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("move middle item up — sortOrders reassigned correctly")
    func moveMiddleUp() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let a = FormItem(key: "A", value: "", sortOrder: 0)
        let b = FormItem(key: "B", value: "", sortOrder: 1)
        let c = FormItem(key: "C", value: "", sortOrder: 2)
        [a, b, c].forEach { context.insert($0) }
        try context.save()

        var list = [a, b, c]
        applyMove(to: &list, from: IndexSet(integer: 1), to: 0) { $0.sortOrder = $1 }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(fetched.map(\.key) == ["B", "A", "C"])
        #expect(fetched.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("sortOrders are always contiguous after move")
    func sortOrdersAreContiguous() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let items = (0..<5).map { i in
            let item = FormItem(key: "\(i)", value: "", sortOrder: i)
            context.insert(item)
            return item
        }
        try context.save()

        var list = items
        applyMove(to: &list, from: IndexSet(integer: 4), to: 1) { $0.sortOrder = $1 }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FormItem>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(fetched.map(\.sortOrder) == [0, 1, 2, 3, 4])
    }

    // MARK: Folder reordering

    @Test("folders reordered — sortOrders reassigned correctly")
    func foldersReordered() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let work = Folder(name: "Work", sortOrder: 0)
        let personal = Folder(name: "Personal", sortOrder: 1)
        let other = Folder(name: "Other", sortOrder: 2)
        [work, personal, other].forEach { context.insert($0) }
        try context.save()

        var list = [work, personal, other]
        applyMove(to: &list, from: IndexSet(integer: 2), to: 0) { $0.sortOrder = $1 }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(fetched.map(\.name) == ["Other", "Work", "Personal"])
        #expect(fetched.map(\.sortOrder) == [0, 1, 2])
    }
}
