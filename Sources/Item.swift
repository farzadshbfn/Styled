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
	
	/// Defines the Type thast this `Item` is trying to encapsulate to be calculated on runtime and synchronized automatically
	associatedtype Result
	
	/// This method checks for transformations first, then fetches needed `Item` from `Scheme` and after applying all transformations, returns the `Result`
	/// - Parameter scheme: `Scheme` to provide `Result` for `Item`s needed
	func resolve(from scheme: Scheme) -> Result?
}
