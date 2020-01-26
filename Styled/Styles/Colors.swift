//
//  Colors.swift
//  Styled
//
//  Created by Farzad Sharbafian on 12/12/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import Foundation
import Styled

/// - Note: How to define Color variables to make sense throughout all different
/// `ColorScheme`s is a time consuming task and highly dependant on the product
/// your application will resemble. But for simplicity, we'll follow the same
/// naming convention `UIKit` used for defining color variables
extension Color {

	/// Primary color of the brand or application
	/// Mostly the color that is used essentially inside the application
	/// and is likely tied to tintColor
	static let accent: Self = "accent"

	// MARK: Labels

	/// Color suitable for first-level labels
	static let label: Self = "label"

	/// Color suitable for second-level labels (i.e subtitle/description)
	static let secondaryLabel: Self = "label.secondary"

	// MARK: Backgrounds
	/// Color suitable for first-level backgrounds inside the app
	/// - Note: It would be a good idea to define `tableViewBackground` for background
	/// color of `UITableView`s
	static let background: Self = "background"

	/// Default gray color used inside the application
	static let gray: Self = "gray"

	/// - Note: Color's nature is slightly lighter than `gray` in `Color.LightScheme`
	/// - Note: Color's nature is slightly darker than `gray` in `Color.DarkScheme`
	static let gray2: Self = "gray.level2"

	static let red: Self = "red"

	static let green: Self = "green"

	static let blue: Self = "blue"

	static let gold: Self = "gold"
}
