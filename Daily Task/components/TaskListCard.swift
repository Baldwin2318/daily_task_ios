//
//  TaskListCard.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore
import SwiftUI


struct TaskListCard: View {
    var taskList: TaskList
    var themeColor: Color
    var isSelectionMode: Bool
    var isSelected: Bool

    @FetchRequest var items: FetchedResults<Item>
    
    init(taskList: TaskList, themeColor: Color, isSelectionMode: Bool = false, isSelected: Bool = false) {
        self.taskList = taskList
        self.themeColor = themeColor
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        _items = FetchRequest<Item>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Item.sortOrder, ascending: true),
                NSSortDescriptor(keyPath: \Item.isPriority, ascending: false),
                NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)
            ],
            predicate: NSPredicate(format: "list == %@", taskList),
            animation: .default
        )
    }
    
    // Use the fetched items to show a preview (first three)
    var previewTasks: [Item] {
        return Array(items.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // List Title
            Text(taskList.name ?? "Unnamed List")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Preview Tasks
            if !previewTasks.isEmpty {
                ForEach(previewTasks, id: \.self) { task in
                    if taskList.useBulletPoints {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .primary)
                            Text(task.text ?? "Task")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(task.text ?? "Task")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
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
        .overlay(
            isSelectionMode ? selectionOverlay : nil
        )
        .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var selectionOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .padding(8)
            }
            Spacer()
        }
    }
}
