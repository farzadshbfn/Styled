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
		
		let df = DateFormatter()
		df.dateFormat = "dd/mm/yyyy"
		
		let key: LocalizedString = "khiar \(Date(), formatter: df)"
		
		dump(key)
		return true
	}
}
