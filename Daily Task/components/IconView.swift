//
//  IconView.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import SwiftUICore


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
