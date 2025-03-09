//
//  List.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-02-28.
//

import SwiftUI
import CoreData
import UIKit

struct ListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var taskList: TaskList
    
    @FetchRequest var items: FetchedResults<Item>
    
    init(taskList: TaskList) {
        self.taskList = taskList
        // Updated fetch request to sort by priority first, then timestamp
        _items = FetchRequest<Item>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Item.isPriority, ascending: false),
                NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)
            ],
            predicate: NSPredicate(format: "list == %@", taskList),
            animation: .default
        )
    }
    
    @State private var showingCompletedTasksSheet = false
    @State private var checkboxTapped = false
    @State private var isSharePresented = false
    
    @FocusState private var focusedField: UUID?
    @State private var editingItemID: UUID?
    
    var body: some View {
        ZStack {
            if items.isEmpty {
                // Empty state view
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.secondary)
                    Text("No tasks available.\nTap + to add one!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button {
                        addNewItem()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                // Main list view with tasks
                VStack {
                    List {
                        ForEach(items) { item in
                            TaskRow(
                                item: item,
                                isEditing: editingItemID == item.id,
                                focusedField: $focusedField,
                                onToggleComplete: { toggleItemComplete(item) },
                                onStartEditing: { startEditing(item) },
                                onEditingChanged: { newText in
                                    item.text = newText
                                    saveContext()
                                },
                                onEndEditing: { endEditing() }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Delete action
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Priority action
                                Button {
                                    togglePriority(item)
                                } label: {
                                    Label(
                                        item.isPriority ? "Remove Priority" : "Prioritize",
                                        systemImage: "flag"
                                    )
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(
                        // Background tap detector to end editing
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if editingItemID != nil {
                                    endEditing()
                                }
                            }
                    )
                }
                
                // floating add button to be visible all the time
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            addNewItem()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle(taskList.name ?? "Checklist")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        shareList()
                    }) {
                        Label("Copy & Share List", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        // Reset priorities
                        resetAllPriorities()
                    }) {
                        Label("Reset Priorities", systemImage: "flag.slash")
                    }
                    
                    Button(role: .destructive, action: {
                        // Delete all completed tasks
                        deleteCompletedTasks()
                    }) {
                        Label("Delete Completed", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                }
            }
        }
        .sheet(isPresented: $showingCompletedTasksSheet) {
            CompletedTasksSheet(completedTasks: Array(items).filter { $0.isCompleted })
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    private func shareList() {
        // Share list immediately without needing to capture an image
        self.isSharePresented = true
    }
    
    // Generate a text representation of the list for sharing
    private func generateShareText() -> String {
        let title = taskList.name ?? "Checklist"
        var shareText = "\(title):\n"
        
        let priorityItems = items.filter { $0.isPriority && !$0.isCompleted }
        let regularItems = items.filter { !$0.isPriority && !$0.isCompleted }
        let completedItems = items.filter { $0.isCompleted }
        
        // Add priority tasks
        if !priorityItems.isEmpty {
            shareText += "PRIORITY TASKS ⭐️:\n"
            for item in priorityItems {
                shareText += "• \(item.text ?? "Task")\n"
            }
            shareText += "\n"
        }
        
        // Add regular tasks
        if !regularItems.isEmpty {
//            shareText += "TASKS:\n"
            for item in regularItems {
                shareText += "• \(item.text ?? "Task")\n"
            }
            shareText += "\n"
        }
        
        // Add completed tasks
        if !completedItems.isEmpty {
            shareText += "COMPLETED ✅ :\n"
            for item in completedItems {
                shareText += "• \(item.text ?? "Task")\n"
            }
        }
        
        return shareText
    }
    
    private func addNewItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.id = UUID()
            newItem.text = ""
            newItem.timestamp = Date()
            newItem.isCompleted = false
            newItem.isPriority = false // Initialize as not priority
            newItem.list = taskList
            
            saveContext()
            
            // Set focus to the new item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.editingItemID = newItem.id
                self.focusedField = newItem.id
            }
        }
    }
    
    private func toggleItemComplete(_ item: Item) {
        withAnimation {
            item.isCompleted.toggle()
            saveContext()
        }
    }
    
    private func togglePriority(_ item: Item) {
        withAnimation {
            item.isPriority.toggle()
            saveContext()
        }
    }
    
    private func startEditing(_ item: Item) {
        editingItemID = item.id
        focusedField = item.id
    }
    
    private func endEditing() {
        editingItemID = nil
        focusedField = nil
        saveContext()
    }
    
    private func deleteItem(_ item: Item) {
        withAnimation {
            viewContext.delete(item)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func resetAllPriorities() {
        withAnimation {
            for item in items {
                if item.isPriority {
                    item.isPriority = false
                }
            }
            saveContext()
        }
    }
      
    private func deleteCompletedTasks() {
        withAnimation {
            let completedItems = items.filter { $0.isCompleted }
            for item in completedItems {
                viewContext.delete(item)
            }
            saveContext()
        }
    }
}

// ShareSheet to present the UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to do here
    }
}

// Updated TaskRow to show priority status
struct TaskRow: View {
    let item: Item
    let isEditing: Bool
    var focusedField: FocusState<UUID?>.Binding
    let onToggleComplete: () -> Void
    let onStartEditing: () -> Void
    let onEditingChanged: (String) -> Void
    let onEndEditing: () -> Void
    
    @State private var text: String = ""
    
    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button(action: onToggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .primary)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Task content - either text field or text
            if isEditing {
                TextField("Enter task", text: $text)
                    .font(.system(size: 20))
                    .padding(.vertical, 8)
                    .focused(focusedField, equals: item.id)
                    .onAppear {
                        text = item.text ?? ""
                    }
                    .onChange(of: text) { newValue in
                        onEditingChanged(newValue)
                    }
                    .onSubmit {
                        if text.isEmpty {
                            // Delete empty tasks
                            deleteEmptyItem()
                        } else {
                            onEndEditing()
                        }
                    }
            } else {
                Text(item.text ?? "New Task")
                    .font(.system(size: 20))
                    .strikethrough(item.isCompleted, color: .black)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !item.isCompleted {
                            onStartEditing()
                        }
                    }
            }
            
            // Priority flag (if prioritized)
            if item.isPriority {
                Image(systemName: "flag.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }
            
        }
        .padding(.horizontal, 4)
        .background(
            item.isPriority ?
                Color.orange.opacity(0.1) :
                Color.clear
        )
        .cornerRadius(6)
    }
    
    private func deleteEmptyItem() {
        if let context = item.managedObjectContext {
            context.delete(item)
            do {
                try context.save()
            } catch {
                print("Error deleting empty item: \(error)")
            }
        }
    }
}

// Keep the CompletedTasksSheet unchanged
struct CompletedTasksSheet: View {
    let completedTasks: [Item]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            List {
                ForEach(completedTasks) { task in
                    HStack {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        cleanCompletedTasks()
                        dismiss()
                    }) {
                        Text("CLEAN ALL")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    private func cleanCompletedTasks() {
        withAnimation {
            for task in completedTasks {
                viewContext.delete(task)
            }
            do {
                try viewContext.save()
            } catch {
                print("Error cleaning tasks: \(error.localizedDescription)")
            }
        }
    }
}
