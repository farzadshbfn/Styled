//
//  Color.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import class UIKit.UIColor

// MARK:- StyledColor
/// Used to fetch color on runtime based on current `StyledColorScheme`
///
/// - Important: It's important to follow **dot.case** syntax while defining name of colors. e.g `primary`, `primary.lvl1`
/// in-order to let them be pattern-matched
///
/// - Note: In pattern-matching, matches with `pattern` if it is *prefix* of given `Color`. For more information see `~=`. You can
/// disable this behavior by setting `isPrefixMatchingEnabled` to `false`
///
/// Sample usage:
///
/// 	extension StyledColor {
/// 	    static let primary  = Self("primary")
/// 	    static let primary1 = Self("primary.lvl1")
/// 	    static let primary2 = Self("primary.lvl2")
/// 	}
///
/// 	view.styled.backgroundColor = .primary
/// 	label.styled.textColor = .opacity(0.9, of: .primary)
/// 	layer.styled.backgroundColor = .primary
///
/// `StyledColor` uses custom pattern-matchin.  in the example given, `primary2` would match
/// with `primary` if it is checked before `primary2`:
///
///  	switch StyledColor.primary2 {
///  	case .primary: // Will match ✅
///  	case .primary2: // Will not match ❌
///  	}
///
/// And without `isPrefixMatchingEnabled`:
///
/// 	StyledColor.isPrefixMatchingEnabled = false
/// 	switch StyledColor.primary2 {
///  	case .primary: // Will not match ❌
///  	case .primary2: // Will match ✅
///  	}
///
/// - SeeAlso: `~=` method in this file
public struct StyledColor: Hashable, CustomStringConvertible ,ExpressibleByStringLiteral {
	/// A type that represents a `StyledColor` name
	public typealias StringLiteralType = String
	
	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `primary.lvl1` can be matched with `primary`
	public static var isPrefixMatchingEnabled: Bool = true
	
	/// Initiates a `StyledColor` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Colors
	///
	/// - Parameter name: Name of the color.
	public init(_ name: String) { resolver = .name(name) }
	
	/// This type is used internally to manage transformations if applied to current `StyledColor` before fetching `UIColor`
	let resolver: Resolver
	
	/// Name of the `StyledColor`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `StyledColor`, hence no specific `name` is available
	///
	public var name: String? {
		switch resolver {
		case .name(let name): return name
		default: return nil
		}
	}
	
	/// Describes specification of `UIColor` that will be *fetched*/*generated*
	///
	///  - Note: `StyledColor`s with transformations will not be sent to `StyledColorScheme`s directly
	///  - Note: If description contains `{...}` it means this `StyledColor` contains transformations
	///
	///  Samples:
	///
	/// 	StyledColor("primary")
	/// 	// description: "primary"
	/// 	StyledColor.blending(.primary, 0.30, .secondary)
	/// 	// description: "{primary*0.30+secondary*0.70}"
	/// 	StyledColor.primary.blend(with: .black)
	/// 	// description: "{primary*0.50+UIColor(0.00 0.00 0.00 0.00)*0.50}"
	/// 	StyledColor.opacity(0.9, of: .primary)
	/// 	// description: "{primary(0.90)}"
	/// 	StyledColor.primary.transform { $0 }
	/// 	// description: "{primary->t}"
	/// 	StyledColor("primary", bundle: .main)
	/// 	// description: "{primary(com.farzadshbfn.styled)}"
	///
	public var description: String { resolver.description }
	
	/// Ease of use on defining `StyledColor` variables
	///
	/// 	extension StyledColor {
	/// 	    static let primary:   Self = "primary"
	/// 	    static let secondary: Self = "secondary"
	/// 	}
	///
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }
	
	/// Enables the pattern-matcher (i.e switch-statement) to patch `primary.lvl1` with `primary` if `primary.lvl1` is not available
	/// in the switch-statement
	///
	/// - Parameter pattern: `StyledColor` to match as prefix of the current value
	/// - Parameter value: `StyledColor` given to find the best match for
	@inlinable public static func ~=(pattern: StyledColor, value: StyledColor) -> Bool {
		isPrefixMatchingEnabled ? value.description.hasPrefix(pattern.description) : value == pattern
	}
}

extension StyledColor {
	
