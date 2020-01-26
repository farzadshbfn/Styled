//
//  Fonts.swift
//  Styled
//
//  Created by Farzad Sharbafian on 1/4/20.
//  Copyright © 2020 FarzadShbfn. All rights reserved.
//

import Foundation
import Styled

/// - Note: Different configurations in big products, mostly come from
/// Design teams, It's good to share ideologies for consistency throughout
/// your product
extension Font {
	
	/// The font for All the headlines used inside the application (Top level)
	/// - Note: Due to consistency, it's good to use same **font** for contents that
	/// share something with each-other. (headline, body, footnote)...
	static let headline: Self = .init(size: .dynamic(.headline), weight: .bold)
	
	/// The font for All the bodies used inside the application (Second level)
	/// - Note: Unlike **headline** we might use different weights for different body
	/// contents to emphasise on something.
	static func body(weight: Weight = .regular) -> Font {
		.init(size: .dynamic(.body), weight: weight)
	}
	
	
	static let button: Self = .init(size: .dynamic(.caption1), weight: .black)
}
