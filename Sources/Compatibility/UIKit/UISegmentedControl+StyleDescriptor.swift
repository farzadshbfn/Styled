//
//  UISegmentedControl+StyleDescriptor.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation
import class UIKit.UISegmentedControl

extension StyleDescriptor where Base: UISegmentedControl {
	
	/// Wrapper for `setImage(_:forSegmentAt:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchroniziation
	/// - Parameter index: `Int`
	func setImage(_ image: Image?, forSegmentAt index: Int) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setImage(.styled(img), forSegmentAt: index) } }
		)
	}
	
	/// Wrapper for `setBackgroundImage(_:for:barMetrics:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchroniziation
	/// - Parameter state: `UIControl.State`
	/// - Parameter barMetrics: `UIBarMetrics`
	func setBackgroundImage(_ image: Image?, for state: UIControl.State, barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackgroundImage(.styled(img), for: state, barMetrics: barMetrics) } }
		)
	}
	
	// TODO: Implement `setTitle` when `LocalizedString` is implemented
}
