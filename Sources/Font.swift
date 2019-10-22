//
//  Font.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/20/19.
//

import Foundation
import class UIKit.UIFont

// MARK:- StyledFont
/// Used to fetch font on runtime based on current `StyledFontScheme`
///
/// Sample usage:
///
///  	extension StyledFont {
///  		static let title    = Self(.headline, weight: .bold)
///  		static let subtitle = Self(.subheadline, weight: .light)
///  		static let body     = Self(.body)
///  	}
///
///  	label.styled.font = .title
///  	label.styled.font = .init(.body, weight: .ultraLight)
///
public struct StyledFont: Hashable, CustomStringConvertible {
	
	/// This type is used internally to manage transformations if applied to current `StyledFont` before fetching `UIFont`
	let resolver: Resolver
	
	/// Initiates a `StyledFont` with specifications given to be fetched later
	///
	/// - Parameter size: `Font.Size` instance to specify size of the Font
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(size: Font.Size, weight: Font.Weight = .regular) {
		resolver = .font(.init(size: size, weight: weight))
	}
	
	/// Initiates a `StyledFont` with specifications given to be fetched later
	///
	/// - Parameter textStyle: `UIFont.TextStyle` instance
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(_ textStyle: UIFont.TextStyle, weight: Font.Weight = .regular) {
		resolver = .font(.init(textStyle, weight: weight))
	}
	
	/// Initiates a `StyledFont` with specifications given to be fetched later
	///
	/// - Parameter size: Font's `pointSize`
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(_ size: CGFloat, weight: Font.Weight = .regular) {
		resolver = .font(.init(size, weight: weight))
	}
	
	/// Font of the `StyledFont`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `StyledFont`, hence no specific `font` is available
	///
	public var font: Font? {
		switch resolver {
		case .font(let font): return font
		default: return nil
		}
	}
	
	/// Describes specification of `UIFont` that will be *fetched*/*generated*
	///
	///  - Note: `StyledFont`s with transformations will not be sent to `StyledFontScheme`s directly
	///
	///  Samples:
	///
	/// 	StyledFont(42)
	/// 	// description: "regular-42"
	/// 	StyledFont(.body, weight: .bold)
	/// 	// description: "bold-title1"
	/// 	StyledFont(.title1).transform { $0 }
	/// 	// description:  "{regular-title1->t}"
	///
	public var description: String { resolver.description }
}


extension StyledFont {
	
	/// Specification of the `UIFont` that needs to be fetched by `TextStyle` and `Weight` parameters
	public struct Font: Hashable, CustomStringConvertible {
		
		/// Mirroring `UIFont.TextStyle` for compatibility
		public typealias TextStyle = UIFont.TextStyle
		
		/// Mirroring `UIFont.Weight` for compatibility
		public typealias Weight = UIFont.Weight
		
		/// Holds `Size` information for the font to be fetched
		public let size: Size
		
		/// Holds `Weight` information for the font to be fetched
		public let weight: Weight
		
		/// - Parameter size: `Size` instance to specify size of the Font
		/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
		public init(size: Size, weight: Weight = .regular) {
			self.size = size
			self.weight = weight
		}
		
		/// - Parameter textStyle: `UIFont.TextStyle` instance
		/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
		public init(_ textStyle: TextStyle, weight: Weight = .regular) {
			self.size = .dynamic(textStyle)
			self.weight = weight
		}
		
		/// - Parameter size: Font's `pointSize`
		/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
		public init(_ size: CGFloat, weight: Weight = .regular) {
			self.size = .static(size)
			self.weight = weight
		}
		
		/// Describes weight and size of the given Font
		///
		/// 	Font(42)
		/// 	// description: regular-42
		/// 	Font(42, weight: .bold)
		/// 	// description: bold-42
		/// 	Font(.title1, weight: .init(rawValue: 0.17)
		/// 	// description: (0.17)-title1
		///
		public var description: String { "\(weight.styledDescription)-\(size.description)" }
		
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
			/// 	// description: "title1"
			///
			public var description: String {
				switch self {
				case .static(let size): return "\(size)"
				case .dynamic(let style): return "\(style)"
				}
			}
			
