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
	static let initialColorScheme: StyledColorScheme? = {
		if #available(iOS 11, *) {
			return UIColor.StyledAssetCatalog()
		}
		return nil
	}()
	
	// MARK: Color
	
	/// Notification will be posted when `defaultColorScheme` changes
	/// When notification is raised, read `defaultColorScheme` value
	public static let defaultColorSchemeDidChangeNotification = Notification.Name(rawValue: "StyledDefaultsColorSchemeDidChangeNotification")
	
	/// Defines current `StyledColorScheme` used. (for iOS11 and later default is: `UIColor.StyledAssetCatalog`)
	///
	/// - Note: Will post `defaultColorSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `defaultColorScheme` will trigger the notification.
	public static var defaultColorScheme: StyledColorScheme! = initialColorScheme {
		didSet { NotificationCenter.default.post(name: defaultColorSchemeDidChangeNotification, object: nil) }
	}
	
	/// Holds reference to the observer for `defaultColorSchemeDidChangeNotification`
	var colorNotificationObserver: NSObjectProtocol? = nil
	
	/// Custom `StyledColorScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `defaultColorSchemeDidChangeNotification`
	/// - Note: Setting custom `StyledColorScheme` will stop listening to `defaultColorSchemeDidChangeNotification` and
	/// updates colors with given `StyledColorScheme`
	var customColorScheme: StyledColorScheme? = nil {
		didSet {
			defer { applyColors() }
			if customColorScheme == nil {
				colorNotificationObserver.coalesce(with:
					NotificationCenter.default.addObserver(
						forName: Styled.defaultColorSchemeDidChangeNotification,
						object: nil,
						queue: .main,
						using: { [weak self] _ in self?.applyColors() })
				)
			} else {
				colorNotificationObserver.do { NotificationCenter.default.removeObserver($0) }
				colorNotificationObserver = nil
			}
		}
	}
	
	/// Current `StyledColorScheme`
	var colorScheme: StyledColorScheme { customColorScheme ?? Styled.defaultColorScheme }
	
	/// Will hold `KeyPath` and  closure updates.
	var colorUpdates = Updates<StyledColor>()
	
	/// Calling this method, will update all closures or `KeyPath`s for Color associated with `styled`
	@objc func applyColors() { colorUpdates.refresh(withScheme: colorScheme) }
	
	// MARK: Image
	
	/// Notification will be posted when `defaultImageScheme` changes
	/// When notification is raised, read `defaultImageScheme` value
	public static let defaultImageSchemeDidChangeNotification = Notification.Name(rawValue: "StyledDefaultImageSchemeDidChangeNotification")
	
	/// Defines current `StyledImageScheme` used (default is: `UIImage.StyledAssetCatalog`)
	///
	/// - Note: Will post `defaultImageSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `defaultImageScheme` will trigger the notification.
	public static var defaultImageScheme: StyledImageScheme! = UIImage.StyledAssetCatalog() {
		didSet { NotificationCenter.default.post(name: defaultImageSchemeDidChangeNotification, object: nil) }
	}
	
	/// Holds reference to the observer for `defaultImageSchemeDidChangeNotification`
	var imageNotificationObserver: NSObjectProtocol? = nil
	
	/// Custom `StyledImageScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `defaultImageSchemeDidChangeNotification`
	/// - Note: Setting custom `StyledImageScheme` will stop listening to `defaultImageSchemeDidChangeNotification` and
	/// updates images with given `StyledImageScheme`
	var customImageScheme: StyledImageScheme? = nil {
		didSet {
			defer { applyImages() }
			if customImageScheme == nil {
				imageNotificationObserver.coalesce(with:
					NotificationCenter.default.addObserver(
						forName: Styled.defaultImageSchemeDidChangeNotification,
						object: nil,
						queue: .main,
						using: { [weak self] _ in self?.applyImages() })
				)
			} else {
				imageNotificationObserver.do { NotificationCenter.default.removeObserver($0) }
				imageNotificationObserver = nil
			}
		}
	}
	
	/// Current `StyledImageScheme`
	var imageScheme: StyledImageScheme { customImageScheme ?? Styled.defaultImageScheme }
	
	/// Will hold `KeyPath` and  closure updates.
	var imageUpdates = Updates<StyledImage>()
	
	/// Calling this method, will update all closures or `KeyPath`s for Image associated with `styled`
	@objc func applyImages() { imageUpdates.refresh(withScheme: imageScheme) }
	
	// MARK: Font
	
	/// Notification will be posted when `defaultFontScheme` changes
	/// When notification is raised, read `defaultFontScheme` value
	public static let defaultFontSchemeDidChangeNotification = Notification.Name(rawValue: "StyledDefaultFontSchemeDidChangeNotification")
	
	/// Defines current `StyledFontScheme` used (default is `UIFont.StyledSystemFontCategory`)
	///
	/// - Note: Will post `defaultFontSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `defaultFontScheme` will trigger the notification.
	public static var defaultFontScheme: StyledFontScheme! = UIFont.StyledSystemFontCategory() {
		didSet { NotificationCenter.default.post(name: defaultFontSchemeDidChangeNotification, object: nil) }
	}
	
	/// Holds reference to the observer for `fontSchemeDidChangeNotification`
	var fontNotificationObserver: NSObjectProtocol? = nil
	
	/// Custom `StyledFontScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `defaultFontSchemeDidChangeNotification`
	/// - Note: Setting custom `StyledFontScheme` will stop listening to `defaultFontSchemeDidChangeNotification` and
	/// updates fonts with given `StyledFontScheme`
	var customFontScheme: StyledFontScheme? = nil {
		didSet {
			defer { applyFonts() }
			if customFontScheme == nil {
				fontNotificationObserver.coalesce(with:
					NotificationCenter.default.addObserver(
						forName: Styled.defaultFontSchemeDidChangeNotification,
						object: nil,
						queue: .main,
						using: { [weak self] _ in self?.applyFonts() })
				)
			} else {
				fontNotificationObserver.do { NotificationCenter.default.removeObserver($0) }
				fontNotificationObserver = nil
			}
		}
	}
	
	/// Current `StyledFontScheme`
	var fontScheme: StyledFontScheme { customFontScheme ?? Styled.defaultFontScheme }
	
	/// Will hold `KeyPath` and  closure updates.
	var fontUpdates = Updates<StyledFont>()
	
	/// Calling this method, will update all closures or `KeyPath`s for Font associated with `styled`
	@objc func applyFonts() { fontUpdates.refresh(withScheme: fontScheme) }
	
	/// Creates an Styled class
	///
	/// - Note: Creating an `Styled` instance, will listen to multiple `Notification`s,  It's a good idea to share a `Styled` instance for single object
	///
	public init() {
		customColorScheme = nil
		customImageScheme = nil
		customFontScheme = nil
	}
	
	deinit {
		let center = NotificationCenter.default
		colorNotificationObserver.do { center.removeObserver($0) }
		imageNotificationObserver.do { center.removeObserver($0) }
		fontNotificationObserver.do { center.removeObserver($0) }
	}
}

