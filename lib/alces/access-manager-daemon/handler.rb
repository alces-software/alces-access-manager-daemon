#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Access Manager Daemon.
#
# Alces Access Manager is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Access Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Access Manager Daemon, please visit:
# https://github.com/alces-software/alces-access-manager-daemon
#==============================================================================
module Alces
  module AccessManagerDaemon
    class Handler # < BlankSlate
      class << self
        def define_x(s,str)
          define_method(s,str)
        end
      end

      def define_x(s,str)
        ::Alces::AccessManagerDaemon::Handler.define_x(s,str)
        hello
      end

      def try(s)
        __send__(s)
      end

      def whoami
        execute(['whoami'])
      end

      def execute(cmd)
        ::IO.popen(cmd) {|io| io.read}
      end

      def with_block(&block)
        block.call
      end
    end
  end
end
