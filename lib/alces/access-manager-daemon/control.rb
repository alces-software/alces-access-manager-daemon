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
require 'rpam'

module Alces
  module AccessManagerDaemon
    class Control < BlankSlate

      # authenticate needs to exist here since we don't want it to fork and
      # execute with another user's privileges.
      def authenticate?(options, user, pass)
        ::Rpam.auth(
          user, pass, session: true, service: 'alces-access-manager-daemon'
        )
      end

      # ping exists here to just return true if the client was successfully
      # able to reach us.
      def ping(options) # Argument is required for remote call to work.
        true
      end

      PRIVATE_METHODS = [ :as,
                          :to_s,
                          :class,
                          :private_methods,
                          :protected_methods,
                          :instance_eval,
                          :instance_exec,
                          :send,
                          :__send__,
                          :method_missing
                        ]

      def method_missing(s, *a, &b)
        forker = Forker.new(a.shift)
        if forker.handler_class.method_defined?(s)
          as(forker, s, *a, &b)
        else
          super
        end
      end

      # implemented to satisfy DRb contracts
      def private_methods; ::Alces::AccessManagerDaemon::Control::PRIVATE_METHODS; end
      def protected_methods; []; end
      def to_s; 'Remote'; end
      def class; ::Object; end

      private
      def as(forker, s = nil, *a, &b)
        ::DaemonKit.logger.info("Forking with #{forker.inspect}") do
          [s, a]
        end
        forker.fork(s, *a, &b).tap do |result|
          ::Kernel::raise(result) if result.is_a?(::Exception)
        end
      end
    end
  end
end
