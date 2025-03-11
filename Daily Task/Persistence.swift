//
//  Persistence.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-02-28.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // Use NSPersistentCloudKitContainer instead of NSPersistentContainer
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Replace "Daily_Task" with your data model name if different
        container = NSPersistentCloudKitContainer(name: "Daily_Task")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure the persistent store for CloudKit syncing:
        if let description = container.persistentStoreDescriptions.first {
            // Enable history tracking and remote change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // Optionally, you can set a CloudKit container identifier if needed:
            // description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourcompany.DailyTask")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Automatically merge changes from CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
