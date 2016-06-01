#
#  Be sure to run `pod spec lint HCCoren.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "HCMVManager"
  s.version      = "0.7.8"
  s.summary      = "这是一个与视频录制与剪辑相关核心库。"
  s.description  = <<-DESC
这是一个特定的核心库。包含了常用录像、剪辑、合成、及视频滤镜相关的功能。
                   DESC

  s.homepage     = "https://github.com/halfking/HCMVManager"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "halfking" => "kimmy.huang@gmail.com" }
  # Or just: s.author    = ""
  # s.authors            = { "" => "" }
  # s.social_media_url   = "http://twitter.com/"

  # s.platform     = :ios
   s.platform     = :ios, "7.0"

#  When using multiple platforms
s.ios.deployment_target = "7.0"
# s.osx.deployment_target = "10.7"
# s.watchos.deployment_target = "2.0"
# s.tvos.deployment_target = "9.0"

s.source       = { :git => "https://github.com/halfking/HCMVManager", :tag => s.version}

s.source_files  = "HCMVManager/**/*.{h,m,mm,c,cpp}"
#  s.exclude_files = "hccoren/Exclude"
s.public_header_files = "HCMVManager/**/*.h"

# s.resource  = "icon.png"
# s.resources = "Resources/*.png"
# s.preserve_paths = "FilesToSave", "MoreFilesToSave"
#s.frameworks = "UIKit", "Foundation"

s.libraries = "icucore","stdc++"
s.xcconfig = { "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES","ENABLE_BITCODE" => "YES","DEFINES_MODULE" => "YES" }
#s.pod_target_xcconfig = { 'LIBRARY_SEARCH_PATHS' => "$(inherited) " }
# s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

s.dependency "HCMinizip"
s.dependency "hccoren"
s.dependency "HCBaseSystem"
s.dependency "GPUImage"

#s.subspec 'lame' do |spec|
#    spec.source_files = ['Lib/*.h']
#    spec.public_header_files = ['Lib/*.h']
#    spec.preserve_paths = 'Lib/*.h'
#    spec.vendored_libraries = 'Lib/libmp3lame.a', 'Lib/libopencore-amrnb.a','Lib/libopencore-amrwb.a'
#    spec.libraries = 'mp3lame', 'opencore-amrnb','opencore-amrwb'
#    spec.xcconfig = { 'HEADER_SEARCH_PATHS' => "$(inherited) ${PODS_ROOT}/#{s.name}/Lib/**" }
#
#end

end
