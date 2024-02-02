Pod::Spec.new do |s|
  s.name             = "CardStack"
  s.version          = "1.0.0"
  s.summary          = "SwiftUI CardStack Library"
  s.description      = "A SwiftUI view that arranges its children in a whimsical interactive deck of cards."
  s.homepage         = "https://github.com/notsobigcompany/CardStack"
  s.license          = "Public"
  s.author           = "notsobigcompany"
  s.source           = { :git => "https://github.com/barenddev/CardStack.git" }
  s.source_files     = 'Sources/CardStack/**/*.swift'

  s.platform     = :ios, '14.0'
  s.requires_arc = true
  s.swift_version = '5.0'
end
