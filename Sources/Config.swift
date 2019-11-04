//
//  Config.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/30/19.
//

import Foundation
import UIKit

/// Contains Configurations for `Styled` to operate
public final class Config {
	
	/// Used internally to keep receiving `UIContentSizeCategory.didChangeNotification` events
	static var contentSizeCategoryNotificationObserver: NSObjectProtocol?
	
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
	
	/// Notification will be posted when `localizedStringScheme` changes
	public static let localizedStringSchemeNeedsUpdate = Notification.Name(rawValue: "StyledLocalizedStringSchemeNeedsUpdateNotification")
	

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
	
	/// Defines current `LocalizedStringScheme` used throughout the application
	///
	/// Setting this property will trigger `localizedStringSchemeNeedsUpdate` notification
	///
	/// - Note: Default value is `DefaultLocalizedStringScheme`
	public static var localizedStringScheme: LocalizedStringScheme! = DefaultLocalizedStringScheme() {
		didSet { NotificationCenter.default.post(name: localizedStringSchemeNeedsUpdate, object: nil) }
	}
}

extension Config {
	
	/// This type is used in `onContentSizeCategoryDidChange(_:)` to determine what to do
	public enum FontSchemeUpdate {
		/// Will do nothing
		case none
		/// Will only raise `fontSchemeNeedsUpdate` notification
		case update
		/// Will change `fontScheme` with given scheme and raise `fontSchemeNeedsUpdate` notification
		case replace(with: FontScheme)
	}
	
	/// Call this method to make application respond to `UIContentSizeCategory.didChangeNotification` and update fonts
	///
	/// - PreCondition: This method should be called only once
	///
	/// - Parameter update: `FontSchemeUpdate` instance to determine what to do
	public class func onContentSizeCategoryDidChange(_ update: @escaping (UIContentSizeCategory) -> FontSchemeUpdate) {
		precondition(contentSizeCategoryNotificationObserver == nil, "This method should be called only once")
		
		contentSizeCategoryNotificationObserver = NotificationCenter.default.addObserver(
			forName: UIContentSizeCategory.didChangeNotification,
			object: nil,
			queue: .main,
			using: { notif in
				guard let contentSizeCategory = notif.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory
					else { return }
				switch update(contentSizeCategory) {
				case .none: break
				case .update: NotificationCenter.default.post(name: fontSchemeNeedsUpdate, object: nil)
				case .replace(let scheme): fontScheme = scheme
				}
		})
	}
}
