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
	public var key: String? {
		switch resolver {
		case .localized(let key, _): return key
		default: return nil
		}
	}
	
	public var arguments: [String]? {
		switch resolver {
		case .localized(_, let arguments): return arguments.map { $0.description }
		default: return nil
		}
	}
	
	public var keyAndArguments: (key: String, arguments: [String])? {
		switch resolver {
		case .localized(let key, let arguments): return (key, arguments.map { $0.description } )
		default: return nil
		}
	}
	
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
		resolver = .localized(key: value, arguments: [])
	}
}

extension LocalizedString: Item {
		
	typealias Scheme = LocalizedStringScheme
	
	typealias Result = String
	
	/// This type is used to support transformations on `LocalizedString` like `.transform`
	typealias Lazy = Styled.Lazy<LocalizedString>
	
	/// Internal type to manage Lazy or direct fetching of `String`
	enum Resolver: Hashable, CustomStringConvertible {
		case localized(key: String, arguments: [Argument])
		case lazy(Lazy)
		
		/// Contains description of current `Resolver` state.
		///
		/// - Note: `Lazy` is surrounded by `{...}`
		///
		var description: String {
			switch self {
			case .localized(let key, let arguments):
				return "\(key){\(arguments)}"
			case .lazy(let lazy): return "{\(lazy)}"
			}
		}
	}
	
	struct Argument: Hashable, CustomStringConvertible {
		let value: Any
		let formatter: Formatter?
		let valueHashValue: Int
		
		init<Value>(value: Value, formatter: Formatter? = nil) where Value: Hashable {
			self.value = value
			self.formatter = formatter
			self.valueHashValue = value.hashValue
		}
		
		var description: String { formatter?.string(for: value) ?? "\(value)" }
		
		func hash(into hasher: inout Hasher) { hasher.combine(hashValue) }
		
		static func == (lhs: Argument, rhs: Argument) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	public struct StringInterpolation: StringInterpolationProtocol {
		
		public typealias StringLiteralType = String
		
		var key: String = ""
		var arguments: [Argument] = []
		
		public init(literalCapacity: Int, interpolationCount: Int) {
			key.reserveCapacity(literalCapacity + interpolationCount * 2)
			arguments.reserveCapacity(interpolationCount)
		}
		
		public mutating func appendLiteral(_ literal: String) {
			key.append(literal)
		}
		
		public mutating func appendInterpolation(_ string: String) {
			print(#line)
			arguments.append(.init(value: string))
			key.append("%@")
		}
		
		public mutating func appendInterpolation<T>(_ value: T) where T : CustomStringConvertible {
			print(#line)
			arguments.append(.init(value: value.description))
			key.append("%@")
		}
		
		public mutating func appendInterpolation<T>(_ value: T) where T : CustomStringConvertible & Hashable {
			print(#line)
			arguments.append(.init(value: value))
			key.append("%@")
		}
		
		public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject: ReferenceConvertible {
			print(#line)
			arguments.append(.init(value: subject, formatter: formatter))
			key.append("%@")
		}
		
		public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject: NSObject {
			print(#line)
			arguments.append(.init(value: subject, formatter: formatter))
			key.append("%@")
		}
		
		public mutating func appendInterpolation<Value>(_ value: Value, specifier: String = "%@") where Value: Hashable {
			print(#line)
			arguments.append(.init(value: value))
			key.append(specifier)
		}
		
		public mutating func appendInterpolation<Value>(_ value: Value, specifier: String = "%@") {
			print(#line)
			arguments.append(.init(value: "\(value)"))
			key.append(specifier)
		}
	}
	
	init(lazy: Lazy) { resolver = .lazy(lazy) }
	
	public init(stringInterpolation: LocalizedString.StringInterpolation) {
		resolver = .localized(
			key: stringInterpolation.key,
			arguments: stringInterpolation.arguments
		)
	}
	
	public func resolve(from scheme: LocalizedStringScheme) -> String? {
		switch resolver {
		case .localized: return scheme.string(for: self)
		case .lazy(let lazy): return lazy.item(scheme)
		}
	}
}

extension LocalizedString: CustomReflectable {
	public var customMirror: Mirror { .init(self, children: []) }
}

public protocol LocalizedStringScheme {
	
	func string(for localizedString: LocalizedString) -> String?
}

public struct DefaultLocalizedStringScheme: LocalizedStringScheme {
	
	public init() { }
	
	public func string(for localizedString: LocalizedString) -> String? {
		.init(
			format: Bundle.main.localizedString(
				forKey: localizedString.key!,
				value: localizedString.key!,
				table: nil
			),
			arguments: localizedString.arguments!
		)
	}
}
