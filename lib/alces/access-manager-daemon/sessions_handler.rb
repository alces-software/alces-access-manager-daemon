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

      private

      # Find all the dirs in $cw_ROOT/etc/sessions with a `session.sh` script;
      # these are the available session types for this cluster.
      def session_types
        clusterware_root = ::ENV['cw_ROOT'] || '/opt/clusterware'
        session_types_dir = ::File.join(clusterware_root, '/etc/sessions')
        session_creation_filename = 'session.sh'
        ::Dir.entries(session_types_dir).select do |dir|
          dir_path = ::File.join(session_types_dir, dir)
          ::Dir.exist?(dir_path) && ::Dir.entries(dir_path).include?(session_creation_filename)
        end
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
