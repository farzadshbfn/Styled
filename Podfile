source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!

target 'Styled' do
  pod 'Styled', :path => '.'
	
	target 'SampleModule' do
		inherit! :search_paths
	end
	
	target 'StyledTests' do
		inherit! :search_paths
		
		pod 'Nimble'
	end
end