	/// Internal type to manage Lazy or direct fetching of `UIColor`
	enum Resolver: Hashable, CustomStringConvertible {
		case name(String)
		case lazy(Lazy)
		
		/// Contains description of current `Resolver` state.
		///
		/// - Note: `Lazy` is surrounded by `{...}`
		///
		var description: String {
			switch self {
			case .name(let name): return name
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}
	
	/// This type is used to support transformations on `StyledColor` like `.blend`
	struct Lazy: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `StyledColor` in order to let `StyledColor` hold `Lazy` in its definition
		let colorHashValue: Int
		
		/// Describes current color that will be returned
		let colorDescription: String
		
		/// Describes current color that will be returned
		var description: String { colorDescription }
		
		/// Provides `UIColor` which can be backed by `StyledColor` or static `UIColor`
		let color: (_ scheme: StyledColorScheme) -> UIColor?
		
		/// Used internally to pre-calculate hashValue of Internal `color`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIColor` from `StyledColor` when needed
		init(_ styledColor: StyledColor) {
			colorHashValue = Self.hashed("StyledColor", styledColor)
			colorDescription = styledColor.description
			color = styledColor.resolve
		}
		
		/// Will directly propagate given `UIColor` when needed
		init(_ uiColor: UIColor) {
			colorHashValue = Self.hashed("UIColor", uiColor)
			colorDescription = "\(uiColor.styledDescription)"
			color = { _ in uiColor }
		}
		
		/// Will use custom Provider to provide `UIColor` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ colorProvider: @escaping (_ scheme: StyledColorScheme) -> UIColor?) {
			colorHashValue = Self.hashed("ColorProvider", name)
			colorDescription = name
			color = colorProvider
		}
		
		/// - Returns: `hashValue` of given parameters when initializing `Lazy`
		func hash(into hasher: inout Hasher) { hasher.combine(colorHashValue) }
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: Lazy, rhs: Lazy) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// This method is used internally to manage transformations (if any) and provide `UIColor`
	/// - Parameter scheme:A `StyledColorScheme` to fetch `UIColor` from
	func resolve(from scheme: StyledColorScheme) -> UIColor? {
		switch resolver {
		case .name: return scheme.color(for: self)
		case .lazy(let lazy): return lazy.color(scheme)
		}
	}
	
	/// Enables `StyledColor` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
	
	/// Blends `self`  to the other `Lazy` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `Lazy`
	/// - Returns: `from * perc + to * (1 - perc)`
	func blend(_ perc: Double, _ to: Lazy) -> StyledColor {
		let fromDesc = "\(self)*\(String(format: "%.2f", perc))"
		let toDesc = "\(to)*\(String(format: "%.2f", 1 - perc))"
		return .init(lazy: .init(name: "\(fromDesc)+\(toDesc)") { scheme in
			guard let fromUIColor = self.resolve(from: scheme) else { return to.color(scheme) }
			guard let toUIColor = to.color(scheme) else { return fromUIColor }
			return fromUIColor.blend(CGFloat(perc), with: toUIColor)
			})
	}
	
	/// Blends `self` to the other `StyeledColor` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `StyeledColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public func blend(_ perc: Double = 0.5, with to: StyledColor) -> StyledColor { blend(perc, .init(to)) }
	
	/// Blends `self` to the other `UIColor` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `UIColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public func blend(_ perc: Double = 0.5, with to: UIColor) -> StyledColor { blend(perc, .init(to)) }
	
	/// Blends two `StyledColor`s together with the amount given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter from: `StyledColor` to pour from
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `StyeledColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public static func blending(_ from: StyledColor, _ perc: Double = 0.5, with to: StyledColor) -> StyledColor { from.blend(perc, with: to) }
	
	/// Blends a `StyledColor` and `UIColor` together with the amount given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter from: `StyledColor` to pour from
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `UIColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public static func blending(_ from: StyledColor, _ perc: Double = 0.5, with to: UIColor) -> StyledColor { from .blend(perc, with: to) }
	
	/// Set's `opacity` level
	/// - Parameter perc: will be clamped to `[`**0.0**, **1.0**`]`
	/// - Returns: new instance of `self` with given `opacity`
	public func opacity(_ perc: Double) -> StyledColor {
		return .init(lazy: .init(name: "\(self)(\(String(format: "%.2f", perc)))") { scheme in
			self.resolve(from: scheme)?.withAlphaComponent(CGFloat(perc))
			})
	}
	
