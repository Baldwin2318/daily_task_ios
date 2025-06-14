//
//  EditListView.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore
import SwiftUI


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
