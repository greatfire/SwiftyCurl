#
# Be sure to run `pod lib lint SwiftyCurl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyCurl'
  s.version          = '0.1.0'
  s.summary          = 'A Swift and Objective-C wrapper for libcurl.'

  s.description      = <<-DESC
SwiftyCurl is an easily usable Swift and Objective-C wrapper for libcurl.
                       DESC

  s.homepage         = 'https://github.com/greatfire/SwiftyCurl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
  s.source           = { :git => 'https://github.com/greatfire/SwiftyCurl.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tladesignz'

  s.ios.deployment_target = '12.0'
  s.macos.deployment_target = '12.0'

  s.source_files = 'SwiftyCurl/Classes/**/*'
  s.private_header_files = 'SwiftyCurl/Classes/SCProgress.h'

  s.vendored_frameworks = 'SwiftyCurl/curl.xcframework'

  s.libraries = 'z'
  s.macos.libraries = 'ldap'
  s.macos.frameworks = 'SystemConfiguration'

  s.prepare_command = 'SwiftyCurl/download-curl.sh'
  s.preserve_path = 'SwiftyCurl/download-curl.sh'
end
