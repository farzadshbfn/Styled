//
//  Misc.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/30/19.
//

import Foundation

extension Optional {
	
	/// Mutates self to the given value if and only if `self` is `nil`
	/// - Parameter value: WrappedType
	@inlinable mutating func coalesce(with value: @autoclosure () -> Wrapped) {
		switch self {
		case .none: self = .some(value())
		default: break
		}
	}
	
	/// Will call the closure if `self` is not `nil`
	/// - Parameter action: (`Wrapped`) -> ()
	@inlinable func `do`(_ action: (Wrapped) -> ()) {
		guard let value = self else { return }
		action(value)
	}
	
	/// Will write to `KeyPath` if self is `some`
	/// - Parameter keyPath:`ReferenceWritableKeyPath`
	/// - Parameter root: Root object to write to
	@inlinable func write<Root>(to keyPath: ReferenceWritableKeyPath<Root, Wrapped>, on root: Root) where Root: AnyObject {
		guard let value = self else { return }
		root[keyPath: keyPath] = value
	}
}
