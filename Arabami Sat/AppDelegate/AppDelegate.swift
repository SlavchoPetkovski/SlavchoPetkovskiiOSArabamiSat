//
//  AppDelegate.swift
//  Arabami Sat
//
//  Created by Slavcho Petkovski on 7.5.21.
//

import UIKit
import FBSDKCoreKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        var rootVC: UIViewController!
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        FirebaseApp.configure()

        if AuthenticationManager.isUserAuthenticated {
            rootVC = storyboard.instantiateViewController(
                withIdentifier: String(describing: CarListViewController.self))
        } else {
            rootVC = storyboard.instantiateViewController(
                withIdentifier: String(describing: LoginViewController.self))
        }

        let navigationController = UINavigationController(rootViewController: rootVC)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app,
                                               open: url,
                                               sourceApplication:
                                                options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                               annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
}
