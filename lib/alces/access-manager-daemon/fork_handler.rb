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
    class ForkHandler < Struct.new(:forker, :message, :args, :block)
      class << self
        def handle(forker, message, args, block)
          new(forker, message, args, block).handle
        end
      end

      def initialize(*args)
        super
        @rd, @wr = IO.pipe
      end

      def handle
        # Flush parent logs so that they appear in the log file close to the
        # child's.
        DaemonKit.logger.flush
        handle_parent(Kernel.fork(&method(:handle_child))).tap do |o|
          raise o if o.is_a?(Exception)
        end
      end

      private
      def handle_parent(pid)
        @wr.close
        Marshal.load(@rd.read)
      ensure
        Process.wait(pid)
      end
      
      def handle_child
        # Make sure not to copy across logs from the parent.
        DaemonKit.logger.clear_buffers
        @rd.close
        forker.change_privilege
        forker.with_timeout do
          forker.handler.__send__(message, *args, &block).tap do |result|
            @wr.write(Marshal.dump(result))
          end
        end
      rescue
        begin
          @wr.write(Marshal.dump($!))
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace.join("\n")
        end
      ensure
        # Ensure that all logs are flushed prior to exit.
        DaemonKit.logger.flush_all! rescue nil
        Kernel.exit!
      end
    end
  end
end
