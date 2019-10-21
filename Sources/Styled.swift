//
//  Styled.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import UIKit

// MARK:- Styled
public final class Styled {
	
	/// Returns `UIColor.StyledAssetCatalog` for iOS11 and later.
	static let defaultColorScheme: StyledColorScheme? = {
		if #available(iOS 11, *) {
			return UIColor.StyledAssetCatalog()
		}
		return nil
	}()
	
	// MARK: Color
	
	/// Notification will be posted when `colorScheme` changes
	/// When notification is raised, read `colorScheme` value
	public static let colorSchemeDidChangeNotification = Notification.Name(rawValue: "StyledColorSchemeDidChangeNotification")
	
	/// Defines current `StyledColorScheme` used. (for iOS11 and later default is: `UIColor.StyledAssetCatalog`)
	///
	/// - Note: Will post `colorSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `colorScheme` will trigger the notification.
	public static var colorScheme: StyledColorScheme! = defaultColorScheme {
		didSet { NotificationCenter.default.post(name: colorSchemeDidChangeNotification, object: nil) }
	}
	
	/// Holds reference to the observer for `colorSchemeDidChangeNotification`
	var colorNotificationObserver: NSObjectProtocol? = nil
	
	/// This flag controls wether the class should listen to `colorSchemeDidChangeNotification` or not
	var autoUpdatesColors: Bool {
		get { colorNotificationObserver != nil }
		set {
			if newValue, colorNotificationObserver == nil {
				colorNotificationObserver = NotificationCenter.default.addObserver(
					forName: Styled.colorSchemeDidChangeNotification,
					object: nil,
					queue: .main,
					using: { [weak self] _ in self?.applyColors() }
				)
			}
			else if let observer = colorNotificationObserver {
				NotificationCenter.default.removeObserver(observer)
			}
		}
	}
	
	/// Will hold `KeyPath`s and `Update` instances to update colors when needed
	var colors: [AnyKeyPath: Update<StyledColor>] = [:]
	
	/// Calling this method, will update all colors associated with `styled`
	@objc func applyColors() {
		DispatchQueue.main.async { self.colors.values.forEach { $0.update() } }
	}
	
	// MARK: Image
	
	/// Notification will be posted when `imageScheme` changes
	/// When notification is raised, read `imageScheme` value
	public static let imageSchemeDidChangeNotification = Notification.Name(rawValue: "StyledImageSchemeDidChangeNotification")
	
	/// Defines current `StyledImageScheme` used (default is: `UIImage.StyledAssetCatalog`)
	///
	/// - Note: Will post `imageSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `imageScheme` will trigger the notification.
	public static var imageScheme: StyledImageScheme! = UIImage.StyledAssetCatalog() {
		didSet { NotificationCenter.default.post(name: imageSchemeDidChangeNotification, object: nil) }
	}
	
	/// Holds reference to the observer for `imageSchemeDidChangeNotification`
	var imageNotificationObserver: NSObjectProtocol? = nil
	
	/// This flag controls wether the class should listen to `imageSchemeDidChangeNotification` or not
	var autoUpdatesImages: Bool {
		get { imageNotificationObserver != nil }
		set {
			if newValue, imageNotificationObserver == nil {
				imageNotificationObserver = NotificationCenter.default.addObserver(
					forName: Styled.imageSchemeDidChangeNotification,
					object: nil,
					queue: .main,
					using: { [weak self] _ in self?.applyImages() }
				)
			}
			else if let observer = imageNotificationObserver {
				NotificationCenter.default.removeObserver(observer)
			}
		}
	}
	
	/// Will hold `KeyPath`s and `Update` instances to update images when needed
	var images: [AnyKeyPath: Update<StyledImage>] = [:]
	
	/// Calling this method, will update all images associated with `styled`
	@objc func applyImages() {
		DispatchQueue.main.async { self.images.values.forEach { $0.update() } }
	}
	
	// MARK: Font
	
	/// Notification will be posted when `fontScheme` changes
	/// When notification is raised, read `fontScheme` value
	public static let fontSchemeDidChangeNotification = Notification.Name(rawValue: "StyledFontSchemeDidChangeNotification")
	
	/// Defines current `StyledFontScheme` used (default is `UIFont.StyledSystemFontCategory`)
	///
	/// - Note: Will post `fontSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `fontScheme` will trigger the notification.
	public static var fontScheme: StyledFontScheme! = UIFont.StyledSystemFontCategory() {
		didSet { NotificationCenter.default.post(name: fontSchemeDidChangeNotification, object: nil) }
	}
	
	/// Holds reference to the observer for `fontSchemeDidChangeNotification`
	var fontNotificationObserver: NSObjectProtocol? = nil
	
	/// This flag controls wether the class should listen to `fontSchemeDidChangeNotification` or not
	var autoUpdatesFonts: Bool {
		get { fontNotificationObserver != nil }
		set {
			if newValue, fontNotificationObserver == nil {
				fontNotificationObserver = NotificationCenter.default.addObserver(
					forName: Styled.fontSchemeDidChangeNotification,
					object: nil,
					queue: .main,
					using: { [weak self] _ in self?.applyFonts() }
				)
			}
			else if let observer = fontNotificationObserver {
				NotificationCenter.default.removeObserver(observer)
			}
		}
	}
	
	/// Will hold `KeyPath`s and `Update` instances to update fonts when needed
	var fonts: [AnyKeyPath: Update<StyledFont>] = [:]
	
	/// Calling this method, will update all fonts associated with `styled`
	@objc func applyFonts() {
		DispatchQueue.main.async { self.fonts.values.forEach { $0.update() } }
	}
	
	/// Creates an Styled class
	///
	/// - Note: Creating an `Styled` instance, will listen to multiple `Notification`s,  It's a good idea to share a `Styled` instance for single object
	///
	public init() {
		autoUpdatesColors = true
		autoUpdatesImages = true
		autoUpdatesFonts = true
	}
	
	deinit {
		autoUpdatesColors = false
		autoUpdatesImages = false
		autoUpdatesFonts = false
	}
}

