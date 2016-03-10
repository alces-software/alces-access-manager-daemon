require 'yaml'

module Alces
  module StorageManagerDaemon
    class TargetsHandler < BlankSlate

      def self.global_targets
        globaldir = "/etc/xdg/clusterware/storage/"
        @global_targets ||= TargetsHandler::load_from_directory(globaldir)
      end

      def user_targets(username)
        userdir = ::Dir.home + "/.config/clusterware/storage/"
        TargetsHandler::load_from_directory(userdir)
      end

      def targets_for(username)
        TargetsHandler::global_targets.merge(user_targets(username))
      end

      private

      class << self
        def load_from_directory(directory)
          targets = {}
          if ::Dir.exist?(directory)
            ::DaemonKit.logger.debug("Looking for targets in " + directory)
            ::Dir.glob(directory + "*.target.yml") { |targetFile|
              ::DaemonKit.logger.debug("Found " + targetFile)
              target = symbolize_keys(::YAML.load_file(targetFile))
              target[:file] = targetFile # Useful for reporting errors
              targets[target.delete(:name)] = target
            }
            ::DaemonKit.logger.debug("Found targets: " + targets.inspect)
          end
        targets.sort_by {|k, v| v[:sortKey]||k }.to_h
        end

        # method based on Ruby on Rails's equivalent
        def symbolize_keys(hash)
          transform_keys(hash){ |key| key.to_sym rescue key }
        end
        # method based on Ruby on Rails's equivalent
        def transform_keys(hash)
          result = hash.class.new
          hash.each_key do |key|
            result[yield(key)] = hash[key]
          end
          result
        end
      end
    end
  end
end

Alces::StorageManagerDaemon::TargetsHandler.global_targets() # Initialise on startup (as root)
