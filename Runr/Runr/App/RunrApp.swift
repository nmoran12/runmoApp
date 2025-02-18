//
//  RunrApp.swift
//  Runr
//
//  Created by Noah Moran on 6/1/2025.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct RunrApp: App {
    @StateObject var runTracker = RunTracker()
    @StateObject var authService = AuthService.shared
    @StateObject var registrationViewModel = RegistrationViewModel()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.userSession == nil {
                    LoginView()
                        .environmentObject(authService)
                        .environmentObject(registrationViewModel)
                } else {
                    RunrTabView()
                        .environmentObject(authService)
                        .environmentObject(runTracker)
                }
            }
        }
    }
}



