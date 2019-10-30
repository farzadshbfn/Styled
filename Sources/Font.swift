//
//  Font.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/20/19.
//

import Foundation
import class UIKit.UIFont

/// Used to escape fix namespace conflicts
public typealias StyledFont = Font
/// Used to escape fix namespace conflicts
public typealias StyledFontScheme = FontScheme

// MARK:- Font
/// Used to fetch font on runtime based on current `FontScheme`
///
/// Sample usage:
///
///  	extension Font {
///  		static let title    = Self(.headline, weight: .bold)
///  		static let subtitle = Self(.subheadline, weight: .light)
///  		static let body     = Self(.body)
///  	}
///
///  	label.styled.font = .title
///  	label.styled.font = .init(.body, weight: .ultraLight)
///
public struct Font: Hashable, CustomStringConvertible {
	
	/// Mirroring `UIFont.TextStyle` for compatibility
	public typealias TextStyle = UIFont.TextStyle
	
	/// Mirroring `UIFont.Weight` for compatibility
	public typealias Weight = UIFont.Weight
	
	/// This type is used internally to manage transformations if applied to current `Font` before fetching `UIFont`
	let resolver: Resolver
	
	/// Initiates a `Font` with specifications given to be fetched later
	///
	/// - Parameter size: `Font.Size` instance to specify size of the Font
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(size: Size, weight: Weight = .regular) {
		resolver = .font(size: size, weight: weight)
	}
	
	/// Initiates a `Font` with specifications given to be fetched later
	///
	/// - Parameter textStyle: `UIFont.TextStyle` instance
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(_ textStyle: TextStyle, weight: Weight = .regular) {
		resolver = .font(size: .dynamic(textStyle), weight: weight)
	}
	
	/// Initiates a `Font` with specifications given to be fetched later
	///
	/// - Parameter size: Font's `pointSize`
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(_ size: CGFloat, weight: Weight = .regular) {
		resolver = .font(size: .static(size), weight: weight)
	}
	
	/// Size of the `Font`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Font`, hence no specific `size` is available
	///
	public var size: Size? {
		switch resolver {
		case .font(let size, _): return size
		default: return nil
		}
	}
	
	/// Weight of the `Font`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Font`, hence no specific `weight` is available
	///
	public var weight: Weight? {
		switch resolver {
		case .font(_, let weight): return weight
		default: return nil
		}
	}
	
	/// size and weight of the `Font`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Font`, hence no specific `size` and `weight` are available
	///
	public var sizeAndWeight: (size: Size, weight: Weight)? {
		switch resolver {
		case .font(let size, let weight): return (size, weight)
		default: return nil
		}
	}
	
	/// Describes specification of `UIFont` that will be *fetched*/*generated*
	///
	///  - Note: `Font`s with transformations will not be sent to `FontScheme`s directly
	///
	///  Samples:
	///
	/// 	Font(42)
	/// 	// description: "42(0.0)"
	/// 	Font(.body, weight: .bold)
	/// 	// description: "UICTFontTextStyleBody(0.4000000059604645)"
	/// 	Font(.title1).transform { $0 }
	/// 	// description:  "{UICTFontTextStyleTitle1(0.0)->t}"
	///
	public var description: String { resolver.description }
}


extension Font {
	
	/// Identifies wether the font needs to be static or dynamically managed by fontSizeCategory of system
	public enum Size: Hashable, CustomStringConvertible {
		/// Explicit size
		case `static`(CGFloat)
		/// Dynamic size based on device (or managed in application) sizes
		case dynamic(TextStyle)
		
		/// Describes given value
		///
		/// 	Size.static(42)
		/// 	// description: "42"
		/// 	Size.dynamic(.title1)
		/// 	// description: "UICTFontTextStyleTitle1"
		///
		public var description: String {
			switch self {
			case .static(let size): return "\(size)"
			case .dynamic(let style): return "\(style.rawValue)"
			}
		}
		
		/// This method is used internally to manage transformations (if any) and provide `CGFloat` as size of `UIFont`
		/// - Parameter scheme:A `FontScheme` to fetch `CGFloat` from
		func resolve(from scheme: FontScheme) -> CGFloat {
			scheme.size(for: self)
		}
	}
	
