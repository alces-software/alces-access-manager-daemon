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
module Alces
  module StorageManagerDaemon
    class IOForker < Forker
      attr_accessor :path, :direction
      def initialize(opts, path, direction)
        self.uid, self.gid = Forker.privileges_for(opts)
        self.timeout = Forker.timeout_for(opts)
        assert_valid_privileges!
        self.path = path
        self.direction = direction
      end

      def fork(message,*a,&b)
        ForkedIOHandler.new(self).handle
      end
    end
  end
end