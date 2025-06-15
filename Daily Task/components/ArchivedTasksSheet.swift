//
//  ArchivedTasksSheet.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-15.
//

import SwiftUI
import CoreData

struct ArchivedTasksSheet: View {
    var taskList: TaskList
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest var archivedTasks: FetchedResults<Item>

    init(taskList: TaskList) {
        self.taskList = taskList
        _archivedTasks = FetchRequest<Item>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
            predicate: NSPredicate(format: "list == %@ AND isArchived == YES", taskList),
            animation: .default
        )
    }

    var body: some View {
        NavigationView {
            if archivedTasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.secondary)
                    Text("No recently deleted items!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Recently Deleted")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            } else {
                List {
                    ForEach(archivedTasks) { task in
                        Text(task.text ?? "Untitled Task")
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Recover") {
                                    unarchiveTask(task)
                                }
                                .tint(.green)
                                Button(role: .destructive, action: {
                                    deleteArchivedItem(task)
                                }) {
                                    Text("Permanently Delete")
                                }
                            }
                    }
                    .onDelete { indices in
                        for index in indices {
                            deleteArchivedItem(archivedTasks[index])
                        }
                    }
                }
                .navigationTitle("Recently Deleted")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Recover All") {
                            unarchiveAll()
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func deleteArchivedItem(_ item: Item) {
        viewContext.delete(item)
        saveContext()
    }

    private func unarchiveAll() {
        for task in archivedTasks {
            task.isArchived = false
        }
        saveContext()
    }
    
    private func unarchiveTask(_ item: Item) {
        item.isArchived = false
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Failed saving context: \(nsError), \(nsError.userInfo)")
        }
    }
}
