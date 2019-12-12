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
		
		/// Configuring `Styled` to respect device's `UIContentSizeCategory` and update accessibility font sizes
		Styled.Config.onContentSizeCategoryDidChange { _ in .update }
		
		/// Configuring `Styled` to respect device's `UIUserInterfaceStyle` and update application with
		/// a suitable `ColorScheme`
		if #available(iOS 12.0, *) {
			Styled.Config.onUserInterfaceStyleDidChange {
				switch $0 {
				case .dark: return .replace(with: Color.DarkScheme())
				default: return .replace(with: Color.LightScheme())
				}
			}
			Styled.Config.colorScheme = Color.LightScheme()
		}
		
		return true
	}
}
