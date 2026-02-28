Pod::Spec.new do |s|
  s.name             = 'WaktuSolatSwift'
  s.version          = '1.0.0'
  s.summary          = 'Malaysia prayer time library for iOS and macOS in Swift.'
  s.description      = <<-DESC
WaktuSolatSwift provides a simple client to fetch Malaysia prayer times
from api.waktusolat.app, including zone/state lookups and convenience date methods.
  DESC
  s.homepage         = 'https://github.com/apkdmg/waktu_solat_swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'apkdmg' => 'apkdmg@users.noreply.github.com' }
  s.source           = {
    :git => 'https://github.com/apkdmg/waktu_solat_swift.git',
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/WaktuSolatSwift/**/*.swift'
  s.frameworks = 'Foundation'
  s.static_framework = true
end
