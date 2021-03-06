//
//  Color.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import class UIKit.UIColor

// MARK: - Color
/// Used to fetch color on runtime based on current `ColorScheme`
///
/// - Important: It's important to follow **dot.case** syntax while defining name of colors. e.g `primary`, `primary.lvl1`
/// in-order to let them be pattern-matched
///
/// - Note: In pattern-matching, matches with `pattern` if it is *prefix* of given `Color`. For more information see `~=`. You can
/// disable this behavior by setting `isPrefixMatchingEnabled` to `false`
///
/// Sample usage:
///
/// 	extension Color {
/// 	    static let primary:  Self = "primary"
/// 	    static let primary1: Self = "primary.lvl1"
/// 	    static let primary2: Self = "primary.lvl2"
/// 	}
///
/// 	view.sd.backgroundColor = .primary
/// 	label.sd.textColor = .opacity(0.9, of: .primary)
/// 	layer.sd.backgroundColor = .primary
///
/// `Color` uses custom pattern-matchin.  in the example given, `primary2` would match
/// with `primary` if it is checked before `primary2`:
///
///  	switch Color.primary2 {
///  	case .primary: // Will match ✅
///  	case .primary2: // Will not match ❌
///  	}
///
/// And without `isPrefixMatchingEnabled`:
///
/// 	Color.isPrefixMatchingEnabled = false
/// 	switch Color.primary2 {
///  	case .primary: // Will not match ❌
///  	case .primary2: // Will match ✅
///  	}
///
/// - SeeAlso: `~=` method in this file
public struct Color: Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
	/// A type that represents a `Color` name
	public typealias StringLiteralType = String

	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `primary.lvl1` can be matched with `primary`
	public static var isPrefixMatchingEnabled: Bool = true

	/// This type is used internally to manage transformations if applied to current `Color` before fetching `UIColor`
	let resolver: Resolver

	/// Name of the `Color`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Color`, hence no specific `name` is available
	public var name: String? {
		switch resolver {
		case .name(let name): return name
		default: return nil
		}
	}

	/// Initiates a `Color` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Colors
	///
	/// - Parameter name: Name of the color.
	public init(_ name: String) { resolver = .name(name) }

	/// Ease of use on defining `Color` variables
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }

	/// Describes specification of `UIColor` that will be *fetched*/*generated*
	///
	///  - Note: If description contains `{...}` it means this `Color` contains transformations
	///
	///  Samples:
	///
	/// 	Color("primary")
	/// 	// description: `primary`
	/// 	Color.blending(.primary, 0.30, .secondary)
	/// 	// description: `{primary*0.30+secondary*0.70}`
	/// 	Color.primary.blend(with: .black)
	/// 	// description: `{primary*0.50+(UIExtendedGrayColorSpace 0 1)*0.50}`
	/// 	Color.opacity(0.9, of: .primary)
	/// 	// description: `{primary(0.90)}`
	/// 	Color.primary.transform { $0 }
	/// 	// description: `{primary->t}`
	/// 	Color("primary", bundle: .main)
	/// 	// description: `{primary(bundle:com.farzadshbfn.styled)}`
	public var description: String { resolver.description }

	/// Enables the pattern-matcher (i.e switch-statement) to patch `primary.lvl1` with `primary` if `primary.lvl1` is not available
	/// in the switch-statement
	/// - Parameter pattern: `Color` to match as prefix of the current value
	/// - Parameter value: `Color` given to find the best match for
	@inlinable public static func ~=(pattern: Color, value: Color) -> Bool {
		if isPrefixMatchingEnabled {
			guard let valueName = value.name, let patternName = pattern.name else { return false }
			return valueName.hasPrefix(patternName)
		}
		return value == pattern
	}
}

extension Lazy where Item == Color {

	/// Will directly propagate given `UIColor` when needed
	init(_ uiColor: UIColor) {
		itemHashValue = uiColor.hashValueCombined(with: "UIColor")
		itemDescription = "(\(uiColor))"
		item = { _ in uiColor }
	}
}

extension Color: Item {

