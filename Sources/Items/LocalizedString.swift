//
//  LocalizedString.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

// MARK:- LocalizedString
/// Used to fetch string on runtime based on current `LocalizedString` from `.strings` or `.stringsdict` files
///
/// - Note: Unlike other `Styled.Item`s, try not to define `LocalizedString`s as static variables. It's in conflict with Localization's nature.
/// Instead try to load localizations from a resource (` File`, `.xml`,` .plist`, `.strings`, `.stringsdict`, ...)
///
/// Sample usage:
///
/// 	label.sd.text = "Hello World!"
/// 	label.sd.text = "Hello \(42) times 👍🏼"
public struct LocalizedString: Hashable, CustomStringConvertible, ExpressibleByStringInterpolation {
	
	/// A type that represents a `LocalizedString` key
	public typealias StringLiteralType = String
	
	/// This type is used internally to manage transformations if applied to current `LocalizedString` before fetching `String`
	let resolver: Resolver
	
	/// Key of the `LocalizedString`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `LocalizedString`, hence no specific `key` is available
	public var key: String? {
		switch resolver {
		case .localized(let key, _): return key
		default: return nil
		}
	}
	
	/// Processed arguments of the `LocalizedString`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `LocalizedString`, hence no specific `arguments` are available
	public var arguments: [String]? {
		switch resolver {
		case .localized(_, let arguments): return arguments.map { $0.description }
		default: return nil
		}
	}
	
	/// Initiates a `LocalizedString` with given key, to be fetched later
	///
	/// - Note: Unlike other `Styled.Item`s, try not to define `LocalizedString`s as static variables. It's in conflict with it's nature
	///
	/// - Parameter key: Key of the localization to look-up in tables later.
	public init(_ key: String) { resolver = .localized(key: key, arguments: []) }
	
	
	/// Ease of use in defining `LocalizedString` variables
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(value) }
	
	/// Describes specification of `String` that will be *fetched*/*generated*
	///
	///  - Note: If description contains `{...}` it means this `LocalizedString` contains transformations
	///
	///  Samples:
	///
	/// 	LocalizedString("Ok")
	/// 	// description: `"Ok" []`
	/// 	LocalizedString("Result is: \(42)")
	/// 	// description: `"Result is: %@" [42]`
	/// 	LocalizedString("Results are \(42) and \(24)")
	/// 	// description: `"Results are %@" and %@" [42, 24]`
	/// 	LocalizedString("Cancel").transform { $0 }
	/// 	// description: `{"Cancel" []->t}`
	/// 	LocalizedString("Ok", bundle: .main)
	/// 	// description: `{"Ok" [](bundle:com.farzadshbfn.styled)}`
	public var description: String { resolver.description }
}

extension LocalizedString: Item {
	
	typealias Scheme = LocalizedStringScheme
	
	typealias Result = String
	
	/// This type is used to support transformations on `LocalizedString` like `.normalized`
	typealias Lazy = Styled.Lazy<LocalizedString>
	
	/// Internally manages `Argument`s passed to `StringInterpolation`
	struct Argument: Hashable, CustomStringConvertible {
		
		/// Value provided in Interpolation
		let value: Any
		
		/// Formatter to format `value` if provided in Interpolation for formatting types
		let formatter: Formatter?
		
		/// Holds initial hashValue of `value` to enable comparision between instances
		let valueHashValue: Int
		
		/// - Parameter value: Any `Hashable` instance
		/// - Parameter formatter: `Formatter` that can format `Any` values to `String`
		init<Value>(value: Value, formatter: Formatter? = nil) where Value: Hashable {
			self.value = value
			self.formatter = formatter
			self.valueHashValue = value.hashValue
		}
		
		/// Generated `String` that will be **interpolated** inside the final result
		var description: String { formatter?.string(for: value) ?? "\(value)" }
		
