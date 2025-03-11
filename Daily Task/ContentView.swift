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

    // Define grid columns for a two-column layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // New List Card
                    NewListCard {
                        isShowingNewListPrompt = true
                    }
                    
                    // Existing List Cards
                    ForEach(taskLists, id: \.self) { list in
                        NavigationLink(destination: ListView(taskList: list)) {
                            TaskListCard(list: list, themeColor: getThemeColor(for: list.theme ?? "default"))
                        }
                        .contextMenu {
                            Button {
                                editingTaskList = list
                                
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                delete(list: list)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Lists")
//            .navigationBarTitleDisplayMode(.inline) // This line forces the inline display mode.
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        isShowingNewListPrompt = true
//                    }) {
//                        Image(systemName: "plus")
//                    }
//                }
//            }
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
                    // Dismiss the sheet by clearing the editing item.
                    editingTaskList = nil
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
        // Customize these theme colors as you wish.
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

// MARK: - Custom Card Views

struct TaskListCard: View {
    var list: TaskList
    var themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(list.name ?? "Unnamed List")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer()
        }
        .padding()
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeColor.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColor, lineWidth: 1)
        )
        .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct NewListCard: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                Text("New List")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(minHeight: 120)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(.blue)
            )
        }
    }
}

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
struct NewListView: View {
    @Binding var isPresented: Bool
    var createList: (String, Bool, String) -> Void  // Includes theme
    
    @State private var listName = ""
    @State private var selectedSymbol: String? = ""
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
                    IconView(symbol: symbol, isSelected: false)
                        .onTapGesture {
                            listName.append(symbol)
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



struct EditListView: View {
    @Binding var isPresented: Bool
    var list: TaskList
    var updateList: (TaskList, String, Bool, String) -> Void

    @State private var listName: String
    @State private var selectedSymbol: String?  // if you have an icon property
    @State private var useBulletPoints: Bool
    @State private var selectedTheme: String
    @FocusState private var isNameFieldFocused: Bool

    // Initialize state with the current list values.
    init(isPresented: Binding<Bool>, list: TaskList, updateList: @escaping (TaskList, String, Bool, String) -> Void) {
        self._isPresented = isPresented
        self.list = list
        self.updateList = updateList
        _listName = State(initialValue: list.name ?? "")
        _useBulletPoints = State(initialValue: list.useBulletPoints)
        _selectedTheme = State(initialValue: list.theme ?? "default")
        // You can initialize selectedSymbol from the list if you store an icon.
        _selectedSymbol = State(initialValue: "✓")
    }

    // Reuse the same UI components as NewListView:
    var body: some View {
        NavigationView {
            Form {
                listDetailsSection
                iconSelectionSection
                themeSelectionSection
                previewSection
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false  // Dismisses the sheet
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        updateList(list, listName, useBulletPoints, selectedTheme)
                        isPresented = false
                    }
                    .disabled(listName.isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }

    // MARK: - UI Components

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
                ForEach([
                    "🥕", "🍎", "🥦", "🛒", "🍞", "🥚", "🥩", "🧀", "🍗", "🍌",
                    "🏠", "💼", "📚", "🎮", "🎬", "✈️", "🔨", "💪", "🎁", "❤️",
                    "💻","⚙️","🇯🇵","🇵🇭","🇨🇦","☀️","✨","⭐️","🌈"
                ], id: \.self) { symbol in
                    IconView(symbol: symbol, isSelected: false)
                        .onTapGesture {
                            listName.append(symbol)
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var themeSelectionSection: some View {
        Section(header: Text("Choose a Theme")) {
            ForEach(["default", "blue", "green", "pink", "purple", "yellow"], id: \.self) { themeKey in
                ThemeRowView(
                    themeKey: themeKey,
                    themeName: themeDisplayName(for: themeKey),
                    themeColor: themeColor(for: themeKey),
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
                    .fill(themeColor(for: selectedTheme))
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

    // Helper methods for theme display
    private func themeColor(for key: String) -> Color {
        let themes: [String: Color] = [
            "default": Color.clear,
            "blue": Color.blue.opacity(0.1),
            "green": Color.green.opacity(0.1),
            "pink": Color.pink.opacity(0.1),
            "purple": Color.purple.opacity(0.1),
            "yellow": Color.yellow.opacity(0.1)
        ]
        return themes[key] ?? Color.white
    }

    private func themeDisplayName(for key: String) -> String {
        let names: [String: String] = [
            "default": "Default",
            "blue": "Sky Blue",
            "green": "Mint Green",
            "pink": "Soft Pink",
            "purple": "Lavender",
            "yellow": "Sunshine"
        ]
        return names[key] ?? key
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
//#Preview {
//    ContentView()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