	typealias Scheme = ColorScheme

	typealias Result = UIColor

	/// This type is used to support transformations on `Color` like `.blend`
	typealias Lazy = Styled.Lazy<Color>

	/// Internal type to manage Lazy or direct fetching of `UIColor`
	enum Resolver: Hashable, CustomStringConvertible {
		case name(String)
		case lazy (Lazy)

		/// Contains description of current `Resolver` state.
		///
		/// - Note: `Lazy` is surrounded by `{...}`
		var description: String {
			switch self {
			case .name(let name): return name
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}

	/// This method is used internally to manage transformations (if any) and provide `UIColor`
	/// - Parameter scheme:A `ColorScheme` to fetch `UIColor` from
	func resolve(from scheme: ColorScheme) -> UIColor? {
		switch resolver {
		case .name: return scheme.color(for: self)
		case .lazy(let lazy): return lazy .item(scheme)
		}
	}

	/// Enables `Color` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
}

/// Hiding `Color` information on reflection
extension Color: CustomReflectable {
	public var customMirror: Mirror { .init(self, children: []) }
}

extension Color {

	/// Blends `self`  to the other `Lazy` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `Lazy`
	/// - Returns: `from * perc + to * (1 - perc)`
	func blend(_ perc: Double, _ to: Lazy) -> Color {
		let fromDesc = "\(self)*\(String(format: "%.2f", perc))"
		let toDesc = "\(to)*\(String(format: "%.2f", 1 - perc))"
		return .init(lazy: .init(name: "\(fromDesc)+\(toDesc)") { scheme in
			guard let fromUIColor = self.resolve(from: scheme) else { return to.item(scheme) }
			guard let toUIColor = to.item(scheme) else { return fromUIColor }
			return fromUIColor.blend(CGFloat(perc), with: toUIColor)
		})
	}

	/// Blends `self` to the other `Color` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `Color`
	/// - Returns: `from * perc + to * (1 - perc)`
	public func blend(_ perc: Double = 0.5, with to: Color) -> Color { blend(perc, .init(to)) }

	/// Blends `self` to the other `UIColor` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `UIColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public func blend(_ perc: Double = 0.5, with to: UIColor) -> Color { blend(perc, .init(to)) }

	/// Blends two `Color`s together with the amount given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter from: `Color` to pour from
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `Color`
	/// - Returns: `from * perc + to * (1 - perc)`
	public static func blending(_ from: Color, _ perc: Double = 0.5, with to: Color) -> Color { from.blend(perc, with: to) }

