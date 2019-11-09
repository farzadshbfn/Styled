//
//  Image.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import class UIKit.UIImage

// MARK:- Image
/// Used to fetch Image on runtime based on current `ImageScheme`
///
/// - Important: It's important to follow **dot.case** syntax while defining name of Images. e.g `profile`, `profile.fill`
/// in-order to let them be pattern-matched
///
/// - Note: In pattern-matching, matches with `pattern` if it is *prefix* of given `Image`. For more information see `~=`. You can
/// disable this behavior by setting `isPrefixMatchingEnabled` to `false`
///
/// Sample usage:
///
/// 	extension Image {
/// 	    static let profile:      Self = "profile"
/// 	    static let profileFill:  Self = "profile.fill"
/// 	    static let profileMulti: Self = "profile.multi"
/// 	}
///
/// 	imageView.sd.image = .profile
/// 	imageView.sd.image = .renderingMode(.alwaysTemplate, of: .profile)
///
/// `Image` uses custom pattern-matchin.  in the example given, `profileMulti` would match
/// with `profile` if it is checked before `profileMulti`:
///
///  	switch Image.profileMulti {
///  	case .profile: // Will match ✅
///  	case .profileMulti: // Will not match ❌
///  	}
///
/// And without `isPrefixMatchingEnabled`:
///
/// 	Image.isPrefixMatchingEnabled = false
/// 	switch Image.profileMulti {
///  	case .profile: // Will not match ❌
///  	case .profileMulti: // Will match ✅
///  	}
///
/// - SeeAlso: `~=` method in this file
public struct Image: Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
	
	/// A type that represents a `Image` name
	public typealias StringLiteralType = String
	
	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `profile.fill` can be matched with `profile`
	public static var isPrefixMatchingEnabled: Bool = true
	
	/// This type is used internally to manage transformations if applied to current `Image` before fetching `UIImage`
	let resolver: Resolver
	
	/// Name of the `Image`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Image`, hence no specific `name` is available
	public var name: String? {
		switch resolver {
		case .name(let name): return name
		default: return nil
		}
	}
	
	/// Initiates a `Image` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Images
	///
	/// - Parameter name: Name of the Image.
	public init(_ name: String) { resolver = .name(name) }
	
	/// Ease of use on defining `Image` variables
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }
	
	/// Describes specification of `UIImage` that will be *fetched*/*generated*
	///
	///  - Note: `Image`s with transformations will not be sent to `ImageScheme`s directly
	///
	///  Samples:
	///
	/// 	Image("profile")
	/// 	// description: `profile`
	/// 	Image.profile.transform { $0 }
	/// 	// description: `{profile->t}`
	/// 	Image.profile.renderingMode(.alwaysTemplate)
	/// 	// description: `profile(alwaysTemplate)`
	/// 	Image("profile", bundle: .main)
	/// 	// description: `{profile(bundle:com.farzadshbfn.styled)}`
	///
	public var description: String { resolver.description }
	
	/// Enables the pattern-matcher (i.e switch-statement) to patch `profile.fill` with `profile` if `profile.fill` is not available
	/// in the switch-statement
	/// - Parameter pattern: `Image` to match as prefix of the current value
	/// - Parameter value: `Image` given to find the best match for
	@inlinable public static func ~=(pattern: Image, value: Image) -> Bool {
		if isPrefixMatchingEnabled {
			guard let valueName = value.name, let patternName = pattern.name else { return false }
			return valueName.hasPrefix(patternName)
		}
		return value == pattern
	}
}

extension Image: Item {
	
	typealias Scheme = ImageScheme
	
	typealias Result = UIImage
	
	/// This type is used to support transformations on `Image` like `.transform`
	typealias Lazy = Styled.Lazy<Image>
	
	/// Internal type to manage Lazy or direct fetching of `UIImage`
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
	
	/// This method is used internally to manage transformations (if any) and provide `UIImage`
	/// - Parameter scheme:A `ImageScheme` to fetch `UIImage` from
	func resolve(from scheme: ImageScheme) -> UIImage? {
		switch resolver {
		case .name: return scheme.image(for: self)
		case .lazy(let lazy): return lazy.item(scheme)
		}
	}
	
	/// Enables `Image` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
}

/// Hiding `Image` information on reflection
extension Image: CustomReflectable {
	public var customMirror: Mirror { .init(self, children: []) }
}

extension Image {
	
