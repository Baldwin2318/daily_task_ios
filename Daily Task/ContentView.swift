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
    
    @State private var isShowingNewListPrompt = false
    @State private var newListName = ""
    
    var body: some View {
        NavigationView {
            if let list = selectedTaskList ?? taskLists.first {
                // Show the tasks for the currently selected list.
                ListView(taskList: list)
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
                        newListName = ""
                        isShowingNewListPrompt = true
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingNewListPrompt) {
            NewListView(
                isPresented: $isShowingNewListPrompt,
                createList: { name in
                    addTaskList(withName: name)
                    
                }
            )
        }
    }
    
    
    // Modify your addTaskList function to accept a name
    private func addTaskList(withName name: String) {
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
    
    @State private var isShowingNewListPrompt = false
    @State private var newListName = ""

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
                        newListName = ""
                        isShowingNewListPrompt = true
                    }) {
                        Image(systemName: "square.and.pencil")
                    }

                }
            }
            .sheet(isPresented: $isShowingNewListPrompt) {
                NewListView(
                    isPresented: $isShowingNewListPrompt,
                    createList: { name in
                        addTaskList(withName: name)
                        dismiss()
                    }
                )
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
    
    // Modify your addTaskList function to accept a name
    private func addTaskList(withName name: String) {
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
            do {
                try viewContext.save()
                selectedTaskList = newList
            } catch {
                print("Error saving new list: \(error.localizedDescription)")
            }
        }
    }
}
struct NewListView: View {
    @Binding var isPresented: Bool
    var createList: (String) -> Void
    
    @State private var listName = ""
    @State private var selectedSymbol: String? = "✓" 
    @FocusState private var isNameFieldFocused: Bool
    
    // Define available symbols - you can customize this list
    let availableSymbols = [
        "🥕", "🍎", "🥦", "🛒", "🍞", "🥚", "🥩", "🧀", "🍗", "🍌",
        "🏠", "💼", "📚", "🎮", "🎬", "✈️", "🔨", "💪", "🎁", "❤️",
        "💻","⚙️","🇯🇵","🇵🇭","🇨🇦","☀️","✨","⭐️","🌈"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("List Details")) {
                    TextField("List Name", text: $listName)
                        .focused($isNameFieldFocused)
                }
                
                Section(header: Text("Choose an Icon (Optional)")) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44))
                    ], spacing: 10) {
                        ForEach(availableSymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(selectedSymbol == symbol ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedSymbol = symbol
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !listName.isEmpty {
                            let finalName = selectedSymbol != nil ? "\(listName) \(selectedSymbol!)" : listName
                            createList(finalName)
                            isPresented = false
                        }
                    }
                    .disabled(listName.isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }
}
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
