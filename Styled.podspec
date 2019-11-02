#
# Be sure to run `pod lib lint Styled.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Styled'
  s.module_name      = 'Styled'
  s.version          = '0.4.0'
  s.summary          = 'Elegant Style(Color,Font,Image,...) management in Swift'
  s.homepage         = 'https://github.com/farzadshbfn/Styled'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'FarzadShbfn' => 'farzad.shbfn@gmail.com' }
  s.source           = { :git => 'https://github.com/farzadshbfn/Styled.git', :tag => s.version.to_s }
  s.source_files 	 = 'Sources/**/*.{swift}'
  s.platforms        = { :ios => '10.0' }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.frameworks = 'UIKit'
end
