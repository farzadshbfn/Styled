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
	private static var contentSizeCategoryNotificationObserver: NSObjectProtocol?
	
	/// Used internally to detect if `UIUserInterfaceStyle` changes between `light` and `dark`
	@available(iOS 12.0, *)
	private static var userInterfaceStyle: UIUserInterfaceStyle?
	
	/// Returns `UIColor.StyledAssetCatalog` for iOS11 and later.
	private static let initialColorScheme: ColorScheme? = {
		if #available(iOS 11, *) {
			return Color.DefaultScheme()
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
	/// - Note: For iOS 11+ default value is `Color.DefaultScheme` and `nil` otherwise
	public static var colorScheme: ColorScheme! = initialColorScheme {
		didSet { NotificationCenter.default.post(name: colorSchemeNeedsUpdate, object: nil) }
	}
	
	/// Defines current `ImageScheme` used throughout the application
	///
	/// Setting this property will trigger `imageSchemeNeedsUpdate` notification
	///
	/// - Note: Default value is `Image.DefaultScheme`
	public static var imageScheme: ImageScheme! = Image.DefaultScheme() {
		didSet { NotificationCenter.default.post(name: imageSchemeNeedsUpdate, object: nil) }
	}
	
	/// Defines current `FontScheme` used throughout the application
	///
	/// Setting this property will trigger `fontSchemeNeedsUpdate` notification
	///
	/// - Note: Default value is `Font.DefaultScheme`
	public static var fontScheme: FontScheme! = Font.DefaultScheme() {
		didSet { NotificationCenter.default.post(name: fontSchemeNeedsUpdate, object: nil) }
	}
	
	/// Defines current `LocalizedStringScheme` used throughout the application
	///
	/// Setting this property will trigger `localizedStringSchemeNeedsUpdate` notification
	///
	/// - Note: Default value is `LocalizedString.DefaultScheme`
	public static var localizedStringScheme: LocalizedStringScheme! = LocalizedString.DefaultScheme() {
		didSet { NotificationCenter.default.post(name: localizedStringSchemeNeedsUpdate, object: nil) }
	}
}

extension Config {
	
	/// This type is used in `onContentSizeCategoryDidChange(_:)` to determine what to do when `UIContentSizeCategory` changes
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
	
	/// This type is used in `onUserInterfaceStyleDidChange(_:)` to determine what to do when `UIUserInterfaceStyle` changes
	public enum ColorSchemeUpdate {
		/// Will do nothing
		case none
		/// Will only raise `colorSchemeNeedsUpdate` notification
		case update
		/// Will change `colorScheme` with given scheme and raise `colorSchemeNeedsUpdate` notification
		case replace(with: ColorScheme)
	}
	
	/// Call this method to make application respond to `UIUserInterfaceStyle` changes and update colors
	///
	/// - PreCondition: This method should be called only once
	///
	/// - Parameter update: `ColorSchemeUpdate` instance to determine what to do
	@available(iOS 12.0, *)
	public class func onUserInterfaceStyleDidChange(_ update: @escaping (UIUserInterfaceStyle) -> ColorSchemeUpdate) {
		precondition(userInterfaceStyle == nil, "This method should be called only once")
		
		userInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
		
		UIWindow.userInterfaceStyleUpdate = { style in
			guard style != userInterfaceStyle else { return }
			userInterfaceStyle = style
			
			switch update(style) {
			case .none: break
			case .update: NotificationCenter.default.post(name: colorSchemeNeedsUpdate, object: nil)
			case .replace(let scheme): colorScheme = scheme
			}
		}
		
		_ = UIWindow.traitCollectionDidChangeSwizzler
	}
}

@available(iOS 12.0, *)
extension UIWindow {
	
	/// Config uses this method to become aware of `UIUserInterfaceStyle` changes
	fileprivate static var userInterfaceStyleUpdate: ((UIUserInterfaceStyle) -> Void)?
	
	/// Swizzled method of `traitCollectionDidChange(_:)` which calls `userInterfaceStyleUpdate` to inform `Config`
	/// about `UIUserInterfaceStyle` changes
	@objc private func swizzled_traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		UIWindow.userInterfaceStyleUpdate?(traitCollection.userInterfaceStyle)
		swizzled_traitCollectionDidChange(previousTraitCollection)
	}
	
	/// Since `UIKit` does not provide a logical way to be notified when `UIUserInterfaceStyle` changes, We had to swizzle
	/// `traitCollectionDidChange(_:)` method to become aware of `UIUserInterfaceStyle` change. ¯\_(ツ)_/¯
	fileprivate static let traitCollectionDidChangeSwizzler: Void = {
		swizzleMethods(original: #selector(traitCollectionDidChange(_:)),
					   swizzled: #selector(swizzled_traitCollectionDidChange(_:)))
	}()
}
