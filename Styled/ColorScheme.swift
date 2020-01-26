//
//  ColorScheme.swift
//  Styled
//
//  Created by Farzad Sharbafian on 12/12/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import Foundation
import Styled

extension Color {
	struct LightScheme: ColorScheme {
		func color(for color: Color) -> UIColor? {
			switch color {
				// primary accent color of the application (used purple as example, it highly
				// depends on your application/product that what your brand color is)
			case .accent: return #colorLiteral(red: 0.5748988115, green: 0.3643724779, blue: 1, alpha: 1)
				// label
			case .secondaryLabel: return #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
			case .label: return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

			case .background: return #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

				// gray
			case .gray2: return #colorLiteral(red: 0.3726607263, green: 0.3723509312, blue: 0.3854131103, alpha: 1)
			case .gray: return #colorLiteral(red: 0.5531356931, green: 0.5526055694, blue: 0.5743864179, alpha: 1)

				// generic colors
			case .red: return #colorLiteral(red: 1, green: 0.1968034384, blue: 0.3571232451, alpha: 1)
			case .green: return #colorLiteral(red: 0.341796224, green: 0.7910955914, blue: 0.3644399204, alpha: 1)
			case .blue: return #colorLiteral(red: 0, green: 0.4510218243, blue: 1, alpha: 1)
			case .gold: return #colorLiteral(red: 1, green: 0.7618049603, blue: 0.01506529563, alpha: 1)

			default:
				#if DEBUG
					fatalError("Unknown Color detected. \(color)")
				#else
					return nil
				#endif
			}
		}
	}

	struct DarkScheme: ColorScheme {
		func color(for color: Color) -> UIColor? {
			switch color {
				// primary accent color of the application (used purple as example, it highly
				// depends on your application/product that what your brand color is)
			case .accent: return #colorLiteral(red: 0.5154122382, green: 0.3266697211, blue: 0.8965268807, alpha: 1)
				// label
			case .secondaryLabel: return #colorLiteral(red: 0.8039215686, green: 0.8039215686, blue: 0.8039215686, alpha: 1)
			case .label: return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

			case .background: return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

				// gray
			case .gray2: return #colorLiteral(red: 0.2784313725, green: 0.2784313725, blue: 0.2784313725, alpha: 1)
			case .gray: return #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

				// generic colors

			case .red: return #colorLiteral(red: 0.9406978627, green: 0.1741740187, blue: 0.324954806, alpha: 1)
			case .green: return #colorLiteral(red: 0.2121840551, green: 0.6495800474, blue: 0.2485897278, alpha: 1)
			case .blue: return #colorLiteral(red: 0, green: 0.3691984414, blue: 0.8185822094, alpha: 1)
			case .gold: return #colorLiteral(red: 0.9513531983, green: 0.7247455855, blue: 0.01433241718, alpha: 1)

			default:
				#if DEBUG
					fatalError("Unknown Color detected. \(color)")
				#else
					return nil
				#endif
			}
		}
	}
}