			/// This method is used internally to manage transformations (if any) and provide `CGFloat` as size of `UIFont`
			/// - Parameter scheme:A `StyledFontScheme` to fetch `CGFloat` from
			func resolve(from scheme: StyledFontScheme) -> CGFloat {
				scheme.size(for: self)
			}
		}
	}
	
	/// Internal type to manage Lazy or direct fetching of `UIFont`
	enum Resolver: Hashable, CustomStringConvertible {
		case font(Font)
		case lazy(LazyFont)
		
		/// Contains description of current `Resolver` state.
		///
		/// - Note: `LazyFont` is surrounded by `{...}`
		///
		var description: String {
			switch self {
			case .font(let font): return font.description
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}
	
	struct LazyFont: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `StyledFont` in order to let `StyledFont` hold `LazyFont` in its definition
		let fontHashValue: Int
		
		/// Describes current font that will be returned
		let fontDescription: String
		
		/// Describes current font that will be returned
		var description: String { fontDescription }
		
		/// Provides `UIFont` which can be backed by `StyledFont`
		let font: (_ scheme: StyledFontScheme) -> UIFont?
		
		/// Used internally to pre-calculate hashValue of Internal `font`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIFont` from `StyledFont` when needed
		init(_ styledFont: StyledFont) {
			fontHashValue = Self.hashed("StyledFont", styledFont)
			fontDescription = styledFont.description
			font = { styledFont.resolve(from: $0) }
		}
		
		/// Will use custom Provider to provide `UIFont` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ fontProvider: @escaping (_ scheme: StyledFontScheme) -> UIFont?) {
			fontHashValue = Self.hashed("FontProvider", name)
			fontDescription = name
			font = fontProvider
		}
		
		/// - Returns: `hashValue` of given parameters when initializing `LazyFont`
		func hash(into hasher: inout Hasher) { hasher.combine(fontHashValue) }
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: LazyFont, rhs: LazyFont) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// This method is used internally to manage transformations (if any) and provide `UIFont`
	/// - Parameter scheme:A `StyledFontScheme` to fetch `UIFont` from
	func resolve(from scheme: StyledFontScheme) -> UIFont? {
		switch resolver {
		case .font: return scheme.font(for: self)
		case .lazy(let lazy): return lazy.font(scheme)
		}
	}
	
	/// Enables `StyledFont` to accept transformations
	/// - Parameter lazyFont: `LazyFont` instance
	init(lazyFont: LazyFont) { resolver = .lazy(lazyFont) }
	
	/// Applies custom transformations on the `UIFont`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIFont`
	public func transform(named name: String = "t", _ transform: @escaping (UIFont) -> UIFont) -> StyledFont {
		return .init(lazyFont: .init(name: "\(name)->\(self)", { scheme in
			guard let font = self.resolve(from: scheme) else { return nil }
			return transform(font)
		}))
	}
	
	/// Applies custom transformations on the `UIFont` fetched from `StyledFont`
	/// - Parameter styledFont: `StyledFont` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIFont`
	public static func transforming(_ styledFont: StyledFont,
									named name: String = "t",
									_ transform: @escaping (UIFont) -> UIFont) -> StyledFont {
		styledFont.transform(named: name, transform)
	}
}

// MARK:- StyledFontScheme
/// Use this protocol to provide `UIFont` for `Styled`
///
/// Sample:
///
/// 	struct LatinoFontScheme: StyledFontScheme {
/// 	    func font(for styledFont: StyledFont) -> UIFont? {
/// 	        switch styledFont {
/// 	        case .title: // return UIFont for all titles in latino localization
/// 	        case .subtitle: // return UIFont for all subtitles in latino localization
/// 	        default: latinoFont(weight: styledFont.font!.weight).withSize(size(for: styledFont.font!.size))
/// 	        }
/// 	    }
///
/// 	    func size(for size: StyledFont.Font.Size) -> CGFloat {
/// 	    	switch size {
/// 	    	case .static(let size): return size
/// 	    	// In dynamic case we need to adjust system font for latino fonts
/// 	    	case .dynamic(let textStyle): return UIFont.preferredFont(forTextStyle: textStyle).pointSize - 3
/// 	    	}
/// 	    }
///
/// 	    func latinoFont(_ weight: UIFont.Weight) -> UIFont {
/// 	    	// loades suitable font from Bundle for given weight
/// 	    }
/// 	}
///
public protocol StyledFontScheme {
	
	/// `Styled` will use this method to fetch `UIFont`
	///
	/// - Important: **Do not** call this method directly. use `UIFont.styled(_:)` instead.
	///
	/// - Note: Unline `StyledColorScheme` & `StyledFontScheme` its good to return a `UIFont` with given `size` and `weight`
	///
	/// - Note: It's guaranteed all `StyledFont`s sent to this message, will contain field `font`
	///
	/// Sample for `LatinoFontScheme`:
	///
	/// 	struct LatinoFontScheme: StyledFontScheme {
	/// 	    func font(for styledFont: StyledFont) -> UIFont? {
	/// 	        switch styledFont {
	/// 	        case .title: // return UIFont for all titles in latino localization
	/// 	        case .subtitle: // return UIFont for all subtitles in latino localization
	/// 	        default: latinoFont(weight: styledFont.font!.weight).withSize(size(for: styledFont.font!.size))
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter styledFont: `StyledFont` type to fetch `UIFont` from current scheme
	func font(for styledFont: StyledFont) -> UIFont?
	
