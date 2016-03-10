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
require 'arriba'
require 'etc'

module Alces
  module AccessManagerDaemon
    class ArribaHandler < BlankSlate
      include ::Arriba::Operations::File

      attr_accessor :volume

      def initialize(root, name = nil)
        root = ::Alces::AccessManagerDaemon::DirectoryFinder.new(root).directory
        self.root = root
        self.name = name || root
        self.volume = ::Arriba::Volume::Directory.new(root, name)
      end

      # Eagerly create hash on the server-side
      def represent(path)
        ::Arriba::File.new(volume,path).tap {|f| f.to_hash}
      end
      
      # Eagerly create hash on the server-side
      def base
        ::Arriba::Root.new(volume,name).tap {|f| f.to_hash}
      end

      # override File IO method as we are unable to deliver a File over marshalling
      def io(path)
        abs(path)
      end

    end

    class DirectoryFinder
      def initialize(dir)
        @dir = dir
      end

      def directory
        case @dir
        when String
          if @dir[0] == '%'
            eval(%(::Kernel::lambda{"#{@dir[1..-1]}"}),
                 passwd_user.instance_eval{::Kernel::binding}).call
          elsif @dir =~ /^lambda{/
            l = eval("::Kernel::#{@dir}",BasicObject.new.instance_eval{::Kernel::binding})
            l.call(passwd_user)
          else
            @dir
          end
        when Symbol
          send(@dir)
        else
          raise "Unable to determine directory from: #{@dir}"
        end
      end
      
      def passwd_user
        ::Etc.getpwuid(::Process.uid)
      end
      
      def home
        passwd_user.dir
      end
      
      def tmpdir
        Dir.tmpdir
      end
    end
  end
end
