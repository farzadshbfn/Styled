//
//  UIButton+StyleDescriptor.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation
import class UIKit.UIButton

extension StyleDescriptor where Base: UIButton {
	
	/// Wrapper for `setImage(_:for:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchroniziation
	/// - Parameter state: `UIControl.State`
	func setImage(_ image: Image?, for state: UIControl.State) {
		onImageSchemeUpdate(withId: #function, do: image.map { img in { $0.setImage(.styled(img), for: state) } } )
	}
	
	/// Wrapper for `setBackgroundImage(_:for:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchroniziation
	/// - Parameter state: `UIControl.State`
	func setBackgroundImage(_ image: Image?, for state: UIControl.State) {
		onImageSchemeUpdate(withId: #function, do: image.map { img in { $0.setBackgroundImage(.styled(img), for: state) } } )
	}
	
	/// Wrapper for `setTitleColor(_:for:)`
	/// - Parameter color: `Color` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	func setTitleColor(_ color: Color?, for state: UIControl.State) {
		onColorSchemeUpdate(withId: #function, do: color.map { clr in { $0.setTitleColor(.styled(clr), for: state) } } )
	}
	
	/// Wrapper for `setTitleShadowColor(_:for:)`
	/// - Parameter color: `Color` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	func setTitleShadowColor(_ color: Color?, for state: UIControl.State) {
		onColorSchemeUpdate(withId: #function, do: color.map { clr in { $0.setTitleShadowColor(.styled(clr), for: state) } } )
	}
	
	// TODO: Implement `setTitle`, `setAttributedTitle` when `LocalizedString` is implemented
}
