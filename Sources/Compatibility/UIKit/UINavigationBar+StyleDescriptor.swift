//
//  UINavigationBar+StyleDescriptor.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation
import class UIKit.UINavigationBar

extension StyleDescriptor where Base: UINavigationBar {
	
	/// Wrapper for `setBackgroundImage(_:for:barMetrics:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter position: `UIBarPosition`
	/// - Parameter barMetrics: `UIBarMetrics`
	public func setBackgroundImage(_ image: Image?, for position: UIBarPosition, barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackgroundImage(.styled(img), for: position, barMetrics: barMetrics) } }
		)
	}
	
	/// Wrapper for `setBackgroundImage(_:for:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter barMetrics: `UIBarMetrics`
	public func setBackgroundImage(_ image: Image?, for barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackgroundImage(.styled(img), for: barMetrics) } }
		)
	}
}
