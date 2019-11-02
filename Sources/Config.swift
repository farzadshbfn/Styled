//
//  Config.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/30/19.
//

import Foundation

/// Contains Configurations for `Styled` to operate
public final class Config {
	static let shared = Config()
	
	init() {
	}
	
	/// Returns `UIColor.StyledAssetCatalog` for iOS11 and later.
	static let initialColorScheme: ColorScheme? = {
		if #available(iOS 11, *) {
			return DefaultColorScheme()
		}
		return nil
	}()
	
	/// Notification will be posted when `colorScheme` changes
	public static let colorSchemeNeedsUpdate = Notification.Name(rawValue: "StyledColorSchemeNeedsUpdateNotification")
	
	/// Notification will be posted when `imageScheme` changes
	public static let imageSchemeNeedsUpdate = Notification.Name(rawValue: "StyledImageSchemeNeedsUpdateNotification")
	
	/// Notification will be posted when `fontScheme` changes
	public static let fontSchemeNeedsUpdate = Notification.Name(rawValue: "StyledFontSchemeNeedsUpdateNotification")
	

	/// Defines current `ColorScheme` used throughout the application
	///
	/// Setting this property will trigger `colorSchemeNeedsUpdate` notification
	///
	/// - Note: For iOS 11+ default value is `DefaultColorScheme` and `nil` otherwise
	public static var colorScheme: ColorScheme! = initialColorScheme {
		didSet { NotificationCenter.default.post(name: colorSchemeNeedsUpdate, object: nil) }
	}
	
	/// Defines current `ImageScheme` used throughout the application
	///
	/// Setting this property will trigger `imageSchemeNeedsUpdate` notification
	///
	/// - Note: Default value is `DefaultImageScheme`
	public static var imageScheme: ImageScheme! = DefaultImageScheme() {
		didSet { NotificationCenter.default.post(name: imageSchemeNeedsUpdate, object: nil) }
	}
	
	/// Defines current `FontScheme` used throughout the application
	///
	/// Setting this property will trigger `fontSchemeNeedsUpdate` notification
	///
	/// - Note: Default value is `DefaultFontScheme`
	public static var fontScheme: FontScheme! = DefaultFontScheme() {
		didSet { NotificationCenter.default.post(name: fontSchemeNeedsUpdate, object: nil) }
	}
}
