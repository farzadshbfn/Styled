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
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter index: `Int`
	public func setImage(_ image: Image?, forSegmentAt index: Int) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setImage(.styled(img), forSegmentAt: index) } }
		)
	}

	/// Wrapper for `setBackgroundImage(_:for:barMetrics:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	/// - Parameter barMetrics: `UIBarMetrics`
	public func setBackgroundImage(_ image: Image?, for state: UIControl.State, barMetrics: UIBarMetrics) {
		onImageSchemeUpdate(
			withId: #function,
			do: image.map { img in { $0.setBackgroundImage(.styled(img), for: state, barMetrics: barMetrics) } }
		)
	}

	/// Wrapper for `setTitle(_:forSegmentAt:)`
	/// - Parameter localizedString: `LocalizedString` to synchronize with. Passing `nil` will stop synchronizatoin
	/// - Parameter index: `Int`
	public func setTitle(_ localizedString: LocalizedString?, forSegmentAt index: Int) {
		onLocalizedStringSchemeUpdate(
			withId: #function,
			do: localizedString.map { ls in { $0.setTitle(.styled(ls), forSegmentAt: index) } }
		)
	}
}
