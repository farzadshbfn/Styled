//
//  Lazy.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

/// This type is used to support transformations on `Item` like `.transform`
struct Lazy<Item>: Hashable, CustomStringConvertible where Item: Styled.Item {
	/// Is generated on `init` to keep the type Hashable and hide `Item` in order to let `Item` be calculated based on transformations
	let itemHashValue: Int
	
	/// Describes current item that will be returned
	let itemDescription: String
	
	/// Describes current item that will be returned
	var description: String { itemDescription }
	
	/// Provides `Item.Result` which can be backed by `Item` or static `Item.Result`
	let item: (_ scheme: Item.Scheme) -> Item.Result?
	
	/// Used internally to pre-calculate hashValue of Internal `item`
	static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
		var hasher = Hasher()
		hasher.combine(category)
		value.hash(into: &hasher)
		return hasher.finalize()
	}
	
	/// Will load `Item.Result` from `Item.Scheme` when needed
	init(_ item: Item) {
		itemHashValue = Self.hashed("Item", item)
		itemDescription = item.description
		self.item = item.resolve
	}
	
	/// Will use custom provider to provide `Item.Result` when needed
	/// - Parameter name: Will be used as `description` and inside hash-algorithms
	init(name: String, _ itemProvider: @escaping (_ scheme: Item.Scheme) -> Item.Result?) {
		itemHashValue = Self.hashed("ItemProvider", name)
		itemDescription = name
		item = itemProvider
	}
	
	/// - Returns: `hashValue` of given parameters when initializing `Lazy`
	func hash(into hasher: inout Hasher) { hasher.combine(itemHashValue) }
	
	/// Is backed by `hashValue` comparision
	static func == (lhs: Lazy, rhs: Lazy) -> Bool { lhs.hashValue == rhs.hashValue }
}
