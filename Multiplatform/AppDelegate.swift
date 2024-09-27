//
//  AppDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import UIKit
import Intents

internal final class AppDelegate: NSObject, UIApplicationDelegate {
    private var backgroundCompletionHandler: (() -> Void)? = nil
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let backgroundCompletionHandler = appDelegate.backgroundCompletionHandler else {
            return
        }
        
        backgroundCompletionHandler()
    }
    
    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
        case is INPlayMediaIntent:
            return PlayMediaHandler()
        default:
            return nil
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner]
    }
    
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        guard let libraryID = userInfo["libraryID"] as? String, let podcastID = userInfo["podcastID"] as? String else {
            return
        }
        
        if let episodeID = userInfo["episodeID"] as? String {
            Navigation.navigate(episodeID: episodeID, podcastID: podcastID, libraryID: libraryID)
        } else {
            Navigation.navigate(podcastID: podcastID, libraryID: libraryID)
        }
    }
}

