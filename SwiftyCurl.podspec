#
# Be sure to run `pod lib lint SwiftyCurl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyCurl'
  s.version          = '0.4.5'
  s.summary          = 'A Swift and Objective-C wrapper for libcurl.'

  s.description      = <<-DESC
SwiftyCurl is an easily usable Swift and Objective-C wrapper for libcurl.
                       DESC

  s.homepage         = 'https://github.com/greatfire/SwiftyCurl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
  s.source           = { :git => 'https://github.com/greatfire/SwiftyCurl.git', :tag => s.version.to_s }
  s.social_media_url = 'https://chaos.social/@tla'

  s.ios.deployment_target = '12.0'
  s.macos.deployment_target = '12.0'

  s.source_files = 'Sources/SwiftyCurl/**/*'
  s.private_header_files = 'Sources/SwiftyCurl/Private/**/*.h'

  s.vendored_frameworks = 'curl.xcframework'

  s.resource_bundles = {
      'certs' => ['curl.xcframework/ios-arm64/curl.framework/Resources/cacert.pem']
  }

  s.libraries = 'z'
  s.macos.libraries = 'ldap'
  s.macos.frameworks = 'SystemConfiguration'

  s.prepare_command = 'Sources/download-curl.sh 8.15.0 2353b5ae767c896fdef1c3e0bf23f3df429fc266809af7f443ae5a1003cea42a'
  s.preserve_path = 'Sources/download-curl.sh'
end