/// Used to poision Base class in `StyledWrapper` to hold `Styled`
private var associatedStyledHolder: Int8 = 0

// MARK:- StyledWrapper
/// Contains and `Base` object and allows `UIColor`/`UIFont`/`UIImage` and `String` setting based on `currentScheme`s set in `Styled`
@dynamicMemberLookup public struct StyledWrapper<Base: AnyObject> {
	
	/// Base object to extend.
	public let base: Base
	
	// TODO: current schemes? (backed by Default)
	
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
	
	/// Custom `StyledColorScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `defaultColorSchemeDidChangeNotification`
	/// - Note: Setting custom `StyledColorScheme` will stop listening to `defaultColorSchemeDidChangeNotification` and
	/// updates colors with given `StyledColorScheme`
	public var customColorScheme: StyledColorScheme? {
		get { styled.customColorScheme }
		set { styled.customColorScheme = newValue }
	}
	
	/// Calling this method, will update all colors associated with `styled`
	public func applyColors() { styled.applyColors() }
	
	/// Custom `StyledImageScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `defaultImageSchemeDidChangeNotification`
	/// - Note: Setting custom `StyledImageScheme` will stop listening to `defaultImageSchemeDidChangeNotification` and
	/// updates images with given `StyledImageScheme`
	public var customImageScheme: StyledImageScheme? {
		get { styled.customImageScheme }
		set { styled.customImageScheme = newValue }
	}
	
