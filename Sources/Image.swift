//
//  Image.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import class UIKit.UIImage

// MARK:- StyledImage
/// Used to fetch Image on runtime based on current Style
///
/// - Important: It's important to follow **dot.case** syntax while defining name of Images. e.g `profile`, `profile.fill`
/// in-order to let them be pattern-matched
///
/// - Note: In pattern-matching, matches with `pattern` if it is *prefix* of given `Image`. For more information see `~=`. You can
/// disable this behavior by setting `isPrefixMatchingEnabled` to `false`
///
/// Sample usage:
///
/// 	extension StyledImage {
/// 	    static let profile      = Self("profile")
/// 	    static let profileFill  = Self("profile.fill")
/// 	    static let profileMulti = Self("profile.multi")
/// 	}
///
/// `StyledImage` uses custom pattern-matchin.  in the example given, `profileMulti` would match
/// with `profile` if it is checked before `profileMulti`:
///
///  	switch StyledImage.profileMulti {
///  	case .profile: // Will match ✅sa
///  	case .profileMulti: // Will not match ❌
///  	}
///
/// And without `isPrefixMatchingEnabled`:
///
/// 	StyledImage.isPrefixMatchingEnabled = false
/// 	switch StyledImage.profileMulti {
///  	case .profile: // Will not match ❌
///  	case .profileMulti: // Will match ✅
///  	}
///
/// - SeeAlso: `~=` method in this file
public struct StyledImage: Hashable, CustomStringConvertible ,ExpressibleByStringLiteral {
	/// A type that represents a `StyledImage` name
	public typealias StringLiteralType = String
	
	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `profile.fill` can be matched with `profile`
	public static var isPrefixMatchingEnabled: Bool = true
	
	/// Initiates a `StyledImage` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Images
	///
	/// - Parameter name: Name of the Image.
	public init(_ name: String) {
		self.description = name
		lazyImage = nil
	}
	
	/// This type is used internally to manage transformations applied to current `StyledImage` before fetcing `UIImage`
	let lazyImage: LazyImage?
	
	/// Describes specification of `UIImage` that will be *fetched*/*generated*
	///
	///  - Note: `StyledImage`s with transformations will not be sent to `StyledImageScheme`s directly
	///
	///  Samples:
	///
	/// 	StyledImage("profile")
	/// 	// description: "profile"
	/// 	StyledImage.profile.transform { $0 }
	/// 	// description:  "(t->profile)"
	///
	public let description: String
	
	/// Ease of use on defining `StyledImage` variables
	///
	/// 	extension StyledImage {
	/// 	    static let profile:   Self = "profile"
	/// 	    static let dashboard: Self = "dashboard"
	/// 	}
	///
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }
	
	/// Enables the pattern-matcher (i.e switch-statement) to patch `profile.fill` with `profile` if `profile.fill` is not available
	/// in the switch-statement
	///
	/// - Parameter pattern: `StyledImage` to match as prefix of the current value
	/// - Parameter value: `StyledImage` given to find the best match for
	@inlinable public static func ~=(pattern: StyledImage, value: StyledImage) -> Bool {
		isPrefixMatchingEnabled ? value.description.hasPrefix(pattern.description) : value == pattern
	}
}

extension StyledImage {
	/// This type is used to support transformations on `StyledImage` like `Blend`
	struct LazyImage: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `StyledImage` in order to let `StyledImage` hold `LazyImage` in its definition
		let imageHashValue: Int
		
		/// Describes current Image that will be returned
		let imageDescription: String
		
		/// Describes current Image that will be returned
		var description: String { imageDescription }
		
		/// Provides `UIImage` which can be backed by `StyledImage` or static `UIImage`
		let image: (_ scheme: StyledImageScheme) -> UIImage?
		
