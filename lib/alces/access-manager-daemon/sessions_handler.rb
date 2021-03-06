
require 'yaml'

module Alces
  module AccessManagerDaemon
    class SessionsHandler < BlankSlate

      def sessions_info(username)
        set_correct_user_home
        {
          sessions: sessions_for(username),
          session_types: session_types,
          can_launch_compute_sessions: qdesktop_available,
          has_vpn: vpn_handler_enabled,
          login_ip: node_public_ip,
          proxy_address: node_access_address,
        }
      end

      def launch_session(session_type, request_compute_node=false)
        set_correct_user_home

        # TODO: Check session_type is valid.

        # Different command used to launch sessions on login node (node this
        # daemon is running on) vs requesting a session on any available
        # compute node.
        if request_compute_node
          launch_session_command = "#{qdesktop_command} #{session_type}"
        else
          launch_session_command = "#{alces_command} session start #{session_type}"
        end

        # Source clusterware shell configuration before launching session;
        # required for environment to be setup for qdesktop to work correctly.
        # TODO: Better way to do this?
        # Run command in new session using setsid, so VNC session does not exit
        # if daemon is stopped.
        launch_output = run("source /etc/profile.d/alces-clusterware.sh && setsid #{launch_session_command}")

        if $?.exitstatus != 0
          launch_output # Return output with reason for failure.
        else
          true # Success.
        end
      end

      def vpn_config
        # Return the tarred, gzipped VPN config to the server where it can be
        # offered for download.
        run "cd #{clusterware_root}/etc/openvpn/client/clusterware/ && tar -zcf - *"
      end

      private

      def set_correct_user_home
        # This hack is needed to set $HOME to the correct value for the current
        # user we are acting as; this is not done when we setuid to act as this
        # user but is needed to correctly run clusterware `alces` commands as
        # them.
        # TODO: do this a nicer way?
        user_home = run('whoami').strip
        ::ENV['HOME'] = run("echo ~#{user_home}").strip
      end

      def sessions_for(username)
        user_sessions_path = ::File.expand_path "~#{username}/.cache/clusterware/sessions"
        metadata_filename ='metadata.vars.sh'
        session_metadata_glob = ::File.join(user_sessions_path, '*', metadata_filename)
        session_uuid_regex = /#{::File.join(user_sessions_path, '([^/]+)', metadata_filename)}/

        sessions = []
        if ::Dir.exist? user_sessions_path
          session_metadata_files = ::Dir.glob(session_metadata_glob)
          session_metadata_files.map do |file|
            metadata_text = ::File.read file
            session_uuid = file.match(session_uuid_regex)[1]
            sessions << parse_session(metadata_text).tap do |session|
              session['uuid'] = session_uuid
            end
          end
        end
        sessions
      end

      # Find all the dirs in $cw_ROOT/etc/sessions with a `session.sh` script;
      # these are the available session types for this cluster.
      def session_types
        session_types_dir = ::File.join(clusterware_root, '/etc/sessions')
        session_creation_filename = 'session.sh'
        ::Dir.entries(session_types_dir).select do |dir|
          dir_path = ::File.join(session_types_dir, dir)
          ::Dir.exist?(dir_path) && ::Dir.entries(dir_path).include?(session_creation_filename)
        end
      end

      def clusterware_root
        ::ENV['cw_ROOT'] || '/opt/clusterware'
      end

      def alces_command
        ::File.join(clusterware_root, '/bin/alces')
      end

      def qdesktop_command
        ::File.join(clusterware_root, '/opt/gridscheduler/bin/linux-x64/qdesktop')
      end

      # Run a shell command with backtick operator; need to do this this way as
      # no methods from Kernel are defined within this class (I assume to
      # prevent security holes as methods are being executed remotely).
      def run(command)
        ::Kernel.send(:`, command)
      end

      def parse_session(metadata_text)
        metadata_hash = {}
        metadata_text.each_line do |line|
          key_match = line.match(/vnc\[(\w+)\]/)
          value_match = line.match('"([^"]+)"')

          if key_match && value_match
            key = key_match[1].downcase
            value = value_match[1]
            metadata_hash[key] = value
          else
            metadata_hash['errors'] ||= []
            metadata_hash['errors'] << line.chomp
          end
        end
        metadata_hash
      end

      def qdesktop_available
        ::File.file? qdesktop_command
      end

      def node_public_ip
        node_info = run "#{alces_command} about node"
        ip_address_regex = /IP address:\s+([\w\.]+)/
        match = ip_address_regex.match(node_info)
        match[1] if match
      end

      def node_access_address
        access_info = run "#{alces_command} about access"
        access_address_regex = /Access host name:\s+([^\s]+)/
        match = access_address_regex.match(access_info)
        match[1] if match
      end

      def vpn_handler_enabled
        vpn_handler_enabled_regex = /^\[\*\].*base.*\/.*cluster-vpn.*$/
        available_handlers = run "#{alces_command} handler avail"
        !!(available_handlers =~ vpn_handler_enabled_regex)
      end

    end
  end
end
