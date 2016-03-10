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
require 'socket'

module Alces
  module AccessManagerDaemon
    class ForkedIOHandler < ForkHandler
      def handle
        # ensure ssl_context is set up in parent (under root) before
        # we change privileges - we can't access the certificate files
        # under a non-root user
        Alces::AccessManagerDaemon.ssl_context if ssl?
        super
      end

      private
      # result of handle_parent should be the address on which socket
      # communications with the child can proceed
      def handle_parent(pid)
        @wr.close
        Marshal.load(@rd.read).tap do |v|
          # we don't directly care about the child in this fork model,
          # so detach from it
          Process.detach(pid)
        end
      end

      def handle_child
        setup
        listen
      ensure
        Kernel.exit!
      end

      def server
        @server ||= TCPServer.new(0)
      end

      def setup
        @rd.close
        forker.change_privilege
        @wr.write(Marshal.dump(server.addr[1]))
      rescue
        @wr.write(Marshal.dump($!)) rescue nil
        raise
      ensure
        @wr.close
      end

      def connect_io(direction, path, socket)
        if direction == :download
          [File.open(path, 'r'), socket]
        else
          [socket, File.open(path, 'w')]
        end
      end

      def ssl?
        Alces::AccessManagerDaemon.ssl?
      end

      def socket_io(server)
        ssl? ? Alces::AccessManagerDaemon.ssl_server(server) : server
      end

      def listen
        input, output = connect_io(forker.direction, forker.path, socket_io(server).accept)
        @c = 0
        loop do
          data = input.read(1_048_576)
          break if data.nil?
          @c += 1
          # XXX - proper logging in here pls :-p
          STDERR.print '.' if @c % 10 == 0
          output.write(data)
        end
      rescue
        STDERR.puts $!.message
        STDERR.puts $!.backtrace.join("\n")
      ensure
        input.close rescue nil
        output.close rescue nil
        server.close rescue nil
      end
    end
  end
end
