//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

extension NowPlayingSheet {
    struct Title: View {
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if let episode = AudioPlayer.shared.item as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                        } else if let audiobook = AudioPlayer.shared.item as? Audiobook, let seriesName = audiobook.seriesName {
                            Text(seriesName)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text(AudioPlayer.shared.item?.name ?? "-/-")
                        .lineLimit(1)
                        .font(.headline)
                        .fontDesign(AudioPlayer.shared.item as? Audiobook != nil ? .serif : .default)
                        .foregroundStyle(.primary)
                    
                    if let author = AudioPlayer.shared.item?.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}