	/// Will return the backed `Image` with given `renderingMode`
	/// - Parameter renderingMode: `UIImage.RenderingMode`
	public func renderingMode(_ renderingMode: UIImage.RenderingMode) -> Image {
		return .init(lazy: .init(name: "\(self)(\(renderingMode.rawValue))") { scheme in
			guard let image = self.resolve(from: scheme) else { return nil }
			return image.withRenderingMode(renderingMode)
			})
	}
	
	/// Will return the given `Image` with the given renderingMode
	/// - Parameter renderingMode: `UIImage.RenderingMode`
	/// - Parameter image: `Image`
	public static func renderingMode(_ renderingMode: UIImage.RenderingMode,
									 of image: Image) -> Image {
		image.renderingMode(renderingMode)
	}
}

// MARK:- ImageScheme
/// Use this protocol to provide `UIImage` for `Styled`
///
/// Sample:
///
/// 	struct DarkImageScheme: ImageScheme {
/// 	    func image(for image: Image) -> UIImage? {
/// 	        switch image {
/// 	        case .profile: // return profile image
/// 	        case .dashboard: // return dashboard image
/// 	        default: fatalError("New `Image` detected: \(image)")
/// 	        }
/// 	    }
/// 	}
///
public protocol ImageScheme {
	
	/// `StyleDescriptor` will use this method to fetch `UIImage`
	///
	/// - Important: **Do not** call this method directly. use `UIImage.styled(_:)` instead.
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `image`
	/// - Note: Returning `nil` translates to **not supported** by this scheme. Returning `nil` will not guarantee that the associated object
	/// will receive `nil` as `UIImage`
	/// - Note: It's guaranteed all `Image`s sent to this message, will contain field `name`
	///
	/// Sample for `DarkImageScheme`:
	///
	/// 	struct DarkImageScheme: ImageScheme {
	/// 	    func image(for image: Image) -> UIImage? {
	/// 	        switch image {
	/// 	        case .profileFill: // return profile filled image
	/// 	        case .profileMulti: // return multi profile image
	/// 	        default: fatalError("Forgot to support \(image)")
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter image: `Image` type to fetch `UIImage` from current scheme
	func image(for image: Image) -> UIImage?
}

extension Image {
	
	/// Will fetch `Image`s from Assets Catalog
	///
	/// - Note: `Image.isPrefixMatchingEnabled` does not affect `Image.DefaultScheme` since
	/// Assets Catalog  uses prefixMatching for loading `UIImage`
	///
	/// - SeeAlso: NoScheme
	/// - SeeAlso: Image(_:bundle:)
	public struct DefaultScheme: ImageScheme {
		
		public init() { }
		
		public func image(for image: Image) -> UIImage? { .named(image.name!, in: nil) }
	}
	
	/// Will return `nil` for all `Image`s
	///
	/// - Important: It's recommended to use `NoScheme` when using `.init(_:bundle:)` version of `Image`
	public struct NoScheme: ImageScheme {
		
		public init() { }
		
		public func image(for image: Image) -> UIImage? { nil }
	}
	
	/// Fetches `UIImage` from ImageAsset defined in given `Bundle`
	///
	/// - Note: `Image`s initialized with this initializer, will not be sent **directly** to `ImageScheme`. In `ImageScheme`
	/// read `name` variable to determine what to do.
	///
	/// - Parameter name: Name of the image to look-up in Assets Catalog
	/// - Parameter bundle: `Bundle` to look into it's Assets
	/// - SeeAlso: `XcodeAssetsImageScheme`
	public init(_ name: String, bundle: Bundle) {
		resolver = .lazy(.init(name: "\(name)(bundle:\(bundle.bundleIdentifier ?? ""))") {
			$0.image(for: .init(name)) ?? UIImage.named(name, in: bundle)
			})
	}
}

// MARK: UIImage+Extensions
extension UIImage {
	
	/// Will look in the Assets catalog in given `Bundle` for the given image
	///
	/// - Note: if `Image.isPrefixMatchingEnabled` is `true` will try all possbile variations
	///
	/// - Parameter imageName: `String` name of the `Image` (mostly it's description"
	/// - Parameter bundle: `Bundle` to look into it's Assets Catalog
	fileprivate class func named(_ imageName: String, in bundle: Bundle?) -> UIImage? {
		UIImage(named: imageName, in: bundle, compatibleWith: nil)
	}
	
	/// Will fetch `UIImage` defined in given `ImageScheme`
	/// - Parameter image: `Image`
	/// - Parameter scheme: `ImageScheme` to search for image. (default: `Config.imageScheme`)
	open class func styled(_ image: Image, from scheme: ImageScheme = Config.imageScheme) -> UIImage? {
		image.resolve(from: scheme)
	}
}