	/// `Styled` will use this method to fetch suitable `pointSize` for `UIFont`
	///
	/// - Important: **Do not** call this method directly. use `UIFont.preferredFontSize(_:)` instead
	///
	/// Sample for `LatinoFontScheme`:
	///
	/// 	struct LatinoFontScheme: StyledFontScheme {
	/// 	    func size(for size: StyledFont.Font.Size) -> CGFloat {
	/// 	    	switch size {
	/// 	    	case .static(let size): return size
	/// 	    	// In dynamic case we need to adjust system font for latino fonts
	/// 	    	case .dynamic(let textStyle): return UIFont.preferredFont(forTextStyle: textStyle).pointSize - 3
	/// 	    	}
	/// 	    }
	/// 	}
	///
	/// - Parameter size: `StyledFont.Font.Size`
	func size(for size: StyledFont.Font.Size) -> CGFloat
}

// MARK:- SystemFontCategory
extension UIFont {
	
	/// Will fetch `StyledFont`s from system font size category
	public struct StyledSystemFontCategory: StyledFontScheme {
		
		public func font(for styledFont: StyledFont) -> UIFont? {
			.systemFont(ofSize: size(for: styledFont.font!.size), weight: styledFont.font!.weight)
		}

		public func size(for size: StyledFont.Font.Size) -> CGFloat {
			switch size {
			case .static(let size): return size
			case .dynamic(let textStyle): return UIFont.preferredFont(forTextStyle: textStyle).pointSize
			}
		}
	}
}

// MARK:- UIFont+Extensions
extension UIFont {
	
	/// Will fetch `UIFont` defined in given `StyledFontScheme`
	///
	/// - Parameter styledFont: `StyledFont`
	/// - Parameter scheme: `StyledFontScheme` to search for font. (default: `Styled.defaultFontScheme`)
	open class func styled(_ styledFont: StyledFont, from scheme: StyledFontScheme = Styled.defaultFontScheme) -> UIFont? {
		styledFont.resolve(from: scheme)
	}
	
	/// Will fetch suitable `pointSize` for given `StyledFont.Font.Size` defined in given `StyledFontScheme`
	///
	/// - Parameter size: `StyledFont.Font.Size`
	/// - Parameter scheme: `StyledFontScheme` to search for suitable pointSize. (default: `Styled.defaultFontScheme`
	open class func preferedFontSize(for size: StyledFont.Font.Size, from scheme: StyledFontScheme = Styled.defaultFontScheme) -> CGFloat {
		size.resolve(from: scheme)
	}
}

extension UIFont.Weight {
	
	/// Returns description of current weight if it is known
	fileprivate var styledDescription: String {
		switch self {
		case .ultraLight: return "ultraLight"
		case .thin: return "thin"
		case .light: return "light"
		case .regular: return "regular"
		case .medium: return "medium"
		case .semibold: return "semibold"
		case .bold: return "bold"
		case .heavy: return "heavy"
		case .black: return "black"
		default: return "(\(self))"
		}
	}
}

extension UIFont.TextStyle {
	
	/// Returns description of current weight if it is known
	fileprivate var styledDescription: String {
		switch self {
			case .title1: return "title1"
			case .title2: return "title2"
			case .title3: return "title3"
			case .headline: return "headline"
			case .subheadline: return "subheadline"
			case .body: return "body"
			case .callout: return "callout"
			case .footnote: return "footnote"
			case .caption1: return "caption1"
			case .caption2: return "caption2"
		default:
			if #available(iOS 11, *), self == .largeTitle {
				return "largeTitle"
			}
			return "(\(self))"
		}
	}
}

// MARK:- StyledWrapper
extension StyledWrapper {
	
	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ styledFont: StyledFont?, _ apply: @escaping (Base, UIFont?) -> Void) -> Styled.Update<StyledFont>? {
		guard let styledFont = styledFont else { return nil }
		let styledUpdate = Styled.Update(item: styledFont) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, styledFont.resolve(from: scheme))
		}
		styledUpdate.update(styled.fontScheme)
		return styledUpdate
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with font defined in `fontScheme` for given `StyledFont`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `fontScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIFont>) -> StyledFont? {
		get { styled.fonts[keyPath]?.item }
		set { styled.fonts[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1! : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with font defined in `fontScheme` for given `StyledFont`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `fontScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIFont?>) -> StyledFont? {
		get { styled.fonts[keyPath]?.item }
		set { styled.fonts[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}
}
