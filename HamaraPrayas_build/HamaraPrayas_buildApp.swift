//
//  HamaraPrayas_buildApp.swift
//  HamaraPrayas_build
//
//  Created by Avighna Daruka on 29/08/25.
//

import SwiftUI
import FirebaseCore

@main
struct HamaraPrayas_buildApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Force light mode
        }
    }
}
