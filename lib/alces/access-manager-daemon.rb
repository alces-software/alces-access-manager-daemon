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
require 'alces/storage-manager-daemon/blank_slate'
require 'alces/storage-manager-daemon/control'
require 'alces/storage-manager-daemon/errors'
require 'alces/storage-manager-daemon/forker'
require 'alces/storage-manager-daemon/io_forker'
require 'alces/storage-manager-daemon/fork_handler'
require 'alces/storage-manager-daemon/forked_io_handler'
require 'alces/storage-manager-daemon/arriba_handler'
require 'alces/storage-manager-daemon/targets_handler'
require 'alces/storage-manager-daemon/sessions_handler'
require 'alces/storage-manager-daemon/handler'
require 'alces/storage-manager-daemon/constantize'
require 'alces/tools/daemon'
require 'alces/tools/drb'
require 'alces/tools/ssl_configurator'

module Alces
  class << self
    def development!
      @development = true
    end
    def development?
      @development == true
    end
  end

  module StorageManagerDaemon
    include Alces::Tools::Daemon

    class Configuration < Alces::Tools::Daemon::Configuration
      include DaemonKit
      include SSL

      def storage_manager_daemon_ssl=(config)
        self.ssl = config
      end
    end

    class << self
      include Alces::Tools::SSLConfigurator

      def default_config
        super.
          merge({
                  port: 25268,
                  log_file: File.join(DaemonKit.root,'log','daemon.log'),
                  configs: ['ssl']
                })
      end

      def ssl
        config.ssl
      end
    end
  end
end
