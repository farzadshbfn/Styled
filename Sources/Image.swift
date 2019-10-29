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
/// 	    static let profile      = Self("profile")
/// 	    static let profileFill  = Self("profile.fill")
/// 	    static let profileMulti = Self("profile.multi")
/// 	}
///
/// 	imageView.styled.image = .profile
/// 	imageView.styled.image = .renderingMode(.alwaysTemplate, of: .profile)
///
/// `Image` uses custom pattern-matchin.  in the example given, `profileMulti` would match
/// with `profile` if it is checked before `profileMulti`:
///
///  	switch Image.profileMulti {
///  	case .profile: // Will match ✅sa
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
public struct Image: Hashable, CustomStringConvertible ,ExpressibleByStringLiteral {
	/// A type that represents a `Image` name
	public typealias StringLiteralType = String
	
	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `profile.fill` can be matched with `profile`
	public static var isPrefixMatchingEnabled: Bool = true
	
	/// Initiates a `Image` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Images
	///
	/// - Parameter name: Name of the Image.
	public init(_ name: String) { resolver = .name(name) }
	
	/// This type is used internally to manage transformations if applied to current `Image` before fetching `UIImage`
	let resolver: Resolver
	
	/// Name of the `Image`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `Image`, hence no specific `name` is available
	///
	public var name: String? {
		switch resolver {
		case .name(let name): return name
		default: return nil
		}
	}
	
	/// Describes specification of `UIImage` that will be *fetched*/*generated*
	///
	///  - Note: `Image`s with transformations will not be sent to `ImageScheme`s directly
	///
	///  Samples:
	///
	/// 	Image("profile")
	/// 	// description: "profile"
	/// 	Image.profile.transform { $0 }
	/// 	// description:  "{profile->t}"
	/// 	Image.profile.renderingMode(.alwaysTemplate)
	/// 	// description: "profile(alwaysTemplate)"
	/// 	Image("profile", bundle: .main)
	/// 	// description: "{profile(com.farzadshbfn.styled)}"
	///
	public var description: String { resolver.description }
	
	/// Ease of use on defining `Image` variables
	///
	/// 	extension Image {
	/// 	    static let profile:   Self = "profile"
	/// 	    static let dashboard: Self = "dashboard"
	/// 	}
	///
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }
	
	/// Enables the pattern-matcher (i.e switch-statement) to patch `profile.fill` with `profile` if `profile.fill` is not available
	/// in the switch-statement
	///
	/// - Parameter pattern: `Image` to match as prefix of the current value
	/// - Parameter value: `Image` given to find the best match for
	@inlinable public static func ~=(pattern: Image, value: Image) -> Bool {
		if isPrefixMatchingEnabled {
			guard let valueName = value.name, let patternName = pattern.name else { return false }
			return valueName.hasPrefix(patternName)
		} else {
			return value == pattern
		}
	}
}

extension Image {
	
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
	
	/// This type is used to support transformations on `Image` like `renderMode`
	struct Lazy: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `Image` in order to let `Image` hold `Lazy` in its definition
		let imageHashValue: Int
		
		/// Describes current image that will be returned
		let imageDescription: String
		
		/// Describes current image that will be returned
		var description: String { imageDescription }
		
		/// Provides `UIImage` which can be backed by `Image` or static `UIImage`
		let image: (_ scheme: ImageScheme) -> UIImage?
		
		/// Used internally to pre-calculate hashValue of Internal `Image`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIImage` from `Image` when needed
		init(_ image: Image) {
			imageHashValue = Self.hashed("Image", image)
			imageDescription = image.description
			self.image = image.resolve
		}
		