		/// - Returns: `hashValue` of given parameters when initializing `Argument`
		func hash(into hasher: inout Hasher) { hasher.combine(hashValue) }
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: Argument, rhs: Argument) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// Internal type to manage Lazy or direct fetching of `String`
	enum Resolver: Hashable, CustomStringConvertible {
		case localized(key: String, arguments: [Argument])
		case lazy(Lazy)
		
		/// Contains description of current `Resolver` state.
		///
		/// - Note: `Lazy` is surrounded by `{...}`
		var description: String {
			switch self {
			case .localized(let key, let arguments): return "\"\(key)\" \(arguments)"
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}
	
	/// The type each segment of a string literal containing interpolations should be appended to.
	///
	/// - Important: In *right-hand-side* of the localization file, always use **%@** even when custom specifier is provided in interpolation
	public struct StringInterpolation: StringInterpolationProtocol {
		/// A type that represents a `LocalizedString` literals
		public typealias StringLiteralType = String
		
		/// Will incrementally contain localizedKey that needs to be fetched from *.strings* or *.stringsdict* tables
		var key: String = ""
		
		/// Will incrementally contain arguments passed to `StringInterpolation` as interpolations
		var arguments: [Argument] = []
		
		public init(literalCapacity: Int, interpolationCount: Int) {
			key.reserveCapacity(literalCapacity + interpolationCount * 2)
			arguments.reserveCapacity(interpolationCount)
		}
		
		/// Used by system to generate the final string
		public mutating func appendLiteral(_ literal: String) {
			key.append(literal)
		}
		
		/// Any `CustomStringConvertible` type can be interpolated
		public mutating func appendInterpolation<T>(_ value: T) where T : CustomStringConvertible {
			arguments.append(.init(value: value.description))
			key.append("%@")
		}
		
		/// `Hashable` types that are also `CustomStringConvertbile` will not be converted to `String` instantly,
		/// it will be converted to `String` while generating the final result
		/// - Parameter value: Any `Hashable` value.
		public mutating func appendInterpolation<T>(_ value: T) where T : CustomStringConvertible & Hashable {
			arguments.append(.init(value: value))
			key.append("%@")
		}
		
		/// Use this method to provide custom `Formatter` for types like `Date`, `TimeZone`, `Locale` and ...
		///
		/// - Important: `Formatter` will apply formatting to `Subject` when generating the final result and not when this method is called.
		/// - Important: If `Formatter` fails to format the given `Subject`, `Subject` itself will be used in final-result.
 		/// - Note: `Formatter` will be used **as-is**. Remember to sync `Formatter` configurations (`locale`, `timeZone`, ...)
		/// in your application
		///
		/// - Parameter subject: Any `ReferenceConvertbile` type like `Date`, `TimeZone`, `Locale` and ...
		/// - Parameter formatter: `Formatter` instance like `NumberFormatter`, `DateFormatter` or custom `Formatter`s
		public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject: ReferenceConvertible {
			arguments.append(.init(value: subject, formatter: formatter))
			key.append("%@")
		}
		
		/// Use this method to provide custom `Formatter` for any type that can be formatted
		///
		/// - Important: `Formatter` will apply formatting to `Subject` when generating the final result and not when this method is called.
		/// - Important: If `Formatter` fails to format the given `Subject`, `Subject` itself will be used in final-result.
 		/// - Note: `Formatter` will be used **as-is**. Remember to sync `Formatter` configurations (`locale`, `timeZone`, ...)
		/// in your application
		///
		/// - Parameter subject: Any `NSObject` type that can be formatted
		/// - Parameter formatter: `Formatter` instance like `NumberFormatter`, `DateFormatter` or custom `Formatter`s
		public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject: NSObject {
			arguments.append(.init(value: subject, formatter: formatter))
			key.append("%@")
		}
		
		/// Provide custom specifier to change generated `key` which be looked-up in .strings or .stringsdict files.
		///
		/// - Important: Passing customized `specifier` will **only** affect the generated localized key which be looked-up
		/// in .strings or .stringsdict files. **Always** provide localization result with **%@**
		/// - Note: Passed `value` will not be converted to `String` instantly, it will be converted to `String` in generating final results
		///
		/// - Parameter value: Any `Hashable` value
		/// - Parameter specifier: Custom `specifier` to use in generating localization key. (default is **%@**)
		public mutating func appendInterpolation<Value>(_ value: Value, specifier: String = "%@") where Value: Hashable {
			arguments.append(.init(value: value))
			key.append(specifier)
		}
		
		/// Provide custom specifier to change generated `key` which be looked-up in .strings or .stringsdict files.
		///
		/// - Important: Passing customized `specifier` will **only** affect the generated localized key which be looked-up
		/// in .strings or .stringsdict files. **Always** provide localization result with **%@**
		///
		/// - Parameter value: `Any`
		/// - Parameter specifier: Custom `specifier` to use in generating localization key. (default is **%@**)
		public mutating func appendInterpolation<Value>(_ value: Value, specifier: String = "%@") {
			arguments.append(.init(value: "\(value)"))
			key.append(specifier)
		}
		
		// TODO: support for localized number entry
	}
	
	public init(stringInterpolation: LocalizedString.StringInterpolation) {
		resolver = .localized(
			key: stringInterpolation.key,
			arguments: stringInterpolation.arguments
		)
	}
	
	/// This method is used internally to manage transformations (if any) and provide localized `String`
	/// - Parameter scheme:A `LocalizedStringScheme` to fetch `String` from
	func resolve(from scheme: LocalizedStringScheme) -> String? {
		switch resolver {
		case .localized: return scheme.string(for: self)
		case .lazy(let lazy): return lazy.item(scheme)
		}
	}
	
	/// Enables `LocalizedString` to accept transformations
	/// - Parameter lazy: `Lazy` instance
	init(lazy: Lazy) { resolver = .lazy(lazy) }
}

/// Hiding `LocalizedString` information on reflection
extension LocalizedString: CustomReflectable {
	public var customMirror: Mirror { .init(self, children: []) }
}

// MARK:- LocalizedStringScheme
/// Use this protocol to provide `String` for `LocalizedString
///
/// Sample:
///
///  	struct SpanishLocalizedStringScheme: LocalizedStringScheme {
///  	    func string(for localizedString: LocalizedString) -> String? {
///  	        // Fetch `localizedString.key!` from a known resource and format with `localizedStirng.arguments!`
///
///  	        // We can also manage plural localization by identifying the `localizedString.key!` and reordering
///  	        /// `localizedString.arguments` in a way that is needed in plural localization
///  	    }
///  	}
public protocol LocalizedStringScheme {
	
