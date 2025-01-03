//
//  AudiobookshelfClient.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import OSLog
import SwiftUI
import SPFoundation

public final class AudiobookshelfClient: ObservableObject {
    public private(set) var serverUrl: URL!
    public private(set) var _token: String?
    
    @Published public private(set) var authorized: Bool
    
    public private(set) var clientBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    public private(set) var clientVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    public private(set) var clientId: String
    
    public static let defaults = SPKit_ENABLE_ALL_FEATURES ? UserDefaults(suiteName: "group.io.rfk.shelfplayer")! : UserDefaults.standard
    
    internal var _customHTTPHeaders: [CustomHTTPHeader]?
    internal let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "HTTP")
    
    private init(serverUrl: URL?, token: String?) {
        if !SPKit_ENABLE_ALL_FEATURES {
            logger.warning("User-data will not be stored in a shared app group")
        }
        
        self.serverUrl = serverUrl
        _token = token
        authorized = token != nil
        
        if let clientId = Self.defaults.string(forKey: "clientId") {
            self.clientId = clientId
        } else {
            clientId = String(length: 100)
            Self.defaults.set(clientId, forKey: "clientId")
        }
    }
}

public extension AudiobookshelfClient {
    var token: String {
        _token ?? ""
    }
    
    func store(serverUrl: String) throws {
        guard let serverUrl = URL(string: serverUrl) else {
            throw ClientError.invalidServerUrl
        }
        
        Self.defaults.set(serverUrl, forKey: "serverUrl")
        self.serverUrl = serverUrl
    }
    
    func store(token: String?) {
        Self.defaults.set(token, forKey: "token")
        
        _token = token
        authorized = token != nil
    }
}

internal extension AudiobookshelfClient {
    enum ClientError: Error {
        case invalidServerUrl
        case invalidHttpBody
        case invalidResponse
        case missing
    }
}

public extension AudiobookshelfClient {
    static let shared = AudiobookshelfClient(serverUrl: defaults.url(forKey: "serverUrl"), token: defaults.string(forKey: "token"))
}
