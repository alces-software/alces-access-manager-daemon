require 'yaml'

module Alces
  module StorageManagerDaemon
    class SessionsHandler < BlankSlate

      def sessions_for(username)
        user_sessions_path = ::File.expand_path "~#{username}/.cache/clusterware/sessions"
        if ::Dir.exist? user_sessions_path
          session_metadata_glob = ::File.join(user_sessions_path, '*', 'metadata.vars.sh')
          session_metadata_files = ::Dir.glob(session_metadata_glob)
          metadata_texts = session_metadata_files.map {|f| ::File.read f}
          metadata_texts.map {|metadata| metadata_hash(metadata)}
        else
          # TODO: error handling
          user_sessions_path
        end
      end

      private

      def metadata_hash(metadata)
        # TODO: decide format for reporting errors
        metadata_hash = {}
        metadata.each_line do |line|
          key_match = line.match(/vnc\[(\w+)\]/)
          value_match = line.match('"([^"]+)"')

          key = key_match[1].downcase
          value = value_match[1]
          metadata_hash[key] = value
        end
        metadata_hash
      end

    end
  end
end
