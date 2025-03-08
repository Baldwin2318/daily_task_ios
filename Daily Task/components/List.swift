//
//  List.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-02-28.
//

import SwiftUI
import CoreData

struct ListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var newItemText: String = ""
    @State private var showingAddItemSheet = false
    @State private var showingCompletedTasksSheet = false // State for completed tasks sheet
    @State private var checkboxTapped = false
    
    // Use this state to track the focused item so that new tasks can become active automatically.
    @FocusState private var focusedItem: Item?

    var body: some View {
        NavigationView {
            if items.isEmpty {
                // Show an empty state with an image and message.
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.secondary)
                    Text("No tasks available.\nTap + to add one!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button {
                        addItem() // Create a new item and set focus.
                    } label: {
                        Label("", systemImage: "plus")
                            .font(.system(size: 25))
                    }
                }
                .onTapGesture {
                    addItem()
                }
            } else {
                List {
                    ForEach(items) { item in
                        HStack {
                            Button(action: {
                                checkboxTapped = true
                                item.isCompleted.toggle()
                                saveContext()
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.square" : "square")
                                    .foregroundColor(item.isCompleted ? .green : .primary)
                                    .simultaneousGesture(TapGesture().onEnded {}) // Prevent tap gesture from interfering
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // Show TextField if the item is focused or its text is empty.
                            if focusedItem == item || (item.text?.isEmpty ?? true) {
                                inlineTextField(for: item)
                            } else {
                                Text(item.text ?? "No Text")
                                    .strikethrough(item.isCompleted, color: .black)
                                    .foregroundColor(item.isCompleted ? .gray : .primary)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationTitle("Checklist")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        // Only show the sweep button if there are any completed tasks.
                        if items.contains(where: { $0.isCompleted }) {
                            Button {
                                showingCompletedTasksSheet = true
                            } label: {
                                Image(systemName: "list.bullet.clipboard")
                                    .renderingMode(.original)
                            }
                        }
                        // Add button is always visible.
                        Button {
                            addItem() // Create a new item and set focus.
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                // Dismiss the keyboard when tapping anywhere in the List background.
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            // Only add an item if the tap was NOT on a checkbox
                            if !checkboxTapped {
                                if focusedItem == nil {
                                    addItem()
                                } else {
                                    if let item = focusedItem, item.text?.isEmpty ?? true {
                                        deleteItem(item)
                                    } else {
                                        saveContext()
                                    }
                                    focusedItem = nil
                                }
                            }
                            checkboxTapped = false // Reset after handling tap
                        }
                )
            }
        }
        // Present the sheet with completed tasks.
        .sheet(isPresented: $showingCompletedTasksSheet) {
            CompletedTasksSheet(completedTasks: Array(items).filter { $0.isCompleted })
        }
    }

    @ViewBuilder
    private func inlineTextField(for item: Item) -> some View {
        TextField("Enter task", text: Binding(
            get: { item.text ?? "" },
            set: { newValue in
                item.text = newValue
            }
        ))
        .focused($focusedItem, equals: item)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .onSubmit {
            if item.text?.isEmpty ?? true {
                deleteItem(item)
            } else {
                saveContext()
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.text = "" // Start with an empty text
            newItem.timestamp = Date()
            newItem.isCompleted = false

            saveContext()
            
            // Optionally, set focus on the new item for immediate editing.
            focusedItem = newItem
        }
    }
    
    private func deleteItem(_ item: Item) {
        withAnimation {
            viewContext.delete(item)
            saveContext()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct CompletedTasksSheet: View {
    let completedTasks: [Item]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            List {
                ForEach(completedTasks) { task in
                    HStack {
                        // Static checkbox image (non-interactive)
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.green)
                        Text(task.text ?? "No Text")
                            .strikethrough(task.isCompleted, color: .black)
                            .foregroundColor(task.isCompleted ? .gray : .primary)
                    }
                }
            }
            .navigationTitle("Completed Tasks")
            .toolbar {
                // Close button.
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") {
//                        dismiss()
//                    }
//                }
                // Circular CLEAN button.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        cleanCompletedTasks()
                        dismiss()
                    }) {
                        Text("CLEAN")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    private func cleanCompletedTasks() {
        withAnimation {
            // Iterate over the completedTasks passed in and delete each one.
            for task in completedTasks {
                viewContext.delete(task)
            }
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately in your app.
                print("Error cleaning tasks: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