	/// `StyleDescriptor` will use this method to fetch localized `String`
	///
	/// - Important: **Do not** call this method directly. use `String.styled(_:)` instead.
	///
	/// - Note: Returning `nil` translates to **not supported** by this scheme. Returning `nil` will not guarantee that the associated object
	/// will receive `nil` as `UIColor`
	/// - Note: It's guaranteed all `String`s sent to this message, will contain fields `key` and `arguments`
	///
	/// Sample for `SpanishLocalizedStringScheme`:
	///
	///  	struct SpanishLocalizedStringScheme: LocalizedStringScheme {
	///  	    func string(for localizedString: LocalizedString) -> String? {
	///  	        // Fetch `localizedString.key!` from a known resource and format with `localizedStirng.arguments!`
	///
	///  	        // We can also manage plural localization by identifying the `localizedString.key!` and reordering
	///  	        /// `localizedString.arguments` in a way that is needed in plural localization
	///  	    }
	///  	}
	///
	/// - Parameter localizedString: `LocalizedString` type to fetch `String` from current scheme
	func string(for localizedString: LocalizedString) -> String?
}

extension LocalizedString {
	
	/// Will fetch `String`s from **Localizable.strings** and **Localizable.stringsdict** files
	/// - SeeAlso: NoScheme
	/// - SeeAlso: LocalizedString(_:bundle:useKeyAsValue:table)
	public struct DefaultScheme: LocalizedStringScheme {
		
		/// This flag controls wether return `String` should be mirrored to generated `key` or not
		///
		/// - Note: If you're using `.init(_:bundle:)` version of `LocalizedString`, This flag should be set to false in-order to make that work
		public var useKeyAsValue: Bool
		
		public init(useKeyAsValue: Bool = true) {
			self.useKeyAsValue = useKeyAsValue
		}
		
		public func string(for localizedString: LocalizedString) -> String? {
			.localized(localizedString, in: .main, useKeyAsValue: useKeyAsValue, table: nil)
		}
	}
	
	/// Will return `nil` for all `LocalizedString`s
	///
	/// - Important: It's recommended to use `NoScheme` when using `.init(_:bundle:useKeyAsValue:table)` version of `LocalizedString`
	public struct NoScheme: LocalizedStringScheme {
		
		public init() { }
		
		public func string(for localizedString: LocalizedString) -> String? { nil }
	}

	
	/// Initializes a LocalizedString which will look in the Bundle for **.strings** and **.stringdict**
	///
	/// - Note: `LocalizedString`s initialized with this initializer, will not be sent **directly** to `LocalizedStringScheme`.
	/// In `LocalizedStringScheme` read `key` & `arguments` variables to determine what to do.
	///
	/// - Parameter localizedString: `LocalizedString` to look-up
	/// - Parameter bundle: `Bundle` to search for localizable files in
	/// - Parameter useKeyAsValue: If `true`, will send `value` to localization method to be used in `key`'s place if key look-up was not successful
	/// - Parameter table: Name of **.strings** and **.stringsdict** files. If `nil` is provided,
	/// will look into **Localizable.strings** and **Localizable.stringsdict**
	public init(_ localizedString: LocalizedString, bundle: Bundle, useKeyAsValue: Bool = true, table: String? = nil) {
		resolver = .lazy(.init(name: "\(localizedString)(bundle:\(bundle.bundleIdentifier ?? ""))") {
			$0.string(for: localizedString) ?? String.localized(localizedString, in: bundle, useKeyAsValue: useKeyAsValue, table: table)
		})
	}
}

// MARK:- String+Extensions
extension String {
	
	/// Will fetch `String` defined in given `LocalizedStringScheme`
	/// - Parameter localizedString: `LocalizedString`
	/// - Parameter scheme: `LocalizedStringScheme` to search for string. (default: `Config.localizedStringScheme`)
	public static func styled(_ localizedString: LocalizedString, from scheme: LocalizedStringScheme = Config.localizedStringScheme) -> String? {
		localizedString.resolve(from: scheme)
	}
	
	/// Will look in the Bundle for **.strings** and **.stringdict**
	/// - Parameter localizedString: `LocalizedString` to look-up
	/// - Parameter bundle: `Bundle` to search for localizable files in (default is `.main`)
	/// - Parameter useKeyAsValue: If `true`, will send `value` to localization method to be used in `key`'s place if key look-up was not successful
	/// - Parameter table: Name of **.strings** and **.stringsdict** files. If `nil` is provided,
	/// will look into **Localizable.strings** and **Localizable.stringsdict**
	/// - Returns: `nil` If `useKeyAsValue` is `false` and `localizedString.key` was not found in provided `table`
	fileprivate static func localized(_ localizedString: LocalizedString, in bundle: Bundle = .main, useKeyAsValue: Bool, table: String?) -> String? {
		guard let key = localizedString.key, let args = localizedString.arguments else { return nil }
		/// Point here is to have `notFound` as always not equal to `key`
		let notFound = key != "<~@#*#@~>" ? "<~@#*#@~>" : ">~@#*#@~<"
		let format = bundle.localizedString(
			forKey: key,
			value: useKeyAsValue ? key : notFound,
			table: table
		)
		return format != notFound ? .init(format: format, arguments: args ) : nil
	}
}
