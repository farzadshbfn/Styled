//
//  AppDelegate.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import UIKit
import Styled

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		/// Configuring `Styled` to respect device's `UIContentSizeCategory`
		Styled.Config.onContentSizeCategoryDidChange { _ in .update }
		
		return true
	}
}