	/// Blends a `Color` and `UIColor` together with the amount given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter from: `Color` to pour from
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `UIColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public static func blending(_ from: Color, _ perc: Double = 0.5, with to: UIColor) -> Color { from.blend(perc, with: to) }

	/// Set's `opacity` level
	/// - Parameter perc: will be clamped to `[`**0.0**, **1.0**`]`
	/// - Returns: new instance of `self` with given `opacity`
	public func opacity(_ perc: Double) -> Color {
		return .init(lazy: .init(name: "\(self)(\(String(format: "%.2f", perc)))") { scheme in
			self.resolve(from: scheme)?.withAlphaComponent(CGFloat(perc))
		})
	}

	/// Set's `opacity` level of the given `color`
	/// - Parameter perc: will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter color: `Color`
	/// - Returns: new instance of `color` with given `opacity`
	public static func opacity(_ perc: Double, of color: Color) -> Color { color.opacity(perc) }
}

// MARK: - ColorScheme
/// Use this protocol to provide `UIColor` for `Styled`
///
/// Sample:
///
/// 	struct DarkColorScheme: ColorScheme {
/// 	    func color(for color: Color) -> UIColor? {
/// 	        switch color {
/// 	        case .primary: // return primary color
/// 	        case .secondary: // return secondary color
/// 	        default: fatalError("Forgot to support \(color)")
/// 	        }
/// 	    }
/// 	}
public protocol ColorScheme {

	/// `StyleDescriptor` will use this method to fetch `UIColor`
	///
	/// - Important: **Do not** call this method directly. use `UIColor.styled(_:)` instead.
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `color`
	/// - Note: Returning `nil` translates to **not supported** by this scheme. Returning `nil` will not guarantee that the associated object
	/// will receive `nil` as `UIColor`
	/// - Note: It's guaranteed all `Color`s sent to this message, will contain field `name`
	///
	/// Sample for `DarkColorScheme`:
	///
	/// 	struct DarkColorScheme: ColorScheme {
	/// 	    func color(for color: Color) -> UIColor? {
	/// 	        switch color {
	/// 	        case .primary1: // return primary level1 color
	/// 	        case .primary2: // return primary level2 color
	/// 	        default: fatalError("Forgot to support \(color)")
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter color: `Color` type to fetch `UIColor` from current scheme
	func color(for color: Color) -> UIColor?
}

extension Color {

	/// Will fetch `Color`s from Assets Catalog
	///
	/// - Note: if `Color.isPrefixMatchingEnabled` is `true`, in case of failure at loading `a.b.c.d`
	/// will look for `a.b.c` and if `a.b.c` is failed to be loaded, will look for `a.b` and so on.
	/// Will return `nil` if nothing were found.
	///
	/// - SeeAlso: NoScheme
	/// - SeeAlso: Color(_:bundle:)
	@available(iOS 11, *)
	public struct DefaultScheme: ColorScheme {

		public init() {}

		public func color(for color: Color) -> UIColor? { .named(color.name!, in: nil) }
	}

	/// Will return `nil` for all `Color`s
	///
	/// - Important: It's recommended to use `NoScheme` when using `.init(_:bundle:)` version of `Color`
	public struct NoScheme: ColorScheme {

		public init() {}

		public func color(for color: Color) -> UIColor? { nil }
	}

	/// Fetches `UIColor` from ColorAsset defined in given `Bundle`
	///
	/// - Note: `Color`s initialized with this initializer, will not be sent **directly** to `ColorScheme`. In `ColorScheme`
	/// read `name` variable to determine what to do.
	///
	/// - Parameter name: Name of the color to look-up in Assets Catalog
	/// - Parameter bundle: `Bundle` to look into it's Assets
	/// - SeeAlso: `XcodeAssetsColorScheme`
	@available(iOS 11, *)
	public init(_ name: String, bundle: Bundle) {
		resolver = .lazy(.init(name: "\(name)(bundle:\(bundle.bundleIdentifier ?? ""))") {
			$0.color(for: .init(name)) ?? UIColor.named(name, in: bundle)
		})
	}
}

// MARK: UIColor+Extensions
extension UIColor {

	/// Will fetch `UIColor` defined in given `ColorScheme`
	/// - Parameter color: `Color`
	/// - Parameter scheme: `ColorScheme` to search for color. (default: `Config.colorScheme`)
	open class func styled(_ color: Color, from scheme: ColorScheme = Config.colorScheme) -> UIColor? {
		color.resolve(from: scheme)
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

		return UIColor(red: col1.r * perc + col2.r * percComp,
		               green: col1.g * perc + col2.g * percComp,
		               blue: col1.b * perc + col2.b * percComp,
		               alpha: col1.a * perc + col2.a * percComp)
	}

	/// Will look in the Assets catalog in given `Bundle` for the given color
	///
	/// - Note: if `Color.isPrefixMatchingEnabled` is `true` will try all possbile variations
	///
	/// - Parameter colorName: `String` name of the `Color` (mostly it's description"
	/// - Parameter bundle: `Bundle` to look into it's Assets Catalog
	@available(iOS 11, *)
	fileprivate class func named(_ colorName: String, in bundle: Bundle?) -> UIColor? {
		guard Color.isPrefixMatchingEnabled else {
			return UIColor(named: colorName, in: bundle, compatibleWith: nil)
		}
		var name = colorName
		while name != "" {
			if let color = UIColor(named: name, in: bundle, compatibleWith: nil) { return color }
			name = name.split(separator: ".").dropLast().joined(separator: ".")
		}
		return nil
	}
}
