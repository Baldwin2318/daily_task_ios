//
//  CompletedTasksSheet.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-13.
//

import SwiftUICore
import SwiftUI


struct CompletedTasksSheet: View {
    let completedTasks: [Item]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            List {
                ForEach(completedTasks) { task in
                    HStack {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.green)
                        Text(task.text ?? "No Text")
                            .strikethrough(task.isCompleted, color: .black)
                            .foregroundColor(task.isCompleted ? .gray : .primary)
                    }
                }
            }
            .navigationTitle("Completed Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        cleanCompletedTasks()
                        dismiss()
                    }) {
                        Text("CLEAN ALL")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    private func cleanCompletedTasks() {
        withAnimation {
            for task in completedTasks {
                viewContext.delete(task)
            }
            do {
                try viewContext.save()
            } catch {
                print("Error cleaning tasks: \(error.localizedDescription)")
            }
        }
    }
}
