# Be sure to restart your daemon when you modify this file

# Boot up
require File.join(File.dirname(__FILE__), 'boot')

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, DaemonKit.env

DaemonKit::Initializer.run do |config|

  # The name of the daemon as reported by process monitoring tools
  config.daemon_name = 'alces-access-manager-daemon'
end
