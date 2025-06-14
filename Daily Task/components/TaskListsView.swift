//
//  TaskListsView.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore
import SwiftUI
import CoreData


struct TaskListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var taskLists: FetchedResults<TaskList>
    @Binding var selectedTaskList: TaskList?
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingNewListPrompt = false
    @State private var isShowingEditListPrompt = false
    @State private var newListName = ""
    
    // State variables for delete confirmation (single deletion)
    @State private var showingDeleteAlert = false
    @State private var listToDelete: TaskList? = nil
    @State private var editingTaskList: TaskList? = nil

    // New state for selection mode:
    @State private var isSelectionMode = false
    @State private var selectedListIDs = Set<NSManagedObjectID>()
    
    // Define grid columns (two columns in this example)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // "Add New List" cell remains at the start (only if not in selection mode)
                    if !isSelectionMode {
                        Button(action: {
                            isShowingNewListPrompt = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundColor(.gray)
                                Image(systemName: "plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 100)
                        }
                        .transition(.scale) // Animate with a scaling transition
                    }
                    
                    ForEach(taskLists, id: \.self) { list in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getThemeColor(list.theme ?? "default"))
                            VStack {
                                Text(list.name ?? "Unnamed List")
                                    .font(.headline)
                                    .padding()
                            }
                            // If in selection mode, overlay a checkmark indicator:
                            if isSelectionMode {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: selectedListIDs.contains(list.objectID) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedListIDs.contains(list.objectID) ? .blue : .gray)
                                            .padding(6)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(height: 100)
                        .onTapGesture {
                            if isSelectionMode {
                                // Toggle selection
                                if selectedListIDs.contains(list.objectID) {
                                    selectedListIDs.remove(list.objectID)
                                } else {
                                    selectedListIDs.insert(list.objectID)
                                }
                            } else {
                                // Normal tap behavior (select list and dismiss)
                                selectedTaskList = list
                                dismiss()
                            }
                        }
                        .contextMenu {
                            // Allow context actions only when not in selection mode
                            if !isSelectionMode {
                                Button("Edit") {
                                    editingTaskList = list
                                }
                                Button("Delete", role: .destructive) {
                                    listToDelete = list
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: isSelectionMode)
                .padding()
            }
            .navigationTitle("Task Lists")
            .toolbar {
                if isSelectionMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            // Exit selection mode and clear selections
                            isSelectionMode = false
                            selectedListIDs.removeAll()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                        }
                        .disabled(selectedListIDs.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Select") {
                            isSelectionMode = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingNewListPrompt) {
                NewListView(
                    isPresented: $isShowingNewListPrompt,
                    createList: { name, useBulletPoints, theme in
                        addTaskList(withName: name, useBulletPoints: useBulletPoints, theme: theme)
                        dismiss()
                    }
                )
            }// In TaskListsView:
            .sheet(item: $editingTaskList) { list in
                EditListView(
                    isPresented: Binding(
                        get: { editingTaskList != nil },
                        set: { newValue in
                            if !newValue { editingTaskList = nil }
                        }
                    ),
                    list: list
                ) { updatedList, newName, newBullet, newTheme in
                    updatedList.name = newName
                    updatedList.useBulletPoints = newBullet
                    updatedList.theme = newTheme
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error updating list: \(error.localizedDescription)")
                    }
                    // Dismiss the sheet by clearing the editing item.
                    editingTaskList = nil
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                if isSelectionMode {
                    // Alert for deleting multiple selected lists.
                    return Alert(
                        title: Text("Delete Lists"),
                        message: Text("Are you sure you want to delete the selected lists? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            for list in taskLists {
                                if selectedListIDs.contains(list.objectID) {
                                    viewContext.delete(list)
                                }
                            }
                            saveChanges()
                            // Exit selection mode after deletion.
                            isSelectionMode = false
                            selectedListIDs.removeAll()
                        },
                        secondaryButton: .cancel()
                    )
                } else if let list = listToDelete {
                    // Alert for deleting a single list via context menu.
                    return Alert(
                        title: Text("Delete List"),
                        message: Text("Are you sure you want to delete '\(list.name ?? "Unnamed List")'? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            viewContext.delete(list)
                            saveChanges()
                        },
                        secondaryButton: .cancel()
                    )
                } else {
                    return Alert(title: Text("Error"))
                }
            }
        }
    }
    
    private func saveChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
        }
    }
    
    private func addTaskList(withName name: String, useBulletPoints: Bool = true, theme: String = "default") {
        withAnimation(.bouncy(duration: 0.5)) {
            var finalName = name
            
            // Ensure the name is unique
            var counter = 1
            while taskLists.contains(where: { $0.name == finalName }) {
                counter += 1
                finalName = "\(name) \(counter)"
            }
            
            // Create the new list with the user-provided name
            let newList = TaskList(context: viewContext)
            newList.name = finalName
            newList.useBulletPoints = useBulletPoints
            newList.theme = theme  // Store the theme
            do {
                try viewContext.save()
                selectedTaskList = newList
            } catch {
                print("Error saving new list: \(error.localizedDescription)")
            }
        }
    }
    
    private func getThemeColor(_ themeKey: String) -> Color {
        // Define theme colors as in NewListView
        let themes = [
            "default": Color.gray.opacity(0.1),
            "blue": Color.blue.opacity(0.1),
            "green": Color.green.opacity(0.1),
            "pink": Color.pink.opacity(0.1),
            "purple": Color.purple.opacity(0.1),
            "yellow": Color.yellow.opacity(0.1)
        ]
        return themes[themeKey] ?? Color.white
    }
}
