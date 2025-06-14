//
//  NewListView.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore
import SwiftUI


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