/// Used to poision Base class in `StyledWrapper` to hold `Styled`
private var associatedStyledHolder: Int8 = 0

// MARK:- StyledWrapper
/// Contains and `Base` object and allows `UIColor`/`UIFont`/`UIImage` and `String` setting based on `currentScheme`s set in `Styled`
@dynamicMemberLookup public struct StyledWrapper<Base: AnyObject> {
	
	/// Base object to extend.
	public let base: Base
	
	/// Singular instance for all `StyledWrappers` due to performance reasons to share `Notification` events
	var styled: Styled {
		objc_sync_enter(base); defer { objc_sync_exit(base) }
		
		guard let obj = objc_getAssociatedObject(base, &associatedStyledHolder) as? Styled else {
			let obj = Styled()
			objc_setAssociatedObject(base, &associatedStyledHolder, obj, .OBJC_ASSOCIATION_RETAIN)
			return obj
		}
		return obj
	}
	
	/// Creates extensions with base object for `UIColor`/`UIFont`/`UIImage` and `String` setting
	///
	/// - Parameter base: Base object
	init(base: Base) { self.base = base }
	
	/// This flag controls wether to listen to `colorSchemeDidChangeNotification` or not
	public var autoUpdatesColors: Bool {
		get { styled.autoUpdatesColors }
		set { styled.autoUpdatesColors = newValue }
	}
	
	/// Calling this method, will update all colors associated with `styled`
	public func applyColors() { styled.applyColors() }
	
	/// This flag controls wether to listen to `imageSchemeDidChangeNotification` or not
	public var autoUpdatesImages: Bool {
		get { styled.autoUpdatesImages }
		set { styled.autoUpdatesImages = newValue }
	}
	
	/// Calling this method, will update all images associated with `styled`
	public func applyImages() { styled.applyImages() }
	
	/// This flag controls wether to listen to `fontSchemeDidChangeNotification` or not
	public var autoUpdatesFonts: Bool {
		get { styled.autoUpdatesFonts }
		set { styled.autoUpdatesFonts = newValue }
	}
	
	/// Calling this method, will update all fonts associated with `styled`
	public func applyFonts() { styled.applyFonts() }
}

// MARK:- StyledUpdate
extension Styled {
	
	/// Contains an `StyledItem` (i.e `StyledColor`, `StyledFont`, `StyledImage`, ...) and a closure to Update the `KeyPath` with given `Value`
	struct Update<Value> {
		let value: Value
		let update: () -> ()
	}
}


// MARK:- StyledCompatbile
/// A type that enables any object to be Stylable
public protocol StyledCompatible: AnyObject {
	associatedtype StyledBase: AnyObject
	
	/// Use this variable to set  `StyedColor`s, `StyledFont`s, `StyledImage`s  and ...
	var styled: StyledWrapper<StyledBase> { get }
}

extension StyledCompatible {
	
	public var styled: StyledWrapper<Self> {
		get { .init(base: self) }
		set { /* Enables styled mutation */ }
	}
}

extension NSObject: StyledCompatible { }
