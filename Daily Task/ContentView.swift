import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch TaskList objects sorted by name.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskList.name, ascending: true)],
        animation: .default)
    private var taskLists: FetchedResults<TaskList>
    
    @State private var selectedTaskList: TaskList?
    @State private var showingListsSheet = true
    
    var body: some View {
        NavigationView {
            if let list = selectedTaskList ?? taskLists.first {
                // Show the tasks for the currently selected list.
                ListView(taskList: list)
                    .navigationTitle(list.name ?? "List")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            // Button to view all lists (square grid)
                            Button(action: {
                                showingListsSheet = true
                            }) {
                                Image(systemName: "square.grid.2x2")
                            }
                        }
//                        ToolbarItemGroup(placement: .navigationBarTrailing) {
//                            // Button to add a new list (pencil in box)
//                            Button(action: {
//                                addTaskList()
//                            }) {
//                                Image(systemName: "square.and.pencil")
//                            }
//                        }
                    }
                    .sheet(isPresented: $showingListsSheet) {
                        TaskListsView(taskLists: taskLists, selectedTaskList: $selectedTaskList)
                            .interactiveDismissDisabled(true)
                    }
            } else {
                // If no TaskList exists, provide a button to create one.
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.secondary)

                    Text("No lists available.")
                    Button("Create Default List") {
                        addTaskList()
                    }
                }
            }
        }
    }
    
    private func addTaskList() {
        withAnimation(.bouncy(duration: 0.5)) {
            // Start with a candidate number.
            var candidateNumber = taskLists.count + 1
            var candidateName = "List \(candidateNumber)"
            
            // Loop until we find a name that isn't taken.
            while taskLists.contains(where: { $0.name == candidateName }) {
                candidateNumber += 1
                candidateName = "List \(candidateNumber)"
            }
            
            // Create the new list with the unique candidate name.
            let newList = TaskList(context: viewContext)
            newList.name = candidateName
            do {
                try viewContext.save()
                selectedTaskList = newList
            } catch {
                print("Error saving new list: \(error.localizedDescription)")
            }
        }
    }
}

struct TaskListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var taskLists: FetchedResults<TaskList>
    @Binding var selectedTaskList: TaskList?
    @Environment(\.dismiss) private var dismiss

    // Track which list is currently being renamed.
    @State private var editingList: TaskList? = nil

    // Define grid columns (two columns in this example)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
 
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(taskLists, id: \.self) { list in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                            VStack {
                                if editingList == list {
                                    TextField("Rename List", text: Binding(
                                        get: { list.name ?? "" },
                                        set: { list.name = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        saveChanges()
                                        editingList = nil
                                    }
                                } else {
                                    Text(list.name ?? "Unnamed List")
                                        .font(.headline)
                                        .padding()
                                }
                            }
                        }
                        .frame(height: 100)
                        .onTapGesture {
                            selectedTaskList = list
                            dismiss()
                        }
                        .contextMenu {
                            Button("Rename") {
                                editingList = list
                            }
                            Button("Delete", role: .destructive) {
                                viewContext.delete(list)
                                saveChanges()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Task Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Button to add a new list
                    Button(action: {
                        addTaskList()
                        dismiss()
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
    private func deleteLists(offsets: IndexSet) {
        offsets.map { taskLists[$0] }.forEach { list in
            viewContext.delete(list)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error deleting lists: \(error.localizedDescription)")
        }
    }

    private func saveChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
        }
    }
    
    private func addTaskList() {
        withAnimation(.bouncy(duration: 0.5)) {
            // Start with a candidate number.
            var candidateNumber = taskLists.count + 1
            var candidateName = "List \(candidateNumber)"
            
            // Loop until we find a name that isn't taken.
            while taskLists.contains(where: { $0.name == candidateName }) {
                candidateNumber += 1
                candidateName = "List \(candidateNumber)"
            }
            
            // Create the new list with the unique candidate name.
            let newList = TaskList(context: viewContext)
            newList.name = candidateName
            do {
                try viewContext.save()
                selectedTaskList = newList
            } catch {
                print("Error saving new list: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
