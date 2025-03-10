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
                createList: { name, useBulletPoints, theme in
                    addTaskList(withName: name, useBulletPoints: useBulletPoints, theme: theme)
                }
            )
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
    
    // Add state variables for delete confirmation
    @State private var showingDeleteAlert = false
    @State private var listToDelete: TaskList? = nil


    // Define grid columns (two columns in this example)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
 
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
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
                    
                    ForEach(taskLists, id: \.self) { list in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getThemeColor(list.theme ?? "default"))
                            VStack {
                                if editingList == list {
                                    // Editing content remains the same
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
                                listToDelete = list
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Task Lists")
            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    // Button to add a new list
//                    Button(action: {
//                        newListName = ""
//                        isShowingNewListPrompt = true
//                    }) {
//                        Image(systemName: "square.and.pencil")
//                    }
//
//                }
            }
            .sheet(isPresented: $isShowingNewListPrompt) {
                NewListView(
                    isPresented: $isShowingNewListPrompt,
                    createList: { name, useBulletPoints, theme in
                        addTaskList(withName: name, useBulletPoints: useBulletPoints, theme: theme)
                        dismiss()
                    }
                )
            }
            .alert("Delete List", isPresented: $showingDeleteAlert, presenting: listToDelete) { list in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewContext.delete(list)
                    saveChanges()
                }
            } message: { list in
                Text("Are you sure you want to delete '\(list.name ?? "Unnamed List")'? This action cannot be undone.")
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
        // Define the same theme colors as in NewListView
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
struct NewListView: View {
    @Binding var isPresented: Bool
    var createList: (String, Bool, String) -> Void  // Includes theme
    
    @State private var listName = ""
    @State private var selectedSymbol: String? = "✓"
    @State private var useBulletPoints = true
    @State private var selectedTheme = "default"
    @FocusState private var isNameFieldFocused: Bool
    
    // Define available symbols
    let availableSymbols = [
        "🥕", "🍎", "🥦", "🛒", "🍞", "🥚", "🥩", "🧀", "🍗", "🍌",
        "🏠", "💼", "📚", "🎮", "🎬", "✈️", "🔨", "💪", "🎁", "❤️",
        "💻","⚙️","🇯🇵","🇵🇭","🇨🇦","☀️","✨","⭐️","🌈"
    ]
    
    // Theme definitions moved to a computed property
    var themeColors: [String: Color] {
        [
            "default": Color.clear,
            "blue": Color.blue.opacity(0.1),
            "green": Color.green.opacity(0.1),
            "pink": Color.pink.opacity(0.1),
            "purple": Color.purple.opacity(0.1),
            "yellow": Color.yellow.opacity(0.1),
        ]
    }
    
    var themeNames: [String: String] {
        [
            "default": "Default",
            "blue": "Sky Blue",
            "green": "Mint Green",
            "pink": "Soft Pink",
            "purple": "Lavender",
            "yellow": "Sunshine",
        ]
    }
    
    var body: some View {
        NavigationView {
            Form {
                // List details section
                listDetailsSection
                
                // Icon selection section
                iconSelectionSection
                
                // Theme selection section
                themeSelectionSection
                
                // Preview section
                previewSection
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
                            createList(finalName, useBulletPoints, selectedTheme)
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
    
    // MARK: - View Components
    
    private var listDetailsSection: some View {
        Section(header: Text("List Details")) {
            TextField("List Name", text: $listName)
                .focused($isNameFieldFocused)
                
            Toggle("Use Bullet Points", isOn: $useBulletPoints)
                .toggleStyle(SwitchToggleStyle())
        }
    }
    
    private var iconSelectionSection: some View {
        Section(header: Text("Choose an Icon (Optional)")) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(availableSymbols, id: \.self) { symbol in
                    IconView(symbol: symbol, isSelected: selectedSymbol == symbol)
                        .onTapGesture {
                            selectedSymbol = symbol
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var themeSelectionSection: some View {
        Section(header: Text("Choose a Theme")) {
            ForEach(Array(themeNames.keys.sorted()), id: \.self) { themeKey in
                ThemeRowView(
                    themeKey: themeKey,
                    themeName: themeNames[themeKey] ?? "",
                    themeColor: themeColors[themeKey] ?? .white,
                    isSelected: selectedTheme == themeKey
                )
                .onTapGesture {
                    selectedTheme = themeKey
                }
            }
        }
    }
    
    private var previewSection: some View {
        Section(header: Text("Preview")) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeColors[selectedTheme] ?? .white)
                    .frame(height: 120)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(listName.isEmpty ? "My List" : listName)
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    PreviewTaskRow(useBulletPoints: useBulletPoints, isCompleted: false)
                    PreviewTaskRow(useBulletPoints: useBulletPoints, isCompleted: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Helper Views

struct IconView: View {
    let symbol: String
    let isSelected: Bool
    
    var body: some View {
        Text(symbol)
            .font(.title)
            .frame(width: 44, height: 44)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
    }
}

struct ThemeRowView: View {
    let themeKey: String
    let themeName: String
    let themeColor: Color
    let isSelected: Bool
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(themeColor)
                .frame(width: 24, height: 24)
            
            Text(themeName)
                .padding(.leading, 8)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

struct PreviewTaskRow: View {
    let useBulletPoints: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            if useBulletPoints {
                Image(systemName: isCompleted ? "checkmark.circle" : "circle")
                    .foregroundColor(isCompleted ? .green : .primary)
            }
            Text(isCompleted ? "Sample task 2" : "Sample task 1")
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .gray : .primary)
        }
    }
}
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
