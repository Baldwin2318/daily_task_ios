//
//  WidgetPersistence.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import CoreData

struct WidgetPersistenceController {
    static let shared = WidgetPersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Daily_Task")
        
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.baldwin.DailyTask")
        let storeURL = containerURL!.appendingPathComponent("Daily_Task.sqlite")
        container.persistentStoreDescriptions.first!.url = storeURL

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("Widget Core Data error: \(error)")
            }
        }
    }
}