	/// Calling this method, will update all images associated with `styled`
	public func applyImages() { styled.applyImages() }
	
	/// Cusotm `StyledFontScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `defaultFontSchemeDidChangeNotification`
	/// - Note: Setting custom `StyledFontScheme` will stop listening to `defaultFontSchemeDidChangeNotification` and
	/// updates fonts with given `StyledFontScheme`
	public var customFontScheme: StyledFontScheme? {
		get { styled.customFontScheme }
		set { styled.customFontScheme = newValue }
	}
	
	/// Calling this method, will update all fonts associated with `styled`
	public func applyFonts() { styled.applyFonts() }
}

// MARK:- StyledUpdate
extension Styled {
	/// Used to Identify update closures used in `onColorSchemeChange(_), onImageSchemeChange(), onFontSchemeChange()`
	public typealias ClosureId = String
	
	/// Contains list of `StyledItem`s (i.e `StyledColor`, `StyledFont`, `StyledImage`, ...) and a `closures` to act upon `Item.Scheme` change
	struct Updates<Item> where Item: StyledItem {
		
		/// Holds `KeyPath` based variables and their `Update`
		var keyPaths: [AnyKeyPath: Update<Item>] = [:]
		
		/// Holds `Id` of closures passed to `Styled` to get called when `Item.Scheme` changes
		var closures: [ClosureId: () -> ()] = [:]
		
		/// Will call all `Update`.`update`s and Closures
		/// - Parameter scheme: Suitable `Item.Scheme`
		func refresh(withScheme scheme: Item.Scheme) {
			DispatchQueue.main.async {
				self.keyPaths.values.forEach { $0.refresh(scheme) }
				self.closures.values.forEach { $0() }
			}
		}
		
		/// Will query through `keyPaths`
		subscript(_ keyPath: AnyKeyPath) -> Update<Item>? {
			get { keyPaths[keyPath] }
			set { keyPaths[keyPath] = newValue }
		}
		
		/// Will query through `closures`
		subscript(_ id: ClosureId) -> (() -> Void)? {
			get { closures[id] }
			set { closures[id] = newValue }
		}
	}
	
	/// Contains an `StyledItem` (i.e `StyledColor`, `StyledFont`, `StyledImage`, ...) and a closure to Update the `KeyPath` with given `Item`
	struct Update<Item> where Item: StyledItem {
		let item: Item
		let refresh: (Item.Scheme) -> ()
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

// MARK:- Helper

/// Used to encapsulate all `Styled` types
protocol StyledItem { associatedtype Scheme }
extension StyledColor: StyledItem { typealias Scheme = StyledColorScheme }
extension StyledImage: StyledItem { typealias Scheme = StyledImageScheme }
extension StyledFont: StyledItem { typealias Scheme = StyledFontScheme }

private extension Optional {
	
	/// Mutates self to the given value if and only if `self` is `nil`
	/// - Parameter value: WrappedType
	mutating func coalesce(with value: @autoclosure () -> Wrapped) {
		switch self {
		case .none: self = .some(value())
		default: break
		}
	}
	
	/// Will call the closure if `self` is not `nil`
	/// - Parameter action: (`Wrapped`) -> ()
	func `do`(_ action: (Wrapped) -> ()) {
		guard let value = self else { return }
		action(value)
	}
}
