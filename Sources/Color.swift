//
//  Color.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import class UIKit.UIColor

/// Used to escape fix namespace conflicts
public typealias StyledColor = Color
/// Used to escape fix namespace conflicts
public typealias StyledColorScheme = ColorScheme

// MARK:- Color
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
/// 	    static let primary  = Self("primary")
/// 	    static let primary1 = Self("primary.lvl1")
/// 	    static let primary2 = Self("primary.lvl2")
/// 	}
///
/// 	view.styled.backgroundColor = .primary
/// 	label.styled.textColor = .opacity(0.9, of: .primary)
/// 	layer.styled.backgroundColor = .primary
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
public struct Color: Hashable, CustomStringConvertible ,ExpressibleByStringLiteral {
	/// A type that represents a `Color` name
	public typealias StringLiteralType = String
	
	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `primary.lvl1` can be matched with `primary`
	public static var isPrefixMatchingEnabled: Bool = true
	
	/// Initiates a `Color` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Colors
	///
	/// - Parameter name: Name of the color.
	public init(_ name: String) { resolver = .name(name) }
	
	/// This type is used internally to manage transformations if applied to current `Color` before fetching `UIColor`
	let resolver: Resolver
	
	/// Name of the `Color`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Color`, hence no specific `name` is available
	///
	public var name: String? {
		switch resolver {
		case .name(let name): return name
		default: return nil
		}
	}
	
	/// Describes specification of `UIColor` that will be *fetched*/*generated*
	///
	///  - Note: `Color`s with transformations will not be sent to `ColorScheme`s directly
	///  - Note: If description contains `{...}` it means this `Color` contains transformations
	///
	///  Samples:
	///
	/// 	Color("primary")
	/// 	// description: "primary"
	/// 	Color.blending(.primary, 0.30, .secondary)
	/// 	// description: "{primary*0.30+secondary*0.70}"
	/// 	Color.primary.blend(with: .black)
	/// 	// description: "{primary*0.50+(UIExtendedGrayColorSpace 0 1)*0.50}"
	/// 	Color.opacity(0.9, of: .primary)
	/// 	// description: "{primary(0.90)}"
	/// 	Color.primary.transform { $0 }
	/// 	// description: "{primary->t}"
	/// 	Color("primary", bundle: .main)
	/// 	// description: "{primary(com.farzadshbfn.styled)}"
	///
	public var description: String { resolver.description }
	
	/// Ease of use on defining `Color` variables
	///
	/// 	extension Color {
	/// 	    static let primary:   Self = "primary"
	/// 	    static let secondary: Self = "secondary"
	/// 	}
	///
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }
	
	/// Enables the pattern-matcher (i.e switch-statement) to patch `primary.lvl1` with `primary` if `primary.lvl1` is not available
	/// in the switch-statement
	///
	/// - Parameter pattern: `Color` to match as prefix of the current value
	/// - Parameter value: `Color` given to find the best match for
	@inlinable public static func ~=(pattern: Color, value: Color) -> Bool {
		if isPrefixMatchingEnabled {
			guard let valueName = value.name, let patternName = pattern.name else { return false }
			return valueName.hasPrefix(patternName)
		} else {
			return value == pattern
		}
	}
}

extension Color {
	
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
	
	/// This type is used to support transformations on `Color` like `.blend`
	struct Lazy: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `Color` in order to let `Color` hold `Lazy` in its definition
		let colorHashValue: Int
		
		/// Describes current color that will be returned
		let colorDescription: String
		
		/// Describes current color that will be returned
		var description: String { colorDescription }
		
		/// Provides `UIColor` which can be backed by `Color` or static `UIColor`
		let color: (_ scheme: ColorScheme) -> UIColor?
		
		/// Used internally to pre-calculate hashValue of Internal `color`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIColor` from `Color` when needed
		init(_ color: Color) {
			colorHashValue = Self.hashed("Color", color)
			colorDescription = color.description
			self.color = color.resolve
		}
		
		/// Will directly propagate given `UIColor` when needed
		init(_ uiColor: UIColor) {
			colorHashValue = Self.hashed("UIColor", uiColor)
			colorDescription = "(\(uiColor))"
			color = { _ in uiColor }
		}
		
