//
//  StyledImageTests.swift
//  StyledTests
//
//  Created by Farzad Sharbafian on 10/23/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import XCTest
@testable import Styled
import Nimble

extension StyledImage {
	fileprivate static let profile: Self = "profile"
	fileprivate static let profileFill: Self = "profile.fill"
	fileprivate static let profileMulti: Self = "profile.multi"
}

class StyledImageTests: XCTestCase {
	
	struct TestScheme: StyledImageScheme {
		func image(for styledImage: StyledImage) -> UIImage? {
			switch styledImage {
			case .profileMulti: return #imageLiteral(resourceName: "profile.multi")
			case .profileFill: return #imageLiteral(resourceName: "profile.fill")
			case .profile: return #imageLiteral(resourceName: "profile")
			default: return nil
			}
		}
	}

    override func setUp() {
		StyledImage.isPrefixMatchingEnabled = true
	}

    override func tearDown() {
		Styled.defaultImageScheme = nil
	}
	
	func testName() {
		expect(StyledImage.profile.name) == "profile"
		expect(StyledImage.profile.renderingMode(.automatic).name).to(beNil())
	}
	
	func testPatternMatcherSetting() {
		StyledImage.isPrefixMatchingEnabled = false
		
		expect(.profile ~= .profileFill) == false
		expect(.profileFill ~= .profile) == false
		expect(.profileMulti ~= .profileFill) == false
		expect(.profileFill ~= .profileMulti) == false
		
		expect(.profile ~= .profile) == true
		expect(.profileFill ~= .profileFill) == true
		expect(.profileMulti ~= .profileMulti) == true
	}
	
	func testPatternMatcher() {
		expect(.profile ~= .profileFill) == true
		expect(.profileFill ~= .profile) == false
		expect(.profile ~= .profileMulti) == true
		expect(.profileMulti ~= .profile) == false
		
		expect(.profileFill ~= .profileMulti) == false
		expect(.profileMulti ~= .profileFill) == false
		
		expect(.profile ~= .profile) == true
		expect(.profileFill ~= .profileFill) == true
		expect(.profileMulti ~= .profileMulti) == true
		
		switch StyledImage.profileMulti {
		case .profile: break
		default: fail("profile case should be matched")
		}
		
		switch StyledImage.profile {
		case .profileFill, .profileMulti: fail("non of these cases should be matched")
		default: break
		}
	}
	
	func testLazy() {
		Styled.defaultImageScheme = TestScheme()
		
		let lazy1 = StyledImage.Lazy(.profile)
		let lazy2 = StyledImage.Lazy(.profile)
		let lazy3 = StyledImage.Lazy(.profileFill)

		expect(lazy1) == lazy2
		expect(lazy1) != lazy3
		expect(lazy2) != lazy3
		
		expect(UIImage.styled(.init(lazy: lazy1))) == UIImage(named: "profile")
	}
	
	func testDescriptions() {
		expect(StyledImage.profile.description) == "profile"
		expect("\(StyledImage.profile)") == "profile"
		
		expect(StyledImage.renderingMode(.alwaysTemplate, of: .profileMulti).description) == "{profile.multi(alwaysTemplate)}"
		expect(StyledImage.renderingMode(.alwaysOriginal, of: .profileMulti).description) == "{profile.multi(alwaysOriginal)}"
		expect(StyledImage.renderingMode(.automatic, of: .profileMulti).description) == "{profile.multi(automatic)}"
		expect(StyledImage.profileFill.transform { $0 }.description) == "{profile.fill->t}"
		expect(StyledImage.profile.transform(named: "custom") { $0 }.description) == "{profile->custom}"
		
		expect(StyledImage("bundled", bundle: .main).description) == "{bundled(com.farzadshbfn.styled)}"
		expect(StyledImage("bundled", bundle: .init()).description) == "{bundled(bundle.not.found)}"
	}
	
	func testLoad() {
		Styled.defaultImageScheme = TestScheme()
		
		expect(UIImage.styled(.profile)) == UIImage(named: "profile")
		expect(UIImage.styled(.profileFill)) == UIImage(named: "profile.fill")
		expect(UIImage.styled(.profileMulti)) == UIImage(named: "profile.multi")
		expect(UIImage.styled(.profile)) != UIImage(named: "profile.multi")
		expect(UIImage.styled("unkown")).to(beNil())
	}
	
	func testRenderingMode() {
		Styled.defaultImageScheme = TestScheme()
		
		expect(UIImage.styled(.renderingMode(.alwaysTemplate, of: .profile))) != UIImage(named: "profile")
		expect(UIImage.styled(.renderingMode(.alwaysTemplate, of: .profile))) == UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
		
		expect(UIImage.styled(.renderingMode(.alwaysOriginal, of: .profile))) != UIImage(named: "profile")
		expect(UIImage.styled(.renderingMode(.alwaysOriginal, of: .profile))) == UIImage(named: "profile")?.withRenderingMode(.alwaysOriginal)
		
		expect(UIImage.styled(.renderingMode(.alwaysOriginal, of: .profile))) != UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
		
		expect(StyledImage.renderingMode(.alwaysOriginal, of: .profile)) == StyledImage.profile.renderingMode(.alwaysOriginal)
		
		expect(UIImage.styled(StyledImage("notDefined").renderingMode(.alwaysTemplate))).to(beNil())
	}
	
	
	func testTransform() {
		Styled.defaultImageScheme = TestScheme()
		
		expect(UIImage.styled(StyledImage.profile.transform(named: "renderMode", { $0.withRenderingMode(.alwaysTemplate) }))) == UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
		
		expect(StyledImage.renderingMode(.alwaysOriginal, of: .profile)) == StyledImage.profile.renderingMode(.alwaysOriginal)
		
		expect(UIImage.styled(.transforming("notDefined") { $0 } )).to(beNil())
	}
	
	func testAssetsCatalog() {
		Styled.defaultImageScheme = UIImage.StyledAssetCatalog()
		StyledImage.isPrefixMatchingEnabled = false
		
		expect(UIImage.styled(.profile)) == #imageLiteral(resourceName: "profile")
		expect(UIImage.styled(.profileFill)) == #imageLiteral(resourceName: "profile.fill")
		expect(UIImage.styled(.profileMulti)) == #imageLiteral(resourceName: "profile.multi")
		expect(UIImage.styled("profile.multi.fill")) == #imageLiteral(resourceName: "profile.multi")

		// test Bundle load
		let image = StyledImage("sampleModule.profile.multi.fill", bundle: Bundle(identifier: "com.farzadshbfn.SampleModule")!)
		
		expect(UIImage.styled(image)) == UIImage(named: "sampleModule.profile.multi.fill", in: Bundle(identifier: "com.farzadshbfn.SampleModule"), with: nil)
	}
}
