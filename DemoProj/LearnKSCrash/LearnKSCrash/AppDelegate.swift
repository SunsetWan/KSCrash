//
//  AppDelegate.swift
//  LearnKSCrash
//
//  Created by Sunset on 28/2/2026.
//

import UIKit
import KSCrashRecording

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        installKSCrash()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    private func installKSCrash() {
        let configuration = KSCrashConfiguration()
        do {
            try KSCrash.shared.install(with: configuration)
            print("[LearnKSCrash] KSCrash installed")
        } catch {
            print("[LearnKSCrash] KSCrash install failed: \(error)")
        }
    }
}
