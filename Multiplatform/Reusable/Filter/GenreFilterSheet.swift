//
//  AudiobookGenreFilter.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.02.24.
//

import SwiftUI

internal struct GenreFilterSheet: ViewModifier {
    let genres: [String]
    @Binding var selected: [String]
    
    @State private var isPresented = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                List {
                    ForEach(genres.sorted(by: <), id: \.hashValue) { genre in
                        Toggle(genre, isOn: .init(get: { selected.contains(where: { $0 == genre }) }, set: {
                            if $0 && !selected.contains(where: { $0 == genre }) {
                                selected.append(genre)
                            } else {
                                selected.removeAll { $0 == genre }
                            }
                        }))
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }
}