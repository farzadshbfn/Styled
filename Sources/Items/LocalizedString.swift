//
//  LocalizedString.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

public struct LocalizedString: Hashable, CustomStringConvertible, ExpressibleByStringInterpolation {
	
	/// A type that represents a `LocalizedString` key
	public typealias StringLiteralType = String
	
	/// This type is used internally to manage transformations if applied to current `LocalizedString` before fetching `String`
	let resolver: Resolver
	
	/// Key of the `LocalizedString`.
	///
	/// - Note: This field is optional because there might be transformations applied to this `LocalizedString`, hence no specific `key` is available
	///
//	public var key: String? {
//		switch resolver {
//		case .key(let key): return key
//		default: return nil
//		}
//	}
	
	/// Describes specification of `String` that will be *fetched*/*generated*
	///
	///  - Note: If description contains `{...}` it means this `LocalizedString` contains transformations
	///
	///  Samples:
	///
	/// 	LocalizedString("Ok")
	/// 	// description: "Ok"
	/// 	LocalizedString("Result is: \(42)")
	/// 	// description: "Result is: %@"
	/// 	LocalizedString("Results are \(42) and \(42)")
	/// 	// description: "Results are %@" and %@"
	/// 	LocalizedString("Cancel").transform { $0 }
	/// 	// description: "{Cancel->t}"
	/// 	LocalizedString("Ok", bundle: .main)
	/// 	// description: "{Ok(com.farzadshbfn.styled)}"
	///
	public var description: String { resolver.description }
	
	/// Ease of use on defining `LocalizedString` variables
	///
	/// 	extension Color {
	/// 	    static let primary:   Self = "primary"
	/// 	    static let secondary: Self = "secondary"
	/// 	}
	///
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) {
//		self.init(value)
		fatalError("Unimplemented")
	}
}

extension LocalizedString: Item {
		
	typealias Scheme = LocalizedStringScheme
	
	typealias Result = String
	
	/// This type is used to support transformations on `LocalizedString` like `.transform`
	typealias Lazy = Styled.Lazy<LocalizedString>
	
	/// Internal type to manage Lazy or direct fetching of `String`
	enum Resolver: Hashable, CustomStringConvertible {
		case key(String)
		case lazy(Lazy)
		
		/// Contains description of current `Resolver` state.
		///
		/// - Note: `Lazy` is surrounded by `{...}`
		///
		var description: String {
			switch self {
			case .key(let name): return name
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}
	
	public struct StringInterpolation: StringInterpolationProtocol {
		enum Item {
			case literal(String)
		}
		/// A type that represents a `LocalizedString` keys
		public typealias StringLiteralType = String
		
		public init(literalCapacity: Int, interpolationCount: Int) {
			fatalError("Unimplemented")
		}
		
		public mutating func appendLiteral(_ literal: String) {
			fatalError("Unimplemented")
		}
		
		public mutating func appendInterpolation<T>(_ value: T) where T: CustomStringConvertible {
			fatalError("Unimplemented")
		}
		
	}
	
	init(lazy: Lazy) { resolver = .lazy(lazy) }
	
	public init(stringInterpolation: LocalizedString.StringInterpolation) {
		fatalError("Unimplemented")
	}
	
	func resolve(from scheme: LocalizedStringScheme) -> String? {
		fatalError("Unimplemented")
//		switch resolver {
//		case .key: return scheme.string(for: self)
//		case .lazy(let lazy): return lazy.item(scheme)
//		}
	}
}


protocol LocalizedStringScheme {
	
	func string(for localizedString: LocalizedString) -> String?
}
