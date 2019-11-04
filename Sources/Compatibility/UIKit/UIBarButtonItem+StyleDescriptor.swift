//
//  UIBarButtonItem+StyleDescriptor.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation
import class UIKit.UIBarButtonItem

extension StyleDescriptor where Base: UIBarButtonItem {
	
	/// Wrapper for `setBackgroundImage(_:for:style:barMetrics:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	/// - Parameter style: `UIBarButtonItem.Style`
	/// - Parameter barMetrics: `UIBarMetrics`
	func setBackgroundImage(_ image: Image?, for state: UIControl.State, style: UIBarButtonItem.Style, barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackgroundImage(.styled(img), for: state, style: style, barMetrics: barMetrics) } }
		)
	}
	
	/// Wrapper for `setBackgroundImage(_:for:barMetrics:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	/// - Parameter barMetrics: `UIBarMetrics`
	func setBackgroundImage(_ image: Image?, for state: UIControl.State, barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackgroundImage(.styled(img), for: state, barMetrics: barMetrics) } }
		)
	}
	
	/// Wrapper for `setBackButtonBackgroundImage(_:for:barMetrics:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	/// - Parameter barMetrics: `UIBarMetrics`
	func setBackButtonBackgroundImage(_ image: Image?, for state: UIControl.State, barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackButtonBackgroundImage(.styled(img), for: state, barMetrics: barMetrics) } }
		)
	}
}
