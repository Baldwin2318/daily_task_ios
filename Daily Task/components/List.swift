//
//  List.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-02-28.
//

import SwiftUI

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
    @State private var showingScanner = false
    @State private var checkboxTapped = false
    @State private var isSharePresented = false
    
    @FocusState private var focusedField: UUID?
    @State private var editingItemID: UUID?
    
    var body: some View {
        NavigationView {
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
                            withAnimation(.easeInOut(duration: 1.0)) {
                                addNewItem()
                            }
                        } label: {
                            Label("Add Task", systemImage: "plus")
                                .font(.headline)
                                .padding()
                                .background(getThemeColorAddButton(taskList.theme ?? "default"))
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
                                    useBulletPoints: taskList.useBulletPoints,
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
                                .listRowBackground(getThemeColor(taskList.theme ?? "default"))
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
                    .background(getThemeColor(taskList.theme ?? "default"))
                    
                    // floating add button to be visible all the time
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    addNewItem()
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(getThemeColorAddButton(taskList.theme ?? "default"))
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
            .sheet(isPresented: $showingCompletedTasksSheet) {
                CompletedTasksSheet(completedTasks: Array(items).filter { $0.isCompleted })
            }
            .sheet(isPresented: $isSharePresented) {
                ShareSheet(items: [generateShareText()])
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView { scannedTexts in
                    // Process the recognized texts.
                    // For example, split each string into lines if needed and add them as tasks.
                    for text in scannedTexts {
                        // Optionally, you can further split text by newlines if one scanned result contains multiple tasks.
                        let tasks = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                        for task in tasks {
                            addScannedTask(text: task)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        shareList()
                    }) {
                        Label("Share List (RAW)", systemImage: "square.and.arrow.up")
                    }
                    
                    // New scanner menu item
                    Button(action: {
                        showingScanner.toggle()
                    }) {
                        Label("Scan Document", systemImage: "doc.text.viewfinder")
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
    }
    // Add the same helper function to ListView:
    private func getThemeColor(_ themeKey: String) -> Color {
        // Define the same theme colors as in NewListView
        let themes = [
            "default": Color.clear,
            "blue": Color.blue.opacity(0.1),
            "green": Color.green.opacity(0.1),
            "pink": Color.pink.opacity(0.1),
            "purple": Color.purple.opacity(0.1),
            "yellow": Color.yellow.opacity(0.1)
        ]
        
        return themes[themeKey] ?? Color.clear
    }
    // Add the same helper function to ListView:
    private func getThemeColorAddButton(_ themeKey: String) -> Color {
        // Define the same theme colors as in NewListView
        let themes = [
            "default": Color.blue,
            "blue": Color.blue,
            "green": Color.green,
            "pink": Color.pink,
            "purple": Color.purple,
            "yellow": Color.yellow,
        ]
        
        return themes[themeKey] ?? Color.blue
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
    private func addScannedTask(text: String) {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.id = UUID()
            newItem.text = text
            newItem.timestamp = Date()
            newItem.isCompleted = false
            newItem.isPriority = false
            newItem.list = taskList
            
            saveContext()
        }
    }
}
