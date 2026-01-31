//
//  AppDelegate.swift
//  HamaraPrayas_build
//
//  Created by Avighna Daruka on 03/09/25.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Handle Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Handle Firebase password reset
        if Auth.auth().canHandle(url) {
            return true
        }
        
        // Handle custom URL schemes
        if url.scheme == "hamara-prayas" {
            // Handle custom app URLs if needed
            return true
        }
        
        return false
    }
    
}
