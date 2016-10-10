Pod::Spec.new do |s|

  s.name         = "SGTNetworking"
  s.version      = "2.0.1-debug"
  s.summary      = "This is a private pod sp. provide Network function."

  s.description  = <<-DESC
  This is a private Podspec. Provide network function. Base on AFNetworking and ReactiveCocoa
                   DESC

  s.homepage     = "https://github.com/blockdate/SGTNetFramework"

  s.license      = { :type => "MIT", :file => "LICENSE" }



  s.author             = { "吴磊" => "w.leo.sagittarius@gmail.com" }

  s.platform     = :ios, "8.0"



  s.source       = { :git => "https://github.com/blockdate/SGTNetFramework.git", :tag => s.version.to_s }



  s.source_files  = "Source", "Source/**/*.{h,m}"

  s.public_header_files = "Source/SGTNetManager.h", "Source/SGTNetConfig.h", "Source/RACAFNetworking/**/*.h"


  s.frameworks = "Foundation", "UIKit"



  s.requires_arc = true

  s.dependency 'ReactiveObjC'
  s.dependency 'AFNetworking'
end
