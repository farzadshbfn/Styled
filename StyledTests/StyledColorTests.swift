//
//  StyledColorTests.swift
//  StyledTests
//
//  Created by Farzad Sharbafian on 10/17/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import XCTest
@testable import Styled
import Nimble

extension StyledColor {
	fileprivate static let primary: Self = "primary"
	fileprivate static let primary1: Self = "primary.lvl1"
	fileprivate static let primary2: Self = "primary.lvl2"
	
}

class StyledColorTests: XCTestCase {
	
	struct TestScheme: StyledColorScheme {
		func color(for styledColor: StyledColor) -> UIColor? {
			switch styledColor {
			case .primary1: return .green
			case .primary2: return .blue
			case .primary: return .red
			default: return nil
			}
		}
	}
	
	override func setUp() {
		StyledColor.isPrefixMatchingEnabled = true
	}
	
	override func tearDown() {
		Styled.defaultColorScheme = nil
	}
	
	func testName() {
		expect(StyledColor.primary.name) == "primary"
		expect(StyledColor.primary.opacity(1.00).name).to(beNil())
	}
	
	func testPatternMatcherSetting() {
		StyledColor.isPrefixMatchingEnabled = false
		
		expect(.primary ~= .primary2) == false
		expect(.primary2 ~= .primary) == false
		expect(.primary1 ~= .primary2) == false
		expect(.primary2 ~= .primary1) == false
		
		expect(.primary ~= .primary) == true
		expect(.primary1 ~= .primary1) == true
		expect(.primary2 ~= .primary2) == true
	}
	
	func testPatternMatcher() {
		expect(.primary ~= .primary2) == true
		expect(.primary2 ~= .primary) == false
		expect(.primary1 ~= .primary2) == false
		expect(.primary2 ~= .primary1) == false
		
		expect(.primary ~= .primary) == true
		expect(.primary1 ~= .primary1) == true
		expect(.primary2 ~= .primary2) == true
		
		switch StyledColor.primary2 {
		case .primary: break
		default: fail("primary case should be matched")
		}
		
		switch StyledColor.primary {
		case .primary1, .primary2: fail("non of these cases should be matched")
		default: break
		}
	}
	
	func testLazy() {
		let lazy1 = StyledColor.Lazy(.primary)
		let lazy2 = StyledColor.Lazy(.primary)
		let lazy3 = StyledColor.Lazy(.primary1)
		
		expect(lazy1) == lazy2
		expect(lazy1) != lazy3
		expect(lazy2) != lazy3
	}
	
	func testDescriptions() {
		expect(StyledColor.primary.description) == "primary"
		expect("\(StyledColor.primary)") == "primary"
		
		expect(StyledColor.blending(.primary, 0.3, with: .primary2).description) == "{primary*0.30+primary.lvl2*0.70}"
		expect(StyledColor.blending(.primary, 0.3, with: UIColor.black).description) == "{primary*0.30+UIColor(0.00 0.00 0.00 1.00)*0.70}"
		expect(StyledColor.opacity(0.4, of: .primary).description) == "{primary(0.40)}"
		expect(StyledColor.transforming(.primary) { $0 }.description) == "{primary->t}"
		expect(StyledColor.transforming(.primary, named: "custom") { $0 }.description) == "{primary->custom}"
		
		if #available(iOS 11, *) {
			expect(StyledColor("bundled", bundle: .main).description) == "{bundled(com.farzadshbfn.styled)}"
			
			expect(StyledColor("bundled", bundle: .init()).description) == "{bundled(bundle.not.found)}"
		}
	}
	
	func testLoad() {
		Styled.defaultColorScheme = TestScheme()
		
		expect(UIColor.styled(.primary)) == .red
		expect(UIColor.styled(.primary1)) == .green
		expect(UIColor.styled(.primary2)) == .blue
		expect(UIColor.styled(.primary)) != .blue
		expect(UIColor.styled("unknown")).to(beNil())
	}
	
	func testBlending() {
		Styled.defaultColorScheme = TestScheme()
		
		expect(UIColor.styled(.blending(.primary, with: .primary1))) == .init(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)
		expect(UIColor.styled(StyledColor.primary.blend(0.1, with: UIColor.black))) == .init(red: 0.1, green: 0.0, blue: 0.0, alpha: 1.0)
		
		expect(UIColor.styled(.blending("notDefined", with: .black))) == .black
		expect(UIColor.styled(.blending(.blending("notDefined", with: .black), with: "notDefiend"))) == .black
	}
	
	func testOpacity() {
		Styled.defaultColorScheme = TestScheme()
		
		expect(UIColor.styled(.opacity(0.25, of: .primary2))) == .init(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.25)
		expect(UIColor.styled(.primary)?.withAlphaComponent(0.5)) == .styled(StyledColor.primary.opacity(0.5))
		
		expect(UIColor.styled(.opacity(0.5, of: "notDefined"))).to(beNil())
	}
	
	func testTransform() {
		Styled.defaultColorScheme = TestScheme()
		
		expect(UIColor.styled(StyledColor.primary.transform(named: "blend") { $0.blend(with: .black) })) == .init(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
		
		expect(StyledColor.primary.transform { $0 }) == .transforming(.primary) { $0 }
		expect(StyledColor.primary.transform(named: "c") { $0 }) == .transforming(.primary, named: "c") { $0 }
		expect(StyledColor.primary.transform { $0 }) != .transforming(.primary, named: "c") { $0 }
		
		expect(UIColor.styled(.transforming("notDefined") { $0 })).to(beNil())
	}
	
	func testAssetsCatalog() {
		if #available(iOS 11, *) {
			Styled.defaultColorScheme = UIColor.StyledAssetCatalog()
			
			expect(UIColor.styled("red.primary")) == .red
			// lvl1 does not exist. should match to `red.primary`
			expect(UIColor.styled("red.primary.lvl1")) == .red
			// blue does not exist at all
			expect(UIColor.styled("blue.primary.lvl1")).to(beNil())
			
			StyledColor.isPrefixMatchingEnabled = false
			// lvl1 does not exist. should NOT match to `red.primary`
			expect(UIColor.styled("red.primary.lvl1")).to(beNil())
			
			// test Bundle load
			let color = StyledColor("sampleModule.blue.primary", bundle: Bundle(identifier: "com.farzadshbfn.SampleModule")!)
			expect(UIColor.styled(color)) == .blue
		}
	}
}
