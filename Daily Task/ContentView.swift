import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskList.name, ascending: true)],
        animation: .default)
    private var taskLists: FetchedResults<TaskList>

    // State for presenting sheets
    @State private var isShowingNewListPrompt = false
    @State private var editingTaskList: TaskList? = nil
    
    // New state for automatically navigating to a list after creation
    @State private var selectedTaskList: TaskList? = nil
    
    // Selection mode state
    @State private var isSelectionMode = false
    @State private var selectedLists = Set<TaskList>()
    
    // State for deletion confirmation (single deletion)
    @State private var listToDelete: TaskList? = nil
    @State private var showingDeleteAlert = false

    // Define grid columns for a two-column layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    @Namespace private var animationNamespace

    var taskGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            if !isSelectionMode {
                NewListCard {
                    isShowingNewListPrompt = true
                }
                .matchedGeometryEffect(id: "plusCard", in: animationNamespace)
                // Immediately disappear without animation when selection mode toggles
                .transition(.identity)
                .animation(.none, value: isSelectionMode)
            }
            
            ForEach(taskLists, id: \.self) { list in
                if isSelectionMode {
                    TaskListCard(
                        taskList: list,
                        themeColor: getThemeColor(for: list.theme ?? "default"),
                        isSelectionMode: true,
                        isSelected: selectedLists.contains(list)
                    )
                    .matchedGeometryEffect(id: list.objectID, in: animationNamespace)
                    .onTapGesture {
                        toggleSelection(for: list)
                    }
                } else {
                    NavigationLink(destination: ListView(taskList: list)) {
                        TaskListCard(
                            taskList: list,
                            themeColor: getThemeColor(for: list.theme ?? "default"),
                            isSelectionMode: false,
                            isSelected: false
                        )
                        .matchedGeometryEffect(id: list.objectID, in: animationNamespace)
                        // Add a transition for removal
                        .transition(.move(edge: .trailing))
                    }
                    .contextMenu {
                        Button {
                            editingTaskList = list
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            // Set the deletion target and show the confirmation dialog with animation
                            withAnimation {
                                listToDelete = list
                                showingDeleteAlert = true
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        // Animate layout changes (for selection mode changes or deletions)
        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: isSelectionMode)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    taskGrid
                        .padding()
                }
                // Hidden NavigationLink that becomes active when selectedTaskList is set
                NavigationLink(
                    destination: Group {
                        if let list = selectedTaskList {
                            ListView(taskList: list)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding<Bool>(
                        get: { selectedTaskList != nil },
                        set: { newValue in
                            if !newValue { selectedTaskList = nil }
                        }
                    )
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("My Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            exitSelectionMode()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isSelectionMode {
                        Button("Select") {
                            enterSelectionMode()
                        }
                    } else {
                        Button(action: {
                            confirmDeleteSelected()
                        }) {
                            Image(systemName: "trash")
                        }
                        .disabled(selectedLists.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingNewListPrompt) {
                NewListView(isPresented: $isShowingNewListPrompt) { name, useBulletPoints, theme in
                    addTaskList(withName: name, useBulletPoints: useBulletPoints, theme: theme)
                }
            }
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
                    editingTaskList = nil
                }
            }
            // Use a confirmation dialog so it doesn't conflict with the context menu dismiss
            .confirmationDialog("Delete \(isSelectionMode ? "Lists" : "List")",
                                  isPresented: $showingDeleteAlert,
                                  titleVisibility: .visible) {
                if isSelectionMode {
                    Button("Delete \(selectedLists.count) lists", role: .destructive) {
                        deleteSelectedLists()
                    }
                } else if let list = listToDelete {
                    Button("Delete", role: .destructive) {
                        delete(list: list)
                        listToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    // Clear any deletion targets
                    listToDelete = nil
                }
            } message: {
                if isSelectionMode {
                    Text("Are you sure you want to delete \(selectedLists.count) lists? This action cannot be undone.")
                } else if let list = listToDelete {
                    Text("Are you sure you want to delete \"\(list.name ?? "Unnamed List")\"? This action cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func enterSelectionMode() {
        isSelectionMode = true
        selectedLists.removeAll()
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedLists.removeAll()
    }
    
    private func toggleSelection(for list: TaskList) {
        if selectedLists.contains(list) {
            selectedLists.remove(list)
        } else {
            selectedLists.insert(list)
        }
    }
    
    private func confirmDeleteSelected() {
        showingDeleteAlert = true
    }
    
    private func deleteSelectedLists() {
        withAnimation {
            for list in selectedLists {
                viewContext.delete(list)
            }
            saveChanges()
            exitSelectionMode()
        }
    }
    
    private func addTaskList(withName name: String, useBulletPoints: Bool = true, theme: String = "default") {
        withAnimation {
            var finalName = name
            var counter = 1
            while taskLists.contains(where: { $0.name == finalName }) {
                counter += 1
                finalName = "\(name) \(counter)"
            }
            let newList = TaskList(context: viewContext)
            newList.name = finalName
            newList.useBulletPoints = useBulletPoints
            newList.theme = theme
            do {
                try viewContext.save()
                // Set selectedTaskList so the NavigationLink becomes active
                selectedTaskList = newList
            } catch {
                print("Error saving new list: \(error.localizedDescription)")
            }
        }
    }
    
    private func delete(list: TaskList) {
        withAnimation {
            viewContext.delete(list)
            saveChanges()
        }
    }
    
    private func saveChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
        }
    }
    
    private func getThemeColor(for themeKey: String) -> Color {
        let themes: [String: Color] = [
            "default": Color.gray,
            "blue": Color.blue,
            "green": Color.green,
            "pink": Color.pink,
            "purple": Color.purple,
            "yellow": Color.yellow
        ]
        return themes[themeKey] ?? Color.gray
    }
}


//#Preview {
//    ContentView()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
