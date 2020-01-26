//
//  Font.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/20/19.
//

import Foundation
import class UIKit.UIFont

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
///  	label.sd.font = .title
///  	label.sd.font = .init(.body, weight: .ultraLight)
public struct Font: Hashable, CustomStringConvertible {
	
	/// Mirroring `UIFont.TextStyle` for compatibility
	public typealias TextStyle = UIFont.TextStyle
	
	/// Mirroring `UIFont.Weight` for compatibility
	public typealias Weight = UIFont.Weight
	
	/// This type is used internally to manage transformations if applied to current `Font` before fetching `UIFont`
	let resolver: Resolver
	
	/// Size of the `Font`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Font`, hence no specific `size` is available
	public var size: Size? {
		switch resolver {
		case .font(let size, _): return size
		default: return nil
		}
	}
	
	/// Weight of the `Font`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Font`, hence no specific `weight` is available
	public var weight: Weight? {
		switch resolver {
		case .font(_, let weight): return weight
		default: return nil
		}
	}
	
	/// Initiates a `Font` with specifications given to be fetched later
	/// - Parameter size: `Font.Size` instance to specify size of the Font
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(size: Size, weight: Weight = .regular) {
		resolver = .font(size: size, weight: weight)
	}
	
	/// Initiates a `Font` with specifications given to be fetched later
	/// - Parameter textStyle: `UIFont.TextStyle` instance
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(_ textStyle: TextStyle, weight: Weight = .regular) {
		resolver = .font(size: .dynamic(textStyle), weight: weight)
	}
	
	/// Initiates a `Font` with specifications given to be fetched later
	/// - Parameter size: Font's `pointSize`
	/// - Parameter weight: `UIFont.Weight` instance (default is `.regular`)
	public init(_ size: CGFloat, weight: Weight = .regular) {
		resolver = .font(size: .static(size), weight: weight)
	}
	
	/// Describes specification of `UIFont` that will be *fetched*/*generated*
	///
	///  - Note: `Font`s with transformations will not be sent to `FontScheme`s directly
	///
	///  Samples:
	///
	/// 	Font(42)
	/// 	// description: `42(0.0)`
	/// 	Font(.body, weight: .bold)
	/// 	// description: `UICTFontTextStyleBody(0.4000000059604645)`
	/// 	Font(.title1).transform { $0 }
	/// 	// description: `{UICTFontTextStyleTitle1(0.0)->t}`
	public var description: String { resolver.description }
}


extension Font: Item {
	
	typealias Scheme = FontScheme
	
	typealias Result = UIFont
	
	/// This type is used to support transformations on `Font` like `.transform`
	typealias Lazy = Styled.Lazy<Font>
	
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
	
	/// This method is used internally to manage transformations (if any) and provide `UIFont`
	/// - Parameter scheme:A `FontScheme` to fetch `UIFont` from
	func resolve(from scheme: FontScheme) -> UIFont? {
		switch resolver {
		case .font: return scheme.font(for: self)
		case .lazy(let lazy): return lazy.item(scheme)
		}
	}
	
	/// Enables `Font` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
}

/// Hiding `Font` information on reflection
extension Font: CustomReflectable {
	public var customMirror: Mirror { .init(self, children: []) }
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
/// 	}
public protocol FontScheme {
	
	/// `StyleDescriptor` will use this method to fetch `UIFont`
	///
	/// - Important: **Do not** call this method directly. use `UIFont.styled(_:)` instead.
	///
	/// - Note: You can read `UIApplication.shared.preferredContentSizeCategory` to return fonts with suitable size for accessibility
	/// - Note: Unlike `FontScheme` & `FontScheme` its good to return a `UIFont` with given `size` and `weight`
	/// - Note: Returning `nil` translates to **not supported** by this scheme. Returning `nil` will not guarantee that the associated object
	/// will receive `nil` as `UIFont`
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
}

extension Font {
	
	/// Will fetch `Font`s from system font size category
	public struct DefaultScheme: FontScheme {
		
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
	
	/// Will return `nil` for all `Fonts`s
	public struct NoScheme: FontScheme {
		
		public init() { }
		
		public func font(for font: Font) -> UIFont? { nil }
	}
}

// MARK:- UIFont+Extensions
extension UIFont {
	
	/// Will fetch `UIFont` defined in given `FontScheme`
	/// - Parameter font: `Font`
	/// - Parameter scheme: `FontScheme` to search for font. (default: `Config.fontScheme`)
	open class func styled(_ font: Font, from scheme: FontScheme = Config.fontScheme) -> UIFont? {
		font.resolve(from: scheme)
	}
}
