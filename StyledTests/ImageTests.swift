//
//  ImageTests.swift
//  StyledTests
//
//  Created by Farzad Sharbafian on 10/23/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import XCTest
@testable import Styled
import Nimble

extension Image {
	fileprivate static let profile: Self = "profile"
	fileprivate static let profileFill: Self = "profile.fill"
	fileprivate static let profileMulti: Self = "profile.multi"
}

class ImageTests: XCTestCase {
	
	struct TestScheme: ImageScheme {
		func image(for image: Image) -> UIImage? {
			switch image {
			case .profileMulti: return #imageLiteral(resourceName: "profile.multi")
			case .profileFill: return #imageLiteral(resourceName: "profile.fill")
			case .profile: return #imageLiteral(resourceName: "profile")
			default: return nil
			}
		}
	}

    override func setUp() {
		Image.isPrefixMatchingEnabled = true
	}

    override func tearDown() {
		Config.imageScheme = nil
	}
	
	func testName() {
		expect(Image.profile.name) == "profile"
		expect(Image.profile.renderingMode(.automatic).name).to(beNil())
	}
	
	func testPatternMatcherSetting() {
		Image.isPrefixMatchingEnabled = false
		
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
		
		switch Image.profileMulti {
		case .profile: break
		default: fail("profile case should be matched")
		}
		
		switch Image.profile {
		case .profileFill, .profileMulti: fail("non of these cases should be matched")
		default: break
		}
	}
	
	func testLazy() {
		Config.imageScheme = TestScheme()
		
		let lazy1 = Image.Lazy(.profile)
		let lazy2 = Image.Lazy(.profile)
		let lazy3 = Image.Lazy(.profileFill)

		expect(lazy1) == lazy2
		expect(lazy1) != lazy3
		expect(lazy2) != lazy3
		
		expect(UIImage.styled(.init(lazy: lazy1))) == UIImage(named: "profile")
	}
	
	func testDescriptions() {
		expect(Image.profile.description) == "profile"
		expect("\(Image.profile)") == "profile"
		
		expect(Image.renderingMode(.alwaysTemplate, of: .profileMulti).description) == "{profile.multi(2)}"
		expect(Image.renderingMode(.alwaysOriginal, of: .profileMulti).description) == "{profile.multi(1)}"
		expect(Image.renderingMode(.automatic, of: .profileMulti).description) == "{profile.multi(0)}"
		expect(Image.profileFill.transform { $0 }.description) == "{profile.fill->t}"
		expect(Image.profile.transform(named: "custom") { $0 }.description) == "{profile->custom}"
		
		expect(Image("bundled", bundle: .main).description) == "{bundled(com.farzadshbfn.styled)}"
		expect(Image("bundled", bundle: .init()).description) == "{bundled(bundle.not.found)}"
	}
	
	func testLoad() {
		Config.imageScheme = TestScheme()
		
		expect(UIImage.styled(.profile)) == UIImage(named: "profile")
		expect(UIImage.styled(.profileFill)) == UIImage(named: "profile.fill")
		expect(UIImage.styled(.profileMulti)) == UIImage(named: "profile.multi")
		expect(UIImage.styled(.profile)) != UIImage(named: "profile.multi")
		expect(UIImage.styled("unkown")).to(beNil())
	}
	
	func testRenderingMode() {
		Config.imageScheme = TestScheme()
		
		expect(UIImage.styled(.renderingMode(.alwaysTemplate, of: .profile))) != UIImage(named: "profile")
		expect(UIImage.styled(.renderingMode(.alwaysTemplate, of: .profile))) == UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
		
		expect(UIImage.styled(.renderingMode(.alwaysOriginal, of: .profile))) != UIImage(named: "profile")
		expect(UIImage.styled(.renderingMode(.alwaysOriginal, of: .profile))) == UIImage(named: "profile")?.withRenderingMode(.alwaysOriginal)
		
		expect(UIImage.styled(.renderingMode(.alwaysOriginal, of: .profile))) != UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
		
		expect(Image.renderingMode(.alwaysOriginal, of: .profile)) == Image.profile.renderingMode(.alwaysOriginal)
		
		expect(UIImage.styled(Image("notDefined").renderingMode(.alwaysTemplate))).to(beNil())
	}
	
	
	func testTransform() {
		Config.imageScheme = TestScheme()
		
		expect(UIImage.styled(Image.profile.transform(named: "renderMode", { $0.withRenderingMode(.alwaysTemplate) }))) == UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
		
		expect(Image.renderingMode(.alwaysOriginal, of: .profile)) == Image.profile.renderingMode(.alwaysOriginal)
		
		expect(UIImage.styled(.transforming("notDefined") { $0 } )).to(beNil())
	}
	
	func testAssetsCatalog() {
		Config.imageScheme = DefaultImageScheme()
		Image.isPrefixMatchingEnabled = false
		
		expect(UIImage.styled(.profile)) == #imageLiteral(resourceName: "profile")
		expect(UIImage.styled(.profileFill)) == #imageLiteral(resourceName: "profile.fill")
		expect(UIImage.styled(.profileMulti)) == #imageLiteral(resourceName: "profile.multi")
		expect(UIImage.styled("profile.multi.fill")) == #imageLiteral(resourceName: "profile.multi")

		// test Bundle load
		let image = Image("sampleModule.profile.multi.fill", bundle: Bundle(identifier: "com.farzadshbfn.SampleModule")!)
		
		expect(UIImage.styled(image)) == UIImage(named: "sampleModule.profile.multi.fill", in: Bundle(identifier: "com.farzadshbfn.SampleModule"), with: nil)
	}
}
