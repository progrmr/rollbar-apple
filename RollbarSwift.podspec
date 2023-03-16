Pod::Spec.new do |s|
    s.version      = "3.0.0"
    s.name         = "RollbarSwift"
    s.summary      = "Application or client side SDK for interacting with the Rollbar API Server."
    s.description  = <<-DESC
                      Find, fix, and resolve errors with Rollbar.
                      Easily send error data using Rollbar API.
                      Analyze, de-dupe, send alerts, and prepare the data for further analysis.
                      Search, sort, and prioritize via the Rollbar dashboard.
                   DESC
    s.homepage     = "https://rollbar.com"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.authors      = { "Rollbar" => "support@rollbar.com" }
    s.source       = { :git => "https://github.com/rollbar/rollbar-apple.git",
                       :tag => "#{s.version}" }
    s.documentation_url = "https://docs.rollbar.com/docs/apple"
    s.social_media_url  = "http://twitter.com/rollbar"
    s.resource = "rollbar-logo.png"

    s.osx.deployment_target = "12.0"
    s.ios.deployment_target = "14.0"
    s.tvos.deployment_target = "14.0"
    s.watchos.deployment_target = "8.0"

    s.source_files  = "#{s.name}/Sources/#{s.name}/**/*.{h,m}"
    s.public_header_files = "#{s.name}/Sources/#{s.name}/include/*.h"
    s.module_map = "#{s.name}/Sources/#{s.name}/include/module.modulemap"

    s.framework = "Foundation"
    s.dependency "RollbarCommon", "~> #{s.version}"
    s.dependency "RollbarNotifier", "~> #{s.version}"

    s.requires_arc = true
    s.xcconfig = {
      "USE_HEADERMAP" => "NO",
      "HEADER_SEARCH_PATHS" => "$(PODS_ROOT)/#{s.name}/#{s.name}/Sources/#{s.name}/**"
    }
end
