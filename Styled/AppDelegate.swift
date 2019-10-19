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
		// Override point for customization after application launch.
		
		if #available(iOS 11, *) {
			Styled.colorScheme = StyledColorAssetsCatalog()
		}
		Styled.imageScheme = StyledImageAssetsCatalog()
		
		return true
	}
}
