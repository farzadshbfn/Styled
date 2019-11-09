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
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	public func setImage(_ image: Image?, for state: UIControl.State) {
		onImageSchemeUpdate(withId: #function, do: image.map { img in { $0.setImage(.styled(img), for: state) } } )
	}
	
	/// Wrapper for `setBackgroundImage(_:for:)`
	/// - Parameter image: `Image` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	public func setBackgroundImage(_ image: Image?, for state: UIControl.State) {
		onImageSchemeUpdate(withId: #function, do: image.map { img in { $0.setBackgroundImage(.styled(img), for: state) } } )
	}
	
	/// Wrapper for `setTitleColor(_:for:)`
	/// - Parameter color: `Color` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	public func setTitleColor(_ color: Color?, for state: UIControl.State) {
		onColorSchemeUpdate(withId: #function, do: color.map { clr in { $0.setTitleColor(.styled(clr), for: state) } } )
	}
	
	/// Wrapper for `setTitleShadowColor(_:for:)`
	/// - Parameter color: `Color` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	public func setTitleShadowColor(_ color: Color?, for state: UIControl.State) {
		onColorSchemeUpdate(withId: #function, do: color.map { clr in { $0.setTitleShadowColor(.styled(clr), for: state) } } )
	}
	
	/// Wrapper for `setTitle(_:for:)`
	/// - Parameter localizedString: `LocalizedString` to synchronize with. Passing `nil` will stop synchronization
	/// - Parameter state: `UIControl.State`
	public func setTitle(_ localizedString: LocalizedString?, for state: UIControl.State) {
		onLocalizedStringSchemeUpdate(
			withId: #function,
			do: localizedString.map { ls in { $0.setTitle(.styled(ls), for: state) } }
		)
	}
	
	// TODO: Implement `setAttributedTitle` when `AttributedString` is implemented
}
