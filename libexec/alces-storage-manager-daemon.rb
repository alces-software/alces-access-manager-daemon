#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Storage Manager Daemon.
#
# Alces Storage Manager is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Storage Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Storage Manager Daemon, please visit:
# https://github.com/alces-software/alces-storage-manager-daemon
#==============================================================================
DaemonKit::Application.running! do |config|
  module ::Alces
    module Tools
      module SSLConfigurator
        class Configuration
          attr_reader :verify
          def initialize(h)
            @verify = h.delete('verify')
            h.each do |k,v|
              self[k] = v
            end
          end
        end

        def ssl_verify_mode
          if Alces::StorageManagerDaemon.config.ssl.verify == false
            OpenSSL::SSL::VERIFY_NONE
          else
            OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
          end
        end
      end
    end
  end

  Alces::StorageManagerDaemon.setup! do |daemon|
    daemon.load_config('storage-manager-daemon')
    # Extend the standard Alces::Tools::Logger to provide a convenience
    # method that DaemonKit internals expect to be able to use when
    # exceptions are rescued internally.
    class << daemon.logger
      def exception(e)
        error('DaemonKit logged exception'){e}
      end
    end
    DaemonKit.logger = daemon.logger
    DaemonKit.logger.level = Logger::INFO
    DaemonKit.logger.auto_flushing = 2
  end

  Alces::Tools::DRb.listen(Alces::StorageManagerDaemon.config, Alces::StorageManagerDaemon::Control.new)
end

# Add to the term_proc to disable thread safe logging in order to
# defeat Ruby 2.0 requirement for no mutexes in trap handlers.
daemon_kit_term_proc = trap('INT', 'IGNORE')
term_proc = Proc.new do
  DaemonKit.logger.thread_safety_disabled = true
  daemon_kit_term_proc.call
end
trap('INT', &term_proc)
trap('TERM', &term_proc)
# XXX - consider retrapping HUP, USR1 and USR2 as well, because our
# logger implementation causes these to break.

DaemonKit.at_shutdown do
  DaemonKit.logger.flush_all
end

if ARGV.include?("alces_development=true")
  Alces.development!
  DaemonKit.logger.info "-- ENTERING ALCES DEVELOPMENT MODE --"
end

DaemonKit.logger.info "-- STARTED --"
loop do
  DaemonKit.logger.info "-- MARK --"
  DaemonKit.logger.flush
  sleep 60
end
