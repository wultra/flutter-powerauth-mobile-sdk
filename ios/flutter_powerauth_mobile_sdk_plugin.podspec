Pod::Spec.new do |s|
  s.name             = 'flutter_powerauth_mobile_sdk_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Flutter Mobile SDK for PowerAuth Protocol (iOS).'
  s.homepage         = 'https://www.wultra.com/products/mobile-first-authentication'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Wultra s.r.o.' => 'support@wultra.com' }

  s.source           = { :git => "https://github.com/wultra/flutter-powerauth-mobile-sdk" }

  s.source_files = 'Classes/**/*'
  s.platform = :ios, '13.4'

  s.dependency 'Flutter'
  s.dependency "PowerAuth2", "~> 1.9.5"

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
