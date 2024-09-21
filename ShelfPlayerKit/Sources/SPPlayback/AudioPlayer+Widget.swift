//
//  AudioPlayer+Widget.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import MediaPlayer
import SPFoundation
import SPOffline

internal extension AudioPlayer {
    func populateNowPlayingWidgetMetadata() {
        guard let item else {
            return
        }
        
        nowPlayingInfo = [:]
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = item.author
        nowPlayingInfo[MPMediaItemPropertyReleaseDate] = item.released
        nowPlayingInfo[MPNowPlayingInfoPropertyChapterCount] = chapters.count
        
        updateNowPlayingTitle()
        updateLastBookmarkTime()
        
        Task {
            if let image = await item.cover?.systemImage {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                
                updateNowPlayingInfo()
            }
        }
    }
    
    func updateNowPlayingTitle() {
        guard let item else {
            return
        }
        
        if enableChapterTrack, let chapter {
            nowPlayingInfo[MPMediaItemPropertyTitle] = chapter.title
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = item.name
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = item.name
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nil
        }
        
        updateNowPlayingInfo()
    }
    
    func updateLastBookmarkTime() {
        if let audiobook = item as? Audiobook, let bookmarks = try? OfflineManager.shared.bookmarks(itemId: audiobook.id) {
            nowPlayingInfo[MPMediaItemPropertyBookmarkTime] = bookmarks.last?.position
        }
    }
    
    func updateNowPlayingWidget() {
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = chapterDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = chapterCurrentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyChapterNumber] = currentChapterIndex
        
        updateNowPlayingInfo()
    }
    
    func clearNowPlayingMetadata() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingInfo() {
        if let lastWidgetUpdate {
            guard lastWidgetUpdate.timeIntervalSinceNow > -0.2 else {
                return
            }
        }
        
        lastWidgetUpdate = .now
        
        MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
