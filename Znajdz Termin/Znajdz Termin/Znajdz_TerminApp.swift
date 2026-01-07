//
//  Znajdz_TerminApp.swift
//  Znajdz Termin
//
//  Created by Krzysztof Kuźmicki on 29/12/2025.
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct Znajdz_TerminApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    requestTrackingAuthorization()
                }
        }
    }
    
    private func requestTrackingAuthorization() {
        // Request ATT authorization after a short delay to ensure the app is fully active
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    print("ATT Authorization status: \(status.rawValue)")
                    // Initialize Google Mobile Ads after ATT decision
                    MobileAds.shared.start { initStatus in
                        print("Google Mobile Ads SDK initialized")
                    }
                }
            } else {
                // iOS 13 and earlier - no ATT required
                MobileAds.shared.start { initStatus in
                    print("Google Mobile Ads SDK initialized")
                }
            }
        }
    }
}

/// App Delegate for additional setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}