		/// Will use custom Provider to provide `UIColor` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ colorProvider: @escaping (_ scheme: ColorScheme) -> UIColor?) {
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
	/// - Parameter scheme:A `ColorScheme` to fetch `UIColor` from
	func resolve(from scheme: ColorScheme) -> UIColor? {
		switch resolver {
		case .name: return scheme.color(for: self)
		case .lazy(let lazy): return lazy.color(scheme)
		}
	}
	
	/// Enables `Color` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
	
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
	/// - Parameter to: Targeted `StyeledColor`
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
	public static func blending(_ from: Color, _ perc: Double = 0.5, with to: UIColor) -> Color { from .blend(perc, with: to) }
	
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
	
	/// Applies custom transformations on the `UIColor`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIColor`
	public func transform(named name: String = "t", _ transform: @escaping (UIColor) -> UIColor) -> Color {
		return .init(lazy: .init(name: "\(self)->\(name)", { scheme in
			guard let color = self.resolve(from: scheme) else { return nil }
			return transform(color)
		}))
	}
	
	/// Applies custom transformations on the `UIColor` fetched from `Color`
	/// - Parameter color: `Color` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIColor`
	public static func transforming(_ color: Color,
									named name: String = "t",
									_ transform: @escaping (UIColor) -> UIColor) -> Color {
		color.transform(named: name, transform)
	}
}

// MARK:- ColorScheme
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
///
public protocol ColorScheme {
	
	/// `Styled` will use this method to fetch `UIColor`
	///
	/// - Important: **Do not** call this method directly. use `UIColor.styled(_:)` instead.
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `color`
	///
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

/// Will fetch `Color`s from Assets Catalog
///
/// - Note: if `Color.isPrefixMatchingEnabled` is `true`, in case of failure at loading `a.b.c.d`
/// will look for `a.b.c` and if `a.b.c` is failed to be loaded, will look for `a.b` and so on.
/// Will return `nil` if nothing were found.
///
/// - SeeAlso: `Color(_:,bundle:)`
@available(iOS 11, *)
public struct DefaultColorScheme: ColorScheme {
	
	public init() { }
	
	public func color(for color: Color) -> UIColor? { .named(color.description, in: nil) }
}

extension Color {
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
		resolver = .lazy(.init(name: "\(name)(\(bundle.bundleIdentifier ?? "bundle.not.found"))") {
			$0.color(for: .init(name)) ?? UIColor.named(name, in: bundle)
			})
	}
}

// MARK: UIColor+Extensions
extension UIColor {
	
	/// Will fetch `UIColor` defined in given `ColorScheme`
	///
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
		
		return UIColor(red:   col1.r * perc + col2.r * percComp,
					   green: col1.g * perc + col2.g * percComp,
					   blue:  col1.b * perc + col2.b * percComp,
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

// MARK:- StyledWrapper
extension StyledWrapper {
	
	/// Will get called when  `Config.colorSchemeDidChange` is raised or `applyColors()` is called or `currentColorScheme` changes
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onColorSchemeChange(withId id: ClosureIdentifier = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return styled.colorUpdates[id] = nil }
		styled.colorUpdates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}
	
	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ color: Color?, _ apply: @escaping (Base, UIColor?) -> Void) -> Styled.Update<Color>? {
		guard let color = color else { return nil }
		let styledUpdate = Styled.Update(item: color) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, color.resolve(from: scheme))
		}
		styledUpdate.refresh(styled.colorScheme)
		return styledUpdate
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIColor>) -> Color? {
		get { styled.colorUpdates[keyPath]?.item }
		set { styled.colorUpdates[keyPath] = update(newValue) { $1.write(to: keyPath, on: $0) } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIColor?>) -> Color? {
		get { styled.colorUpdates[keyPath]?.item }
		set { styled.colorUpdates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGColor>) -> Color? {
		get { styled.colorUpdates[keyPath]?.item }
		set { styled.colorUpdates[keyPath] = update(newValue) { ($1?.cgColor).write(to: keyPath, on: $0) } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGColor?>) -> Color? {
		get { styled.colorUpdates[keyPath]?.item }
		set { styled.colorUpdates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.cgColor } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIColor>) -> Color? {
		get { styled.colorUpdates[keyPath]?.item }
		set { styled.colorUpdates[keyPath] = update(newValue) { ($1?.ciColor).write(to: keyPath, on: $0) } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIColor?>) -> Color? {
		get { styled.colorUpdates[keyPath]?.item }
		set { styled.colorUpdates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.ciColor } }
	}
}
