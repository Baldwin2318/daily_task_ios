//
//  ThemRowView.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore


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
