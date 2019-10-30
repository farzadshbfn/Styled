//
//  Styled.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import UIKit

/// Used to Identify update closures used in `onColorSchemeChange(_), onImageSchemeChange(), onFontSchemeChange()`
public typealias ClosureIdentifier = String

// MARK:- Styled
public final class Styled {
	
	// MARK: Color
	
	/// Holds reference to the observer for `Config.colorSchemeDidChange`
	var colorNotificationObserver: NSObjectProtocol? = nil
	
	/// Custom `ColorScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.colorSchemeDidChange`
	/// - Note: Setting custom `ColorScheme` will stop listening to `Config.colorSchemeDidChange` and
	/// updates colors with given `ColorScheme`
	var customColorScheme: ColorScheme? = nil {
		didSet {
			defer { applyColors() }
			if customColorScheme == nil {
				colorNotificationObserver.coalesce(with:
					NotificationCenter.default.addObserver(
						forName: Config.colorSchemeDidChange,
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
	
	/// Current `ColorScheme`
	var colorScheme: ColorScheme { customColorScheme ?? Config.colorScheme }
	
	/// Will hold `KeyPath` and  closure updates.
	var colorUpdates = Updates<Color>()
	
	/// Calling this method, will update all closures or `KeyPath`s for Color associated with `styled`
	@objc func applyColors() { colorUpdates.refresh(withScheme: colorScheme) }
	
	// MARK: Image
	
	/// Holds reference to the observer for `Config.imageSchemeDidChange`
	var imageNotificationObserver: NSObjectProtocol? = nil
	
	/// Custom `ImageScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.imageSchemeDidChange`
	/// - Note: Setting custom `ImageScheme` will stop listening to `Config.imageSchemeDidChange` and
	/// updates images with given `ImageScheme`
	var customImageScheme: ImageScheme? = nil {
		didSet {
			defer { applyImages() }
			if customImageScheme == nil {
				imageNotificationObserver.coalesce(with:
					NotificationCenter.default.addObserver(
						forName: Config.imageSchemeDidChange,
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
	
	/// Current `ImageScheme`
	var imageScheme: ImageScheme { customImageScheme ?? Config.imageScheme }
	
	/// Will hold `KeyPath` and  closure updates.
	var imageUpdates = Updates<Image>()
	
	/// Calling this method, will update all closures or `KeyPath`s for Image associated with `styled`
	@objc func applyImages() { imageUpdates.refresh(withScheme: imageScheme) }
	
	// MARK: Font
	
	/// Holds reference to the observer for `fontSchemeDidChangeNotification`
	var fontNotificationObserver: NSObjectProtocol? = nil
	
	/// Custom `FontScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.fontSchemeDidChange`
	/// - Note: Setting custom `FontScheme` will stop listening to `Config.fontSchemeDidChange` and
	/// updates fonts with given `FontScheme`
	var customFontScheme: FontScheme? = nil {
		didSet {
			defer { applyFonts() }
			if customFontScheme == nil {
				fontNotificationObserver.coalesce(with:
					NotificationCenter.default.addObserver(
						forName: Config.fontSchemeDidChange,
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
	
	/// Current `FontScheme`
	var fontScheme: FontScheme { customFontScheme ?? Config.fontScheme }
	
	/// Will hold `KeyPath` and  closure updates.
	var fontUpdates = Updates<Font>()
	
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
	
	/// Custom `ColorScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.colorSchemeDidChange`
	/// - Note: Setting custom `ColorScheme` will stop listening to `Config.colorSchemeDidChange` and
	/// updates colors with given `ColorScheme`
	public var customColorScheme: ColorScheme? {
		get { styled.customColorScheme }
		set { styled.customColorScheme = newValue }
	}
	
	/// Calling this method, will update all colors associated with `styled`
	public func applyColors() { styled.applyColors() }
	
	/// Custom `ImageScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.imageSchemeDidChange`
	/// - Note: Setting custom `ImageScheme` will stop listening to `Config.imageSchemeDidChange` and
	/// updates images with given `ImageScheme`
	public var customImageScheme: ImageScheme? {
		get { styled.customImageScheme }
		set { styled.customImageScheme = newValue }
	}
	
	/// Calling this method, will update all images associated with `styled`
	public func applyImages() { styled.applyImages() }
	
	/// Cusotm `FontScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.fontSchemeDidChange`
	/// - Note: Setting custom `FontScheme` will stop listening to `Config.fontSchemeDidChange` and
	/// updates fonts with given `FontScheme`
	public var customFontScheme: FontScheme? {
		get { styled.customFontScheme }
		set { styled.customFontScheme = newValue }
	}
	
	/// Calling this method, will update all fonts associated with `styled`
	public func applyFonts() { styled.applyFonts() }
}

// MARK:- StyledUpdate
extension Styled {
	
	/// Contains list of `StyledItem`s (i.e `Color`, `Font`, `Image`, ...) and a `closures` to act upon `Item.Scheme` change
	struct Updates<Item> where Item: StyledItem {
		
		/// Holds `KeyPath` based variables and their `Update`
		var keyPaths: [AnyKeyPath: Update<Item>] = [:]
		
		/// Holds `Id` of closures passed to `Styled` to get called when `Item.Scheme` changes
		var closures: [ClosureIdentifier: () -> ()] = [:]
		
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
		subscript(_ id: ClosureIdentifier) -> (() -> Void)? {
			get { closures[id] }
			set { closures[id] = newValue }
		}
	}
	
	/// Contains an `StyledItem` (i.e `Color`, `Font`, `Image`, ...) and a closure to Update the `KeyPath` with given `Item`
	struct Update<Item> where Item: StyledItem {
		let item: Item
		let refresh: (Item.Scheme) -> ()
	}
}


// MARK:- StyledCompatbile
/// A type that enables any object to be Stylable
public protocol StyledCompatible: AnyObject {
	associatedtype StyledBase: AnyObject
	
	/// Use this variable to set  `StyedColor`s, `Font`s, `Image`s  and ...
	var styled: StyledWrapper<StyledBase> { get }
}

extension StyledCompatible {
	
	public var styled: StyledWrapper<Self> {
		get { .init(base: self) }
		set { /* Enables styled mutation */ }
	}
}

extension NSObject: StyledCompatible { }

/// Used to encapsulate all `Styled` types
protocol StyledItem { associatedtype Scheme }
extension Color: StyledItem { typealias Scheme = ColorScheme }
extension Image: StyledItem { typealias Scheme = ImageScheme }
extension Font: StyledItem { typealias Scheme = FontScheme }
