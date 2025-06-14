//
//  TaskRow.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-13.
//

import SwiftUICore
import SwiftUI


struct TaskRow: View {
    let useBulletPoints: Bool
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
            if useBulletPoints{
                Button(action: onToggleComplete) {
                    Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                        .foregroundColor(item.isCompleted ? .green : .primary)
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(BorderlessButtonStyle())
                
            }
            
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
public protocol EquatableBytes: Equatable {
    init(bytes: [UInt8])
    var bytes: [UInt8] { get }
}