	/// Set's `opacity` level of the given `color`
	/// - Parameter perc: will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter color: `StyledColor`
	/// - Returns: new instance of `color` with given `opacity`
	public static func opacity(_ perc: Double, of color: StyledColor) -> StyledColor { color.opacity(perc) }
	
	/// Applies custom transformations on the `UIColor`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIColor`
	public func transform(named name: String = "t", _ transform: @escaping (UIColor) -> UIColor) -> StyledColor {
		return .init(lazy: .init(name: "\(self)->\(name)", { scheme in
			guard let color = self.resolve(from: scheme) else { return nil }
			return transform(color)
		}))
	}
	
	/// Applies custom transformations on the `UIColor` fetched from `StyledColor`
	/// - Parameter styledColor: `StyledColor` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIColor`
	public static func transforming(_ styledColor: StyledColor,
									named name: String = "t",
									_ transform: @escaping (UIColor) -> UIColor) -> StyledColor {
		styledColor.transform(named: name, transform)
	}
}

// MARK:- StyledColorScheme
/// Use this protocol to provide `UIColor` for `Styled`
///
/// Sample:
///
/// 	struct DarkColorScheme: StyledColorScheme {
/// 	    func color(for styledColor: StyledColor) -> UIColor? {
/// 	        switch styledColor {
/// 	        case .primary: // return primary color
/// 	        case .secondary: // return secondary color
/// 	        default: fatalError("Forgot to support \(styledColor)")
/// 	        }
/// 	    }
/// 	}
///
public protocol StyledColorScheme {
	
	/// `Styled` will use this method to fetch `UIColor`
	///
	/// - Important: **Do not** call this method directly. use `UIColor.styled(_:)` instead.
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `styledColor`
	///
	/// - Note: It's guaranteed all `StyledColor`s sent to this message, will contain field `name`
	///
	/// Sample for `DarkColorScheme`:
	///
	/// 	struct DarkColorScheme: StyledColorScheme {
	/// 	    func color(for styledColor: StyledColor) -> UIColor? {
	/// 	        switch styledColor {
	/// 	        case .primary1: // return primary level1 color
	/// 	        case .primary2: // return primary level2 color
	/// 	        default: fatalError("Forgot to support \(styledColor)")
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter styledColor: `StyledColor` type to fetch `UIColor` from current scheme
	func color(for styledColor: StyledColor) -> UIColor?
}

// MARK:- StyledAssetCatalog
extension UIColor {
	
	/// Will fetch `StyledColor`s from Assets Catalog
	///
	/// - Note: if `StyledColor.isPrefixMatchingEnabled` is `true`, in case of failure at loading `a.b.c.d`
	/// will look for `a.b.c` and if `a.b.c` is failed to be loaded, will look for `a.b` and so on.
	/// Will return `nil` if nothing were found.
	///
	/// - SeeAlso: `StyledColor(_:,bundle:)`
	@available(iOS 11, *)
	public struct StyledAssetCatalog: StyledColorScheme {
		
		public func color(for styledColor: StyledColor) -> UIColor? {
			.named(styledColor.description, in: nil)
		}
		
		public init() { }
	}
}

extension StyledColor {
	/// Fetches `UIColor` from ColorAsset defined in given `Bundle`
	/// - Parameter name: Name of the color to look-up in Assets Catalog
	/// - Parameter bundle: `Bundle` to look into it's Assets
	/// - SeeAlso: `XcodeAssetsStyledColorScheme`
	@available(iOS 11, *)
	public init(_ name: String, bundle: Bundle) {
		resolver = .lazy(.init(name: "\(name)(\(bundle.bundleIdentifier ?? "bundle.not.found"))") {
			$0.color(for: .init(name)) ?? UIColor.named(name, in: bundle)
			})
	}
}

// MARK: UIColor+Extensions
extension UIColor {
	
