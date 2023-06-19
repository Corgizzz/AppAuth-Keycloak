//
//  UserInfoViewController.swift
//  Oauth2Example
//
//  Created by 00591908 on 2023/6/7.
//

import AppAuth
import UIKit

class UserInfoViewController: BaseViewController {
    
    let kAppAuthExampleAuthStateKey: String = "authState";
    
    // The OIDC issuer from which the configuration will be discovered.
    let issuer: String = "https://54.95.116.212:8443/realms/Oauth2Example";
    
    //The OAuth client ID.
    let clientID: String? = "DemoClient";
    
    //The OAuth redirect URI for the client @ clientID.
    let redirectURI: String = "cathayoauth://oauth2redirect/test";
    
    @IBOutlet var userAccount: UILabel!
    @IBOutlet var userName: UILabel!
    @IBOutlet var userEmail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.title = "User Info"
        getUserInfo()
    }
    @IBAction func logoutButtonTapped(_ sender: Any) {
        
        guard let issuer = URL(string: issuer) else {
            print("Error creating URL for : \(issuer)")
            return
        }
        
        print("Fetching sign out configuration for issuer: \(issuer)")
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let config = configuration else {
                print("Error retrieving discovery document: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                OauthManager.shared.setAuthState(nil)
                return
            }
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Error accessing AppDelegate")
                return
            }
            
            let signoutRequest = OIDEndSessionRequest(configuration: config,
                                                      idTokenHint: (OauthManager.shared.authState?.lastTokenResponse?.idToken)!,
                                                      postLogoutRedirectURL: URL(string: self.redirectURI)!,
                                                      state: (OauthManager.shared.authState?.lastAuthorizationResponse.state)!,
                                                      additionalParameters: nil)
            
            print("-------------- signoutRequest --------------")
            print("configuration: \(config)")
            print("idTokenHint: \((OauthManager.shared.authState?.lastTokenResponse?.idToken)!)")
            print("postLogoutRedirectURL: \(URL(string: self.redirectURI)!)")
            print("state: \((OauthManager.shared.authState?.lastAuthorizationResponse.state)!)")
            print("--------------------------------------------------------")
            
            
            guard let agent = OIDExternalUserAgentIOS(presenting: self, prefersEphemeralSession: true) else { return }
            appDelegate.currentAuthorizationFlow = OIDAuthorizationService.present(signoutRequest, externalUserAgent: agent) { result, err in
                if let result = result {
                    HTTPCookieStorage.shared.cookies?.forEach { cookie in
                        HTTPCookieStorage.shared.deleteCookie(cookie)
                    }
                    print("Sign Out Result: \(result)")
                    OauthManager.shared.setAuthState(nil)
                    if OauthManager.shared.authState?.isAuthorized != true {
                        self.popViewController()
                    }
                } else {
                    print("Sign Out error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                }
            }
        }
        
    }
    
    func getUserInfo() {
        
        print("--------------------UserInfo--------------------")
        guard let userinfoEndpoint = OauthManager.shared.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint else {
            print("Userinfo endpoint not declared in discovery document")
            return
        }
        
        print("userinfoEndpoint: \(userinfoEndpoint)")
        
        let currentAccessToken: String? = OauthManager.shared.authState?.lastTokenResponse?.accessToken
        
        OauthManager.shared.authState?.performAction() { (accessToken, idToken, error) in
            if error != nil  {
                print("Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                OauthManager.shared.setAuthState(nil)
                if OauthManager.shared.authState?.isAuthorized != true {
                    self.popViewController()
                }
                return
            }
            
            guard let accessToken = accessToken else {
                print("Error getting accessToken")
                return
            }
            
            if currentAccessToken != accessToken {
                print("Access token was refreshed automatically (\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken))")
            } else {
                //                print("Access token was fresh and not updated \(accessToken)")
            }
            
            var urlRequest = URLRequest(url: userinfoEndpoint)
            urlRequest.allHTTPHeaderFields = ["Authorization":"Bearer \(accessToken)"]
            
            print("urlRequest: \(urlRequest)")
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            let task = session.dataTask(with: urlRequest) { data, response, error in
                
                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        print("HTTP request failed \(error?.localizedDescription ?? "ERROR")")
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse else {
                        print("Non-HTTP response")
                        return
                    }
                    
                    guard let data = data else {
                        print("HTTP response data is empty")
                        return
                    }
                    
                    var json: [String: Any]?
                    
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        print("JSON Serialization Error")
                    }
                    
                    if response.statusCode != 200 {
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)
                        
                        if response.statusCode == 401 {
                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                            // grant. Puts OIDAuthState into an error state.
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: json,
                                                                                                underlyingError: error)
                            OauthManager.shared.authState?.update(withAuthorizationError: oauthError)
                            print("Authorization Error (\(oauthError)). Response: \(responseText ?? "RESPONSE_TEXT")")
                        } else {
                            print("HTTP: \(response.statusCode), Response: \(responseText ?? "RESPONSE_TEXT")")
                        }
                        
                        return
                    }
                    
                    if let json = json {
                        print("Success: \(json)")
                        self.userAccount.text = "帳號: \(json["preferred_username"] as! String)"
                        self.userName.text = "姓名: \(json["name"] as! String)"
                        self.userEmail.text = "信箱: \(json["email"] as! String)"
                    }
                }
            }
            
            task.resume()
        }
    }
}

extension UserInfoViewController: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, urlCredential)
    }
}
