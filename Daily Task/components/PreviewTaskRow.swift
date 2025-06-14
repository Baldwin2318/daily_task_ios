//
//  PreviewTaskRow.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore


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
