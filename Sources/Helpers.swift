//
//  Misc.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/30/19.
//

import Foundation

extension Optional {
	
	/// Will write to `KeyPath` if self is `some`
	/// - Parameter keyPath:`ReferenceWritableKeyPath`
	/// - Parameter root: Root object to write to
	@inlinable func write<Root>(to keyPath: ReferenceWritableKeyPath<Root, Wrapped>, on root: Root) where Root: AnyObject {
		guard let value = self else { return }
		root[keyPath: keyPath] = value
	}
}

extension Hashable {
	
	/// Combines `self` with `other` using `Hasher` and returns finalized `hashValue`
	/// - Parameter other: `Hashable` instance
	/// - Returns: `hashValue` of `self` combined with `other`
	@inlinable func hashValueCombined<T>(with other: T) -> Int where T: Hashable {
		var hasher = Hasher()
		self.hash(into: &hasher)
		other.hash(into: &hasher)
		return hasher.finalize()
	}
}
