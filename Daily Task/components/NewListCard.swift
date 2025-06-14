//
//  NewListCard.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore
import SwiftUI

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