	/// Will look in the Assets catalog in given `Bundle` for the given color
	///
	/// - Note: if `StyledColor.isPrefixMatchingEnabled` is `true` will try all possbile variations
	///
	/// - Parameter styledColorName: `String` name of the `StyledColor` (mostly it's description"
	/// - Parameter bundle: `Bundle` to look into it's Assets Catalog
	@available(iOS 11, *)
	fileprivate class func named(_ styledColorName: String, in bundle: Bundle?) -> UIColor? {
		guard StyledColor.isPrefixMatchingEnabled else {
			return UIColor(named: styledColorName, in: bundle, compatibleWith: nil)
		}
		var name = styledColorName
		while name != "" {
			if let color = UIColor(named: name, in: bundle, compatibleWith: nil) { return color }
			name = name.split(separator: ".").dropLast().joined(separator: ".")
		}
		return nil
	}
	
	/// Returns a simple description for UIColor to use in `Lazy`
	fileprivate var styledDescription: String {
		var color = (r: 0.0 as CGFloat, g: 0.0 as CGFloat, b: 0.0 as CGFloat, a: 0.0 as CGFloat)
		self.getRed(&color.r, green: &color.g, blue: &color.b, alpha: &color.a)
		let r = String(format: "%.2f", color.r)
		let g = String(format: "%.2f", color.g)
		let b = String(format: "%.2f", color.b)
		let a = String(format: "%.2f", color.a)
		return "UIColor(\(r) \(g) \(b) \(a))"
	}
	
	/// Will fetch `UIColor` defined in given `StyledColorScheme`
	///
	/// - Parameter styledColor: `StyledColor`
	/// - Parameter scheme: `StyledColorScheme` to search for color. (default: `Styled.defaultColorScheme`)
	open class func styled(_ styledColor: StyledColor, from scheme: StyledColorScheme = Styled.defaultColorScheme) -> UIColor? {
		styledColor.resolve(from: scheme)
	}
	
	/// Blends current color with the other one.
	///
	/// - Important: `perc` **1.0** means to omit other color while `perc` **0.0** means to omit current color
	///
	/// - Parameter perc: Will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter color: other `UIColor` to blend with. (Passing `.clear` will decrease opacity)
	open func blend(_ perc: CGFloat = 0.5, with color: UIColor) -> UIColor {
		let perc = min(max(0.0, perc), 1.0)
		var col1 = (r: 0.0 as CGFloat, g: 0.0 as CGFloat, b: 0.0 as CGFloat, a: 0.0 as CGFloat)
		var col2 = (r: 0.0 as CGFloat, g: 0.0 as CGFloat, b: 0.0 as CGFloat, a: 0.0 as CGFloat)
		
		self.getRed(&col1.r, green: &col1.g, blue: &col1.b, alpha: &col1.a)
		color.getRed(&col2.r, green: &col2.g, blue: &col2.b, alpha: &col2.a)
		
		let percComp = 1 - perc
		
		return UIColor(red:   col1.r * perc + col2.r * percComp,
					   green: col1.g * perc + col2.g * percComp,
					   blue:  col1.b * perc + col2.b * percComp,
					   alpha: col1.a * perc + col2.a * percComp)
	}
}

// MARK:- StyledWrapper
extension StyledWrapper {
	
	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ styledColor: StyledColor?, _ apply: @escaping (Base, UIColor?) -> Void) -> Styled.Update<StyledColor>? {
		guard let styledColor = styledColor else { return nil }
		let styledUpdate = Styled.Update(item: styledColor) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, styledColor.resolve(from: scheme))
		}
		styledUpdate.update(styled.colorScheme)
		return styledUpdate
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `StyledColor`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIColor>) -> StyledColor? {
		get { styled.colors[keyPath]?.item }
		set { styled.colors[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1! : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `StyledColor`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIColor?>) -> StyledColor? {
		get { styled.colors[keyPath]?.item }
		set { styled.colors[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `StyledColor`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGColor>) -> StyledColor? {
		get { styled.colors[keyPath]?.item }
		set { styled.colors[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1!.cgColor : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `StyledColor`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGColor?>) -> StyledColor? {
		get { styled.colors[keyPath]?.item }
		set { styled.colors[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.cgColor } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `StyledColor`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIColor>) -> StyledColor? {
		get { styled.colors[keyPath]?.item }
		set { styled.colors[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1!.ciColor : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `StyledColor`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIColor?>) -> StyledColor? {
		get { styled.colors[keyPath]?.item }
		set { styled.colors[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.ciColor } }
	}
}
