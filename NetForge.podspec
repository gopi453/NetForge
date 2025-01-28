Pod::Spec.new do |s|
s.name             = 'NetForge'
s.version          = '0.0.1'
s.summary          = 'Performs Networking written in swift'
s.description      = <<-DESC
Performs Networking written in swift to ease development
DESC

s.homepage         = 'https://github.com/gopi453/NetForge'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'username' => 'gopi19453@gmail.com' }
s.source           = { :git => 'https://github.com/gopi453/NetForge.git', :tag => s.version.to_s }
s.ios.deployment_target = '12.0'
s.source_files = 'src/**/*.swift'
end
