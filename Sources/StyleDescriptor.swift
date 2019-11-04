//
//  StyleDescriptor.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

/// Contains and `Base` object and allows `UIColor`/`UIFont`/`UIImage` and `String` setting based on `currentScheme`s set in `Styled`
@dynamicMemberLookup public struct StyleDescriptor<Base: AnyObject> {
	
	/// Base object to extend.
	public let base: Base
	
	/// Creates extensions with base object for `UIColor`/`UIFont`/`UIImage` and `String` setting
	///
	/// - Parameter base: Base object
	init(base: Base) { self.base = base }
}

/// A type that enables any object to be Stylable
public protocol StyledCompatible: AnyObject {
	associatedtype StyledBase: AnyObject
	
	/// Use this variable to set  `Color`s, `Font`s, `Image`s  and `LocalizedString`
	var sd: StyleDescriptor<StyledBase> { get }
}

extension StyledCompatible {
	
	public var sd: StyleDescriptor<Self> {
		get { .init(base: self) }
		set { /* Enables dynamicStyle mutations */ }
	}
}

extension NSObject: StyledCompatible { }
