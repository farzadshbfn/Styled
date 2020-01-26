//
//  Item.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

/// Used to encapsulate all `Styled` types
protocol Item: Hashable, CustomStringConvertible {

	/// Defines the type that will act as dataprovider of this `Item` and provides a `Result` for each given `Item`
	associatedtype Scheme

	/// Defines the Type that this `Item` is trying to encapsulate to be calculated on runtime and synchronized automatically
	associatedtype Result

	/// This method checks for transformations first, then fetches needed `Item` from `Scheme` and after applying all transformations, returns the `Result`
	/// - Parameter scheme: `Scheme` to provide `Result` for `Item`s needed
	func resolve(from scheme: Scheme) -> Result?

	/// Each Item needs to support Lazy calculation in-order to enable `Item` to accept transformations
	/// - Parameter lazy: `Lazy<Self>`
	init(lazy: Lazy<Self>)
}

extension Item {

	/// Applies custom transformations on the `Item.Result`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `Item.Result`
	public func transform(named name: String = "t", _ transform: @escaping (Result) -> Result) -> Self {
		return .init(lazy: .init(name: "\(self)->\(name)", { scheme in
			guard let item = self.resolve(from: scheme) else { return nil }
			return transform(item)
		}))
	}

	/// Applies custom transformations on the `Item.Result` fetched from `Item`
	/// - Parameter item: `Item` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `Item.Result`
	public static func transforming(_ item: Self,
	                                named name: String = "t",
	                                _ transform: @escaping (Result) -> Result) -> Self {
		item.transform(named: name, transform)
	}
}