		/// Will use custom Provider to provide `UIImage` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ imageProvider: @escaping (_ scheme: ImageScheme) -> UIImage?) {
			imageHashValue = Self.hashed("ImageProvider", name)
			imageDescription = name
			image = imageProvider
		}
		
		/// - Returns: `hashValue` of given parameters when initializing `Lazy`
		func hash(into hasher: inout Hasher) { hasher.combine(imageHashValue) }
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: Lazy, rhs: Lazy) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// This method is used internally to manage transformations (if any) and provide `UIImage`
	/// - Parameter scheme:A `ImageScheme` to fetch `UIImage` from
	func resolve(from scheme: ImageScheme) -> UIImage? {
		switch resolver {
		case .name: return scheme.image(for: self)
		case .lazy(let lazy): return lazy.image(scheme)
		}
	}
	
	/// Enables `Image` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
	
	
	/// Will return the backed `Image` with given `renderingMode`
	///
	/// - Parameter renderingMode: `UIImage.RenderingMode`
	public func renderingMode(_ renderingMode: UIImage.RenderingMode) -> Image {
		return .init(lazy: .init(name: "\(self)(\(renderingMode.rawValue))") { scheme in
			guard let image = self.resolve(from: scheme) else { return nil }
			return image.withRenderingMode(renderingMode)
			})
	}
	
	/// Will return the given `Image` with the given renderingMode
	///
	/// - Parameter renderingMode: `UIImage.RenderingMode`
	/// - Parameter image: `Image`
	public static func renderingMode(_ renderingMode: UIImage.RenderingMode,
									 of image: Image) -> Image {
		image.renderingMode(renderingMode)
	}
	
	/// Applies custom transformations on the `UIImage`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIImage`
	public func transform(named name: String = "t", _ transform: @escaping (UIImage) -> UIImage) -> Image {
		return .init(lazy: .init(name: "\(self)->\(name)", { scheme in
			guard let image = self.resolve(from: scheme) else { return nil }
			return transform(image)
		}))
	}
	
	/// Applies custom transformations on the `UIImage` fetched from `Image`
	/// - Parameter image: `Image` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIImage`
	public static func transforming(_ image: Image,
									named name: String = "t",
									_ transform: @escaping (UIImage) -> UIImage) -> Image {
		image.transform(named: name, transform)
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
	
	/// `Styled` will use this method to fetch `UIImage`
	///
	/// - Important: **Do not** call this method directly. use `UIImage.styled(_:)` instead.
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `image`
	///
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

/// Will fetch `Image`s from Assets Catalog
///
/// - Note: `Image.isPrefixMatchingEnabled` does not affect `DefaultImageScheme` since
/// Assets Catalog  uses prefixMatching for loading `UIImage`
///
/// - SeeAlso: `Image(_:,bundle:)`
public struct DefaultImageScheme: ImageScheme {
	
	public func image(for image: Image) -> UIImage? { .named(image.description, in: nil) }
	
	public init() { }
}

extension Image {
	/// Fetches `UIImage` from ImageAsset defined in given `Bundle`
	///
	/// - Note: `Image`s initialized with this initializer, will not be sent **directly** to `ImageScheme`. In `ImageScheme`
	/// read `name` variable to determine what to do.
	///
	/// - Parameter name: Name of the image to look-up in Assets Catalog
	/// - Parameter bundle: `Bundle` to look into it's Assets
	/// - SeeAlso: `XcodeAssetsImageScheme`
	public init(_ name: String, bundle: Bundle) {
		resolver = .lazy(.init(name: "\(name)(\(bundle.bundleIdentifier ?? "bundle.not.found"))") {
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
	///
	/// - Parameter image: `Image`
	/// - Parameter scheme: `ImageScheme` to search for image. (default: `Config.imageScheme`)
	open class func styled(_ image: Image, from scheme: ImageScheme = Config.imageScheme) -> UIImage? {
		image.resolve(from: scheme)
	}
}

// MARK:- StyledWrapper
extension StyledWrapper {
	
	/// Will get called when  `Config.imageSchemeDidChange` is raised or `applyImages()` is called or `currentImageScheme` changes
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onImageSchemeChange(withId id: Styled.ClosureId = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return styled.colorUpdates[id] = nil }
		styled.colorUpdates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}
	
	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ image: Image?, _ apply: @escaping (Base, UIImage?) -> Void) -> Styled.Update<Image>? {
		guard let image = image else { return nil }
		let styledUpdate = Styled.Update(item: image) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, image.resolve(from: scheme))
		}
		styledUpdate.refresh(styled.imageScheme)
		return styledUpdate
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIImage>) -> Image? {
		get { styled.imageUpdates[keyPath]?.item }
		set { styled.imageUpdates[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1! : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIImage?>) -> Image? {
		get { styled.imageUpdates[keyPath]?.item }
		set { styled.imageUpdates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGImage>) -> Image? {
		get { styled.imageUpdates[keyPath]?.item }
		set {
			styled.imageUpdates[keyPath] = update(newValue) { base, image in
				guard let cgImage = image?.cgImage else { return () }
				base[keyPath: keyPath] = cgImage
			}
		}
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGImage?>) -> Image? {
		get { styled.imageUpdates[keyPath]?.item }
		set { styled.imageUpdates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.cgImage } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIImage>) -> Image? {
		get { styled.imageUpdates[keyPath]?.item }
		set {
			styled.imageUpdates[keyPath] = update(newValue) { base, image in
				guard let ciImage = image?.ciImage else { return () }
				base[keyPath: keyPath] = ciImage
			}
		}
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIImage?>) -> Image? {
		get { styled.imageUpdates[keyPath]?.item }
		set { styled.imageUpdates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.ciImage } }
	}
}

// MARK:- Typealises
/// Used to fix namespace conflicts
public typealias StyledImage = Image
/// Used to fix namespaec conflicts
public typealias StyledImageScheme = ImageScheme

