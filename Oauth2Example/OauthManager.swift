//
//  OauthManager.swift
//  Oauth2Example
//
//  Created by Corgi on 2023/6/8.
//

import Foundation
import AppAuth

class OauthManager: NSObject {
    static let shared = OauthManager()
    
    var authState: OIDAuthState?
    
    let kAppAuthExampleAuthStateKey: String = "authState"
    
    func saveState() {
        var data: Data? = nil
        
        if let authState = self.authState {
            data = NSKeyedArchiver.archivedData(withRootObject: authState)
            print("123123", String(data: data!, encoding: .utf8))

        }
        
        if let userDefaults = UserDefaults(suiteName: "group.net.openid.appauth.Example") {
            userDefaults.set(data, forKey: kAppAuthExampleAuthStateKey)
            userDefaults.synchronize()
        }
    }
    
    func loadState() {
        guard let data = UserDefaults(suiteName: "group.net.openid.appauth.Example")?.object(forKey: kAppAuthExampleAuthStateKey) as? Data else {
            return
        }
        
        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            self.setAuthState(authState)
        }
    }
    
    func setAuthState(_ authState: OIDAuthState?) {
        if self.authState == authState {
            return
        }
        self.authState = authState
        self.authState?.stateChangeDelegate = self
        self.stateChanged()
    }
    
    func stateChanged() {
        self.saveState()
    }
    
}

//MARK: OIDAuthState Delegate
extension OauthManager: OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    
    func didChange(_ state: OIDAuthState) {
        self.stateChanged()
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        print("Received authorization error: \(error)")
    }
}