	/// Internal type to manage Lazy or direct fetching of `UIFont`
	enum Resolver: Hashable, CustomStringConvertible {
		case font(size: Size, weight: Weight)
		case lazy(Lazy)
		
		/// Contains description of current `Resolver` state.
		///
		/// - Note: `Lazy` is surrounded by `{...}`
		///
		var description: String {
			switch self {
			case .font(let size, let weight): return "\(size.description)(\(weight.rawValue))"
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}
	
	struct Lazy: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `Font` in order to let `Font` hold `Lazy` in its definition
		let fontHashValue: Int
		
		/// Describes current font that will be returned
		let fontDescription: String
		
		/// Describes current font that will be returned
		var description: String { fontDescription }
		
		/// Provides `UIFont` which can be backed by `Font`
		let font: (_ scheme: FontScheme) -> UIFont?
		
		/// Used internally to pre-calculate hashValue of Internal `font`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIFont` from `Font` when needed
		init(_ font: Font) {
			fontHashValue = Self.hashed("Font", font)
			fontDescription = font.description
			self.font = font.resolve
		}
		
		/// Will use custom Provider to provide `UIFont` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ fontProvider: @escaping (_ scheme: FontScheme) -> UIFont?) {
			fontHashValue = Self.hashed("FontProvider", name)
			fontDescription = name
			font = fontProvider
		}
		
		/// - Returns: `hashValue` of given parameters when initializing `Lazy`
		func hash(into hasher: inout Hasher) { hasher.combine(fontHashValue) }
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: Lazy, rhs: Lazy) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// This method is used internally to manage transformations (if any) and provide `UIFont`
	/// - Parameter scheme:A `FontScheme` to fetch `UIFont` from
	func resolve(from scheme: FontScheme) -> UIFont? {
		switch resolver {
		case .font: return scheme.font(for: self)
		case .lazy(let lazy): return lazy.font(scheme)
		}
	}
	
	/// Enables `Font` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
	
	/// Applies custom transformations on the `UIFont`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIFont`
	public func transform(named name: String = "t", _ transform: @escaping (UIFont) -> UIFont) -> Font {
		return .init(lazy: .init(name: "\(name)->\(self)", { scheme in
			guard let font = self.resolve(from: scheme) else { return nil }
			return transform(font)
		}))
	}
	
	/// Applies custom transformations on the `UIFont` fetched from `Font`
	/// - Parameter font: `Font` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIFont`
	public static func transforming(_ font: Font,
									named name: String = "t",
									_ transform: @escaping (UIFont) -> UIFont) -> Font {
		font.transform(named: name, transform)
	}
}

// MARK:- FontScheme
/// Use this protocol to provide `UIFont` for `Styled`
///
/// Sample:
///
/// 	struct LatinoFontScheme: FontScheme {
/// 	    func font(for font: Font) -> UIFont? {
/// 	        switch font {
/// 	        case .title: // return UIFont for all titles in latino localization
/// 	        case .subtitle: // return UIFont for all subtitles in latino localization
/// 	        default: // return Customized latino font with given font.size! and font.weight!
/// 	        }
/// 	    }
///
/// 	    func size(for size: Font.Font.Size) -> CGFloat {
/// 	    	switch size {
/// 	    	case .static(let size): return size
/// 	    	// In dynamic case we need to adjust system font for latino fonts
/// 	    	case .dynamic(let textStyle): return UIFont.preferredFont(forTextStyle: textStyle).pointSize - 3
/// 	    	}
/// 	    }
/// 	}
///
public protocol FontScheme {
	
	/// `Styled` will use this method to fetch `UIFont`
	///
	/// - Important: **Do not** call this method directly. use `UIFont.styled(_:)` instead.
	///
	/// - Note: Unlike `ColorScheme` & `FontScheme` its good to return a `UIFont` with given `size` and `weight`
	///
	/// - Note: It's guaranteed all `Font`s sent to this message, will contain field `font`
	///
	/// Sample for `LatinoFontScheme`:
	///
	/// 	struct LatinoFontScheme: FontScheme {
	/// 	    func font(for font: Font) -> UIFont? {
	/// 	        switch font {
	/// 	        case .title: // return UIFont for all titles in latino localization
	/// 	        case .subtitle: // return UIFont for all subtitles in latino localization
	/// 	        default: // return Customized latino font with given font.size! and font.weight!
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter font: `Font` type to fetch `UIFont` from current scheme
	func font(for font: Font) -> UIFont?
	
