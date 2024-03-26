//
//  LoginView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import SPBase
import BetterSafariView
import CommonCrypto

struct LoginView: View {
    var callback : () -> ()
    
    @State private var loginSheetPresented = false
    @State private var loginFlowState: LoginFlowState = .server
    
    @State private var server = AudiobookshelfClient.shared.serverUrl?.absoluteString ?? "https://"
    @State private var username = ""
    @State private var password = ""
    
    @State private var serverVersion: String?
    @State private var loginError: LoginError?
    
    private let verifier = String.random(length: 100)
    @State private var openIDLoginURL: URL?
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            
            Text("login.welcome")
                .font(.headline)
                .fontDesign(.serif)
            Text("login.text")
                .font(.subheadline)
            
            Button {
                loginSheetPresented.toggle()
            } label: {
                Text("login.prompt")
            }
            .buttonStyle(LargeButtonStyle())
            .padding()
            
            Spacer()
            
            #if !ENABLE_ALL_FEATURES
            Text("developedBy")
                .font(.caption)
                .foregroundStyle(.secondary)
            #else
            Text("login.disclaimer")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            #endif
        }
        .sheet(isPresented: $loginSheetPresented) {
            switch loginFlowState {
                case .server, .credentialsLocal:
                    Form {
                        Section {
                            if loginFlowState == .server {
                                TextField("login.server", text: $server)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else if loginFlowState == .credentialsLocal {
                                TextField("login.username", text: $username)
                                SecureField("login.password", text: $password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Button {
                                flowStep()
                            } label: {
                                Text("login.next")
                            }
                            
                            if loginFlowState == .server {
                                Button {
                                    loginFlowState = .customHTTPHeaders
                                } label: {
                                    Text("login.customHTTPHeaders")
                                }
                            }
                        } header: {
                            if let serverVersion = serverVersion {
                                Text("login.version \(serverVersion)")
                            } else {
                                Text("login.title")
                            }
                        } footer: {
                            Group {
                                switch loginError {
                                    case .server:
                                        Text("login.error.server")
                                    case .url:
                                        Text("login.error.url")
                                    case .failed:
                                        Text("login.error.failed")
                                    case nil:
                                        Text(verbatim: "")
                                }
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .onSubmit(flowStep)
                case .customHTTPHeaders:
                    CustomHeaderEditView() {
                        loginFlowState = .server
                    }
                case .credentialsOpenID:
                    if let openIDLoginURL = openIDLoginURL {
                        ProgressView()
                            .webAuthenticationSession(isPresented: .constant(true)) {
                                WebAuthenticationSession(url: openIDLoginURL, callbackURLScheme: "shelfplayer", completionHandler: self.openIDCallback)
                                    .prefersEphemeralWebBrowserSession(true)
                            }
                    } else {
                        ProgressView()
                            .task { await fetchOpenIDLoginURL() }
                    }
                case .credentialsSelect:
                    Form {
                        Section {
                            Button {
                                loginFlowState = .credentialsOpenID
                            } label: {
                                Text("login.openid")
                            }
                            
                            Button {
                                loginFlowState = .credentialsLocal
                            } label: {
                                Text("login.local")
                            }
                        } header: {
                            Text("login.version \(serverVersion!)")
                        } footer: {
                            Text("login.openid.urlScheme")
                            
                            if loginError == .failed {
                                Text("login.error.failed")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                case .setup:
                    Text("login.setup")
                        .padding()
                case .serverLoading, .credentialsLoading:
                    VStack {
                        ProgressView()
                        Text("login.loading")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
            }
        }
    }
}

// MARK: Functions

extension LoginView {
    private func flowStep() {
        if loginFlowState == .server {
            loginFlowState = .serverLoading
            
            // Verify url format
            do {
                try AudiobookshelfClient.shared.setServerUrl(server)
            } catch {
                loginError = .url
                loginFlowState = .server
                
                return
            }
            
            // Verify server
            Task {
                do {
                    let status = try await AudiobookshelfClient.shared.status()
                    
                    serverVersion = status.serverVersion
                    
                    if status.authMethods.count == 2 {
                        loginFlowState = .credentialsSelect
                    } else if status.authMethods.contains("local") {
                        loginFlowState = .credentialsLocal
                    } else if status.authMethods.contains("openid") {
                        loginFlowState = .credentialsOpenID
                    }
                } catch {
                    loginError = .server
                    loginFlowState = .server
                    
                    return
                }
                
                loginError = nil
            }
        } else if loginFlowState == .credentialsLocal {
            loginFlowState = .credentialsLoading
            
            Task {
                do {
                    let token = try await AudiobookshelfClient.shared.login(username: username, password: password)
                    
                    AudiobookshelfClient.shared.setToken(token)
                    callback()
                } catch {
                    loginError = .failed
                    loginFlowState = .credentialsLocal
                }
            }
        }
    }
    
    enum LoginFlowState {
        case server
        case serverLoading
        
        case credentialsLocal
        case credentialsOpenID
        case credentialsSelect
        case credentialsLoading
        
        case setup
        case customHTTPHeaders
    }
    enum LoginError {
        case server
        case url
        case failed
    }
}

extension LoginView {
    private func fetchOpenIDLoginURL() async {
        do {
            openIDLoginURL = try await AudiobookshelfClient.shared.openIDLoginURL(verifier: verifier)
        } catch {
            loginError = .failed
            loginFlowState = .server
        }
    }
    
    private func openIDCallback(url: URL?, error: Error?) {
        loginFlowState = .credentialsLoading
        
        if error == nil, let url = url {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value,
               let state = components?.queryItems?.first(where: { $0.name == "state" })?.value {
                Task {
                    if let token = try? await AudiobookshelfClient.shared.openIDExchange(code: code, state: state, verifier: verifier) {
                        AudiobookshelfClient.shared.setToken(token)
                        callback()
                    } else {
                        openIDLoginURL = nil
                        
                        loginError = .failed
                        loginFlowState = .server
                    }
                }
                
                return
            }
        }
        
        openIDLoginURL = nil
        
        loginError = .failed
        loginFlowState = .server
    }
}

#Preview {
    LoginView() {
        print("Login flow finished")
    }
}
