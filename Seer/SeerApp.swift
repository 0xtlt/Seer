//
//  SeerApp.swift
//  Seer
//
//  Created by Jacob Davis on 10/30/22.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImageSVGCoder

@main
struct SeerApp: App {
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var nostrData: NostrData = NostrData.shared
    @StateObject var navigation: Navigation = Navigation()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(nostrData)
                .environmentObject(navigation)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print("👁️ Seer => Entered Background Phase")
            case .active:
                print("👁️ Seer => Entered Active Phase")
                nostrData.reconnect()
            case .inactive:
                print("👁️ Seer => Entered Inactive Phase")
                nostrData.disconnect()
            default:
                print("👁️ Seer => Entered Unknown Phase")
            }
        }
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidChangeOcclusionState(_ notification: Notification) {
        if let window = NSApp.windows.first, window.isMiniaturized {
            NSWorkspace.shared.runningApplications.first(where: {
                $0.activationPolicy == .regular
            })?.activate(options: .activateAllWindows)
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if let window = NSApp.windows.first {
            window.deminiaturize(nil)
        }
    }
    
    lazy var windows = NSWindow()
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
         if !flag {
             for window in sender.windows {
                 window.makeKeyAndOrderFront(self)
             }
         }
         return true
     }
}
#elseif os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        return true
    }
}
#endif
