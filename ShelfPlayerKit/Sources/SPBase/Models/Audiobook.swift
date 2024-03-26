//
//  Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public class Audiobook: PlayableItem {
    public let narrator: String?
    public let series: [ReducedSeries]
    
    public let explicit: Bool
    public let abridged: Bool
    
    public init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: Double, narrator: String?, series: [ReducedSeries], explicit: Bool, abridged: Bool) {
        self.narrator = narrator
        self.series = series
        self.explicit = explicit
        self.abridged = abridged
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size, duration: duration)
    }
}

public extension Audiobook {
    var seriesName: String? {
        if series.isEmpty {
            return nil
        }
        
        return series.compactMap {
            if let sequence = $0.sequence {
                return "\($0.name) #\(sequence)"
            }
            
            return $0.name
        }.joined(separator: ", ")
    }
}

extension Audiobook {
    public struct ReducedSeries: Codable {
        public let id: String?
        
        public let name: String
        public let sequence: Float?
        
        public init(id: String?, name: String, sequence: Float?) {
            self.id = id
            self.name = name
            self.sequence = sequence
        }
    }
}
