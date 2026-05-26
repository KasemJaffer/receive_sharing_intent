#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint receive_sharing_intent.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'receive_sharing_intent'
  s.version          = '1.8.1'
  s.summary          = 'A flutter plugin that enables flutter apps to receive sharing photos, text or url from other apps.'
  s.description      = <<-DESC
A flutter plugin that enables flutter apps to receive sharing photos, text or url from other apps.
                       DESC
  s.homepage         = 'https://kasem.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kasem' => 'kasem.jaffer@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'receive_sharing_intent/Sources/receive_sharing_intent/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'receive_sharing_intent_privacy' => ['receive_sharing_intent/Sources/receive_sharing_intent/PrivacyInfo.xcprivacy']}
end
