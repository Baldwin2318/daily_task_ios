//
//  Persistence.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-02-28.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

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
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.Baldwin.Daily-Task")
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