		/// Used internally to pre-calculate hashValue of Internal `Image`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIImage` from `StyledImage` when needed
		init(_ styledImage: StyledImage) {
			imageHashValue = Self.hashed("StyledImage", styledImage)
			imageDescription = styledImage.description
			image = { styledImage.resolve(from: $0) }
		}
		
		/// Will use custom Provider to provide `UIImage` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ ImageProvider: @escaping (_ scheme: StyledImageScheme) -> UIImage?) {
			imageHashValue = Self.hashed("ImageProvider", name)
			imageDescription = name
			image = ImageProvider
		}
		
		/// - Returns: `hashValue` of given parameters when initializing `LazyImage`
		func hash(into hasher: inout Hasher) {
			hasher.combine(imageHashValue)
		}
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: LazyImage, rhs: LazyImage) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// This method is used internally to manage transformations (if any) and provide `UIImage`
	/// - Parameter scheme:A `StyledImageScheme` to fetch `UIImage` from
	func resolve(from scheme: StyledImageScheme) -> UIImage? {
		lazyImage?.image(scheme) ?? scheme.image(for: self)
	}
	
	/// Enables `StyledImage` to accept transformations
	/// - Parameter lazyImage: `LazyImage` instance
	init(lazyImage: LazyImage) {
		self.lazyImage = lazyImage
		self.description = lazyImage.imageDescription
	}
	
	/// Applies custom transformations on the `UIImage`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIImage`
	public func transform(named name: String = "t", _ transform: @escaping (UIImage) -> UIImage) -> StyledImage {
		return .init(lazyImage: .init(name: "(\(name)->\(self))", { scheme in
			guard let Image = self.resolve(from: scheme) else { return nil }
			return transform(Image)
		}))
	}
	
	/// Applies custom transformations on the `UIImage` fetched from `StyledImage`
	/// - Parameter styledImage: `StyledImage` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIImage`
	public static func transforming(_ styledImage: StyledImage,
									named name: String = "t",
									_ transform: @escaping (UIImage) -> UIImage) -> StyledImage {
		styledImage.transform(named: name, transform)
	}
}

// MARK:- StyledImageScheme
/// Use this protocol to provide `UIImage` for `Styled`
///
/// Sample:
///
/// 	struct DarkImageScheme: StyledImageScheme {
/// 	    func image(for styledImage: StyledImage) -> UIImage? {
/// 	        switch styledImage {
/// 	        case .profile: // return profile image
/// 	        case .dashboard: // return dashboard image
/// 	        default: fatalError("New `StyledImage` detected: \(styledImage)")
/// 	        }
/// 	    }
/// 	}
///
public protocol StyledImageScheme {
	
	/// `Styled` will use this method to fetch `UIImage`
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `styledImage`
	///
	/// - Important: **Do not** call this method directly. use `UIImage.styled(_:)` instead.
	///
	/// Sample for `DarkImageScheme`:
	///
	/// 	struct DarkImageScheme: StyledImageScheme {
	/// 	    func image(for styledImage: StyledImage) -> UIImage? {
	/// 	        switch styledImage {
	/// 	        case .profileFill: // return profile filled image
	/// 	        case .profileMulti: // return multi profile image
	/// 	        default: fatalError("Forgot to support profile itself")
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter styledImage: `StyledImage` type to fetch `UIImage` from current scheme
	func image(for styledImage: StyledImage) -> UIImage?
}

// MARK:- StyledImageAssetsCatalog
/// Will fetch `StyledImage`s from Assets Catalog
///
/// - Note: if `StyledImage.isPrefixMatchingEnabled` is `true`, in case of failure at loading `a.b.c.d` will look for `a.b.c`
/// and if `a.b.c` is failed to be loaded, will look for `a.b` and so on. Will return `nil` if nothing were found.
///
/// - SeeAlso: `StyledImage(_:,bundle:)`
public struct StyledImageAssetsCatalog: StyledImageScheme {
	
	/// - Note: **Do not** Call this method directly
	///
	/// - Parameter styledImage: `StyledImage`
	public func image(for styledImage: StyledImage) -> UIImage? { .named(styledImage.description, in: nil) }
	
