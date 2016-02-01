Pod::Spec.new do |s|
  s.name             = "PRGalleryView"
  s.summary          = "UIView subclass which supports Image, GIF, and Video playback."
  s.version          = "0.1.0"

  s.homepage         = "https://github.com/praxent/PRGalleryView"
  s.license          = "MIT"
  s.author           = { "Albert Martin" => "albert@bethel.io" }
  s.source           = { :git => "https://github.com/praxent/PRGalleryView.git", :tag => s.version.to_s }

  s.platform     = :ios, "9.0"
  s.requires_arc = true

  s.frameworks = "UIKit"

  s.source_files = "*.{swift}"

  s.dependency 'FLAnimatedImage', '~> 1.0.10'
end
