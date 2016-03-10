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
require 'etc'
require 'alces/tools/core_ext/string/camelize'

module Alces
  module StorageManagerDaemon
    class Forker
      class << self
        def privileges_for(opts)
          case opts
          when NilClass
            raise(ArgumentError, 'No UID/GID supplied')
          when Hash
            if opts.key?(:uid)
              privileges = opts[:uid]
              privileges = [privileges,opts[:gid]] if opts[:gid]
              privileges_for(privileges)
            elsif opts.key?(:username)
              pwd = ::Etc.getpwnam(opts[:username])
              privileges_for([pwd.uid, pwd.gid])
            else
              raise(ArgumentError, "Invalid options hash supplied. Must specify either :uid or :username: #{opts.keys}")
            end
          when Array
            [opts[0].to_i, (opts[1] || opts[0]).to_i]
          else
            if opts.respond_to?(:to_i)
              [opts.to_i, opts.to_i]
            else
              raise(ArgumentError, "Invalid options object supplied: #{opts.class.name}")
            end
          end
        end

        def timeout_for(opts)
          opts.is_a?(Hash) && opts[:timeout]
        end

        def handler_args_for(opts)
          case opts
          when Hash
            handler_args = opts[:handler_args]
            case handler_args
            when Array
              handler_args
            when NilClass
              []
            else
              [handler_args]
            end
          else
            []
          end
        end

        def handler_class_for(opts)
          case opts
          when Hash
            handler_class = opts[:handler]
            case handler_class
            when Symbol
              Alces::StorageManagerDaemon.constantize("Alces::StorageManagerDaemon::#{handler_class.to_s.camelize}Handler")
            when String
              Alces::StorageManagerDaemon.constantize(handler_class)
            when NilClass
              Alces::StorageManagerDaemon::Handler
            when :io
              Alces::StorageManagerDaemon::IoHandler
            when Class
              handler_class
            else
              raise(ArgumentError, "Invalid handler class supplied: #{handler_class}")
            end
          else
            Alces::StorageManagerDaemon::Handler
          end
        end
      end

      attr_accessor :handler_class, :handler_args
      attr_accessor :uid, :gid, :timeout

      def initialize(opts)
        self.uid, self.gid = Forker.privileges_for(opts)
        self.timeout = Forker.timeout_for(opts)
        assert_valid_privileges!
        self.handler_class = Forker.handler_class_for(opts)
        self.handler_args = Forker.handler_args_for(opts)
      end

      def fork(s, *a, &b)
        ForkHandler.handle(self,s,a,b)
      end

      def change_privilege
        begin
          uname = Etc.getpwuid(uid).name
          Process.initgroups(uname, gid)
        rescue ArgumentError
          # Unable to find user for <uid>
        end
        Process::GID.change_privilege(gid)
        Process::UID.change_privilege(uid)
      end

      def with_timeout(&block)
        if timeout.nil?
          block.call
        else
          Timeout.timeout(self.timeout, &block)
        end
      end

      def handler
        handler_class.new(*handler_args)
      end

      private
      def assert_valid_privileges!
        raise(ArgumentError, 'GID 0 prohibited') if gid == 0
        raise(ArgumentError, 'UID 0 prohibited') if uid == 0
      end
    end
  end
end
