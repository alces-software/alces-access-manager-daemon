require 'yaml'

module Alces
  module AccessManagerDaemon
    class SessionsHandler < BlankSlate

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

        {sessions: sessions, session_types: session_types}
      end

      def launch_session(session_type, request_compute_node=false)
        # TODO:
        # - Check session_type is valid.

        # This hack is needed to set $HOME to the correct value for the current
        # user we are acting as; this is not done when we setuid to act as this
        # user but is needed to create sessions as them.
        # TODO: do this a nicer way?
        user_home = run('whoami').strip
        ::ENV['HOME'] = run("echo ~#{user_home}").strip

        # Different command used to launch sessions on login node (node this
        # daemon is running on) vs requesting a session on any available
        # compute node.
        if request_compute_node
          launch_session_command = "qdesktop #{session_type}"
        else
          alces_command = ::File.join(clusterware_root, '/bin/alces')
          launch_session_command = "#{alces_command} session start #{session_type}"
        end

        # Source clusterware shell configuration before launching session;
        # required for environment to be setup for qdesktop to work correctly.
        # TODO: Better way to do this?
        # Run command in new session using setsid, so VNC session does not exit
        # if daemon is stopped.
        run("source /etc/profile.d/alces-clusterware.sh && setsid #{launch_session_command}")
      end

      private

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

    end
  end
end
