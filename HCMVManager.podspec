#
#  Be sure to run `pod spec lint HCCoren.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "HCMVManager"
  s.version      = "1.6.3"
  s.summary      = "这是一个与视频录制与剪辑相关核心库。"
  s.description  = <<-DESC
这是一个特定的核心库。包含了常用录像、剪辑、合成、及视频滤镜相关的功能。
1.5.3   反向视频生成后，被切割时，起止时间可能导致的错误。另外，增加了反向视频生成失败，重试2次的规则。2次失败则抛弃。
1.5.4   解决生成反向视频中，合成音频时，音频文件不存在的情况下，导致的合成失败，多次调用Block的Bug
1.5.5   将VideoGenerate中的Delegate改成Optional
1.5.6   将默认的角度为0的视频，自动转成标准的有方向的视频。角度为0时，则根据高宽来判断是否为横屏。解决从微信下载的视频方向错误的问题。
1.5.8   修改ActionProgress的默认文字显示
1.5.9   修正 视频方向确认代码的BUG，不需要检查是否录像目录，并且修正CompositeOneitem判断中的一个BUG
1.6.0   修正 视频合成出错时，进度不往前，卡死的问题。修正视频取截图失败时，不再取其它图的BUG
1.6.1   发现GPUImage在处理视频时，如果视频中没有音频轨，将导致Crash。因此在处理之前，将检查是否有音频轨。
1.6.2   所有合成的视频中均加入音频轨，防止没有音频轨的问题出现
1.6.3   在ActionManager与MediaEditManager增加上述的控制变量
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

s.resource  = "HCMVManager.bundle"
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
