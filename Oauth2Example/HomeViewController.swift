//
//  HomeViewController.swift
//  Oauth2Example
//
//  Created by 00591908 on 2023/6/6.
//

import AppAuth
import UIKit

typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?, _ registrationResponse: OIDRegistrationResponse?) -> Void

class HomeViewController: BaseViewController {
    
    // The OIDC issuer from which the configuration will be discovered.
    let issuer: String = "https://54.95.116.212:8443/realms/Oauth2Example";
    
    //The OAuth client ID.
    let clientID: String = "DemoClient";
    
    //The OAuth redirect URI for the client @ clientID.
    let redirectURI: String = "com.corgi.oauth2:/oauth2redirect/example-provider";
    
    var configuration: OIDServiceConfiguration? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Login"
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        OIDURLSessionProvider.setSession(session)
        
        OauthManager.shared.loadState()
        if OauthManager.shared.authState?.isAuthorized == true {
            let vc = UserInfoViewController(nibName: "UserInfoViewController", bundle: nil)
            self.pushViewController(vc)
        }
        
        getServiceConfiguration()
    }
}

// MARK: - Private Method
extension HomeViewController {
    
    private func doAuthWithAutoCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
        
        guard let redirectURI = URL(string: redirectURI) else {
            print("Error creating URL for : \(redirectURI)")
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error accessing AppDelegate")
            return
        }
        
        print("-------------- doAuthWithAutoCodeExchange --------------")
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        
        print("configuration: \(request.configuration)")
        print("clientID: \(request.clientID)")
        print("clientSecret: \(request.clientSecret)")
        print("redirectURL: \(request.redirectURL)")
        print("responseType: \(request.responseType)")
        print("--------------------------------------------------------")
        
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self) { authState, error in
            if let authState = authState {
                print("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN")")
                OauthManager.shared.setAuthState(authState)
                if OauthManager.shared.authState?.isAuthorized == true {
                    let vc = UserInfoViewController(nibName: "UserInfoViewController", bundle: nil)
                    self.pushViewController(vc)
                }
            } else {
                print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                OauthManager.shared.setAuthState(nil)
            }
        }
    }
    
    private func doAuthWithoutCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
        
        guard let redirectURI = URL(string: redirectURI) else {
            print("Error creating URL for : \(redirectURI)")
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error accessing AppDelegate")
            return
        }
        
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        
        appDelegate.currentAuthorizationFlow = OIDAuthorizationService.present(request, presenting: self) { (response, error) in
            if let response = response {
                let authState = OIDAuthState(authorizationResponse: response)
                OauthManager.shared.setAuthState(authState)
                print("Authorization response with code: \(response.authorizationCode ?? "DEFAULT_CODE")")
            } else {
                print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
            }
        }
    }
    
    private func getServiceConfiguration() {
        guard let issuer = URL(string: issuer) else {
            print("Error creating URL for : \(issuer)")
            return
        }
        
        print("Fetching configuration for issuer: \(issuer)")
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { [weak self] config, error in
            if let error = error  {
                print("Error retrieving discovery document: \(error.localizedDescription)")
                return
            }
            
            guard let config = config else {
                print("Error retrieving discovery document. Error & Configuration both are NIL!")
                return
            }
            
            print("Get Configuration: \(config)")
            self?.configuration = config
        }
    }
    
}

// MARK: IBAction Method
extension HomeViewController {
    @IBAction func AutoButtonTapped(_ sender: Any) {
        guard let configuration = self.configuration else { return }
        self.doAuthWithAutoCodeExchange(configuration: configuration, clientID: self.clientID, clientSecret: nil)
    }
    
    @IBAction func WithOutAutoButtonTapped(_ sender: Any) {
        guard let configuration = self.configuration else { return }
        self.doAuthWithoutCodeExchange(configuration: configuration, clientID: self.clientID, clientSecret: nil)
    }
    
    @IBAction func ExchangeButtonTapped(_ sender: Any) {
        guard let tokenExchangeRequest = OauthManager.shared.authState?.lastAuthorizationResponse.tokenExchangeRequest() else {
            print("Error creating authorization code exchange request")
            return
        }
        
        print("Performing authorization code exchange with request \(tokenExchangeRequest)")
        
        OIDAuthorizationService.perform(tokenExchangeRequest) { response, error in
            if let tokenResponse = response {
                print("Received token response with accessToken: \(tokenResponse.accessToken ?? "DEFAULT_TOKEN")")
                OauthManager.shared.authState?.update(with: response, error: error)
                if OauthManager.shared.authState?.isAuthorized == true {
                    let vc = UserInfoViewController(nibName: "UserInfoViewController", bundle: nil)
                    self.pushViewController(vc)
                }
            } else {
                print("Token exchange error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
            }
        }
    }
}

extension HomeViewController: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, urlCredential)
    }
}
