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
	
	// MARK: Settings
	/// Notification will be posted when `colorScheme` changes
	/// When notification is raised, read `colorScheme` value
	public static let colorSchemeDidChangeNotification = Notification.Name(rawValue: "StyledColorSchemeDidChangeNotification")
	
	/// Defines current `ColorScheme` used
	///
	/// - Note: Will post `colorSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `colorScheme` will trigger the notification.
	public static var colorScheme: StyledColorScheme! = nil {
		didSet { NotificationCenter.default.post(name: colorSchemeDidChangeNotification, object: nil) }
	}
	
	/// Notification will be posted when `ImageScheme` changes
	/// When notification is raised, read `imageScheme` value
	public static let imageSchemeDidChangeNotification = Notification.Name(rawValue: "StyledImageSchemeDidChangeNotification")
	
	/// Defines current `ImageScheme` used
	///
	/// - Note: Will post `ImageSchemeDidChangeNotification` notification when changed
	/// - Note: re-setting the same `imageScheme` will trigger the notification.
	public static var imageScheme: StyledImageScheme! = nil {
		didSet { NotificationCenter.default.post(name: imageSchemeDidChangeNotification, object: nil) }
	}
	
	/// Will hold Observers for defined Notifications
	var observers: [NSObjectProtocol] = []
	
	/// Will hold `KeyPath`s and `Update` instances to update colors when needed
	var colors: [AnyKeyPath: Update<StyledColor>] = [:]
	
	/// Will hold `KeyPath`s and `Update` instances to update images when needed
	var images: [AnyKeyPath: Update<StyledImage>] = [:]
	
	/// Creates an Styled class
	///
	/// - Note: Creating an `Styled` instance, will listen to multiple `Notification`s,  It's a good idea to share a `Styled` instance for single object
	///
	public init() {
		let center = NotificationCenter.default
		self.observers = [
			center.addObserver(forName: Styled.colorSchemeDidChangeNotification,
							   object: nil,
							   queue: .main,
							   using: { [weak self] _ in self?.applyColors() }),
			center.addObserver(forName: Styled.imageSchemeDidChangeNotification,
							   object: nil,
							   queue: .main,
							   using: { [weak self] _ in self?.applyImages() })
		]
	}
	
	deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }
	
	/// Calling this method, will update all colors associated with `styled`
	@objc func applyColors() {
		DispatchQueue.main.async { self.colors.values.forEach { $0.update() } }
	}
	
	/// Calling this method, will update all images associated with `styled`
	@objc func applyImages() {
		DispatchQueue.main.async { self.images.values.forEach { $0.update() } }
	}
}

/// Used to poision Base class in `StyledWrapper` to hold `Styled`
private var associatedStyledHolder: Int8 = 0

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
	
	/// Calling this method, will update all colors associated with `styled`
	public func applyColors() { styled.applyColors() }
	
	/// Calling this method, will update all images associated with `styled`
	public func applyImages() { styled.applyImages() }
}

// MARK:- StyledUpdate
/// Contains an `StyledItem` (i.e `StyledColor`, `StyledFont`, `StyledImage`, ...) and a closure to Update the `KeyPath` with given `Value`
struct StyledUpdate<Value> {
	let value: Value
	let update: () -> ()
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

// MARK:- Typealiases
extension Styled {
	typealias Color = StyledColor
	typealias ColorScheme = StyledColorScheme
	
	typealias Update = StyledUpdate
}