	public init() { }
}

extension StyledImage {
	/// Fetches `UIImage` from ImageAsset defined in given `Bundle`
	/// - Parameter name: Name of the image to look-up in Assets Catalog
	/// - Parameter bundle: `Bundle` to look into it's Assets
	/// - SeeAlso: `XcodeAssetsStyledImageScheme`
	public init(_ name: String, bundle: Bundle) {
		self.description = name
		self.lazyImage = .init(name: "Bundle") {
			$0.image(for: .init(name)) ?? UIImage.named(name, in: bundle)
		}
	}
}

// MARK: UIImage+Extensions
extension UIImage {
	
	/// Will look in the Assets catalog in given `Bundle` for the given image
	///
	/// - Note: if `StyledImage.isPrefixMatchingEnabled` is `true` will try all possbile variations
	///
	/// - Parameter styledImageName: `String` name of the `StyledImage` (mostly it's description"
	/// - Parameter bundle: `Bundle` to look into it's Assets Catalog
	fileprivate static func named(_ styledImageName: String, in bundle: Bundle?) -> UIImage? {
		guard StyledImage.isPrefixMatchingEnabled else {
			return UIImage(named: styledImageName, in: bundle, compatibleWith: nil)
		}
		var name = styledImageName
		while name != "" {
			if let Image = UIImage(named: name, in: bundle, compatibleWith: nil) { return Image }
			name = name.split(separator: ".").dropLast().joined(separator: ".")
		}
		return nil
	}
	
	/// Will fetch `UIImage` defined in current `Styled.imageScheme`
	///
	/// - Parameter styledImage: `StyledImage`
	public static func styled(_ styledImage: StyledImage, from scheme: StyledImageScheme = Styled.imageScheme) -> UIImage? {
		styledImage.resolve(from: scheme)
	}
}

// MARK:- StyledWrapper
extension StyledWrapper {
	
	private func update(_ styledImage: StyledImage?, _ apply: @escaping (Base, UIImage?) -> Void) -> StyledUpdate<StyledImage>? {
		guard let styledImage = styledImage else { return nil }
		let styledUpdate = StyledUpdate(value: styledImage) { [weak base] in
			guard let base = base else { return () }
			return apply(base, styledImage.resolve(from: Styled.imageScheme))
		}
		styledUpdate.update()
		return styledUpdate
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `ImageScheme` for given `StyledImage`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `ImageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIImage>) -> StyledImage? {
		get { styled.images[keyPath]?.value }
		set { styled.images[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1! : () } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `ImageScheme` for given `StyledImage`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `ImageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIImage?>) -> StyledImage? {
		get { styled.images[keyPath]?.value }
		set { styled.images[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `ImageScheme` for given `StyledImage`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `ImageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGImage>) -> StyledImage? {
		get { styled.images[keyPath]?.value }
		set {
			styled.images[keyPath] = update(newValue) { base, image in
				guard let cgImage = image?.cgImage else { return () }
				base[keyPath: keyPath] = cgImage
			}
		}
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `ImageScheme` for given `StyledImage`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `ImageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGImage?>) -> StyledImage? {
		get { styled.images[keyPath]?.value }
		set { styled.images[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.cgImage } }
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `ImageScheme` for given `StyledImage`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `ImageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIImage>) -> StyledImage? {
		get { styled.images[keyPath]?.value }
		set {
			styled.images[keyPath] = update(newValue) { base, image in
				guard let ciImage = image?.ciImage else { return () }
				base[keyPath: keyPath] = ciImage
			}
		}
	}
	
	/// Ushin this method, given `KeyPath` will keep in sync with image defined in `ImageScheme` for given `StyledImage`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `ImageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIImage?>) -> StyledImage? {
		get { styled.images[keyPath]?.value }
		set { styled.images[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.ciImage } }
	}
}
