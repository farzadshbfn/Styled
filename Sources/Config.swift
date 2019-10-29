//
//  Config.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/30/19.
//

import Foundation


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
	public static let colorSchemeDidChange = Notification.Name(rawValue: "StyledColorSchemeDidChangeNotification")
	
	/// Notification will be posted when `imageScheme` changes
	public static let imageSchemeDidChange = Notification.Name(rawValue: "StyledImageSchemeDidChangeNotification")
	
	/// Notification will be posted when `fontScheme` changes
	public static let fontSchemeDidChange = Notification.Name(rawValue: "StyledFontSchemeDidChangeNotification")
	

	/// Defines current `ColorScheme` used throughout the application
	///
	/// Setting this property will trigger `colorSchemeDidChange` notification
	///
	/// - Note: For iOS 11+ default value is `DefaultColorScheme` and `nil` otherwise
	public static var colorScheme: ColorScheme! = initialColorScheme {
		didSet { NotificationCenter.default.post(name: colorSchemeDidChange, object: nil) }
	}
	
	/// Defines current `ImageScheme` used throughout the application
	///
	/// Setting this property will trigger `imageSchemeDidChange` notification
	///
	/// - Note: Default value is `DefaultImageScheme`
	public static var imageScheme: ImageScheme! = DefaultImageScheme() {
		didSet { NotificationCenter.default.post(name: imageSchemeDidChange, object: nil) }
	}
	
	/// Defines current `FontScheme` used throughout the application
	///
	/// Setting this property will trigger `fontSchemeDidChange` notification
	///
	/// - Note: Default value is `DefaultFontScheme`
	public static var fontScheme: FontScheme! = DefaultFontScheme() {
		didSet { NotificationCenter.default.post(name: fontSchemeDidChange, object: nil) }
	}
}

// MARK:- Typealises
/// Used to fix namespace conflicts
public typealias StyledConfig = Config