	/// `Styled` will use this method to fetch suitable `pointSize` for `UIFont`
	///
	/// - Important: **Do not** call this method directly. use `UIFont.preferredFontSize(_:)` instead
	///
	/// Sample for `LatinoFontScheme`:
	///
	/// 	struct LatinoFontScheme: FontScheme {
	/// 	    func size(for size: Font.Font.Size) -> CGFloat {
	/// 	    	switch size {
	/// 	    	case .static(let size): return size
	/// 	    	// In dynamic case we need to adjust system font for latino fonts
	/// 	    	case .dynamic(let textStyle): return UIFont.preferredFont(forTextStyle: textStyle).pointSize - 3
	/// 	    	}
	/// 	    }
	/// 	}
	///
	/// - Parameter size: `Font.Font.Size`
	func size(for size: Font.Size) -> CGFloat
}

/// Will fetch `Font`s from system font size category
public struct DefaultFontScheme: FontScheme {
	
	public init() { }
	
	public func font(for font: Font) -> UIFont? {
		.systemFont(ofSize: size(for: font.size!), weight: font.weight!)
	}

	public func size(for size: Font.Size) -> CGFloat {
		switch size {
		case .static(let size): return size
		case .dynamic(let textStyle): return UIFont.preferredFont(forTextStyle: textStyle).pointSize
		}
	}
}

// MARK:- UIFont+Extensions
extension UIFont {
	
	/// Will fetch `UIFont` defined in given `FontScheme`
	///
	/// - Parameter font: `Font`
	/// - Parameter scheme: `FontScheme` to search for font. (default: `Config.fontScheme`)
	open class func styled(_ font: Font, from scheme: FontScheme = Config.fontScheme) -> UIFont? {
		font.resolve(from: scheme)
	}
	
	/// Will fetch suitable `pointSize` for given `Font.Font.Size` defined in given `FontScheme`
	///
	/// - Parameter size: `Font.Font.Size`
	/// - Parameter scheme: `FontScheme` to search for suitable pointSize. (default: `Config.fontScheme`)
	open class func preferedFontSize(for size: Font.Size, from scheme: FontScheme = Config.fontScheme) -> CGFloat {
		size.resolve(from: scheme)
	}
	
	/// Will return the font with `Size` given
	/// - Parameter size: `Font.Size` which determiens font is dynamic or static
	/// - Parameter scheme: `Scheme` to resolve size of Font from. (default: `Config.fontScheme`)
	open func withSize(_ size: Font.Size, from scheme: FontScheme = Config.fontScheme) -> UIFont {
		self.withSize(size.resolve(from: scheme))
	}
}

// MARK:- StyledWrapper
extension StyledWrapper {
	
	/// Will get called when  `Config.fontSchemeDidChange` is raised or `applyFonts()` is called or `currentFontScheme` changes
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onFontSchemeChange(withId id: ClosureIdentifier = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return styled.colorUpdates[id] = nil }
		styled.colorUpdates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}
	
	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ font: Font?, _ apply: @escaping (Base, UIFont?) -> Void) -> Styled.Update<Font>? {
		guard let font = font else { return nil }
		let styledUpdate = Styled.Update(item: font) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, font.resolve(from: scheme))
		}
		styledUpdate.refresh(styled.fontScheme)
		return styledUpdate
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with font defined in `fontScheme` for given `Font`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `fontScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIFont>) -> Font? {
		get { styled.fontUpdates[keyPath]?.item }
		set { styled.fontUpdates[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1! : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with font defined in `fontScheme` for given `Font`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `fontScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIFont?>) -> Font? {
		get { styled.fontUpdates[keyPath]?.item }
		set { styled.fontUpdates.keyPaths[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}
}
