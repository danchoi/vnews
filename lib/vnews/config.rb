require 'vnews/sql'
require 'yaml'

class Vnews
  module Config
    def self.generate_config
      config = Vnews::SQLCLIENT.config.inject({}) do |memo, (k, v)|
        memo[k.to_s] = v
        memo
      end
      out = [config.to_yaml.sub(/---\s+/, ''), '']
      Vnews::SQLCLIENT.configured_folders.map do |x| 
        folder = x["folder"]
        out << folder
        Vnews::SQLCLIENT.feeds_in_folder(folder).each do |feed|
          out <<  feed
        end
        out << ""
      end
      out.join("\n")
    end


    def self.load_config
      # parse database config

      # track feeds that must be deleted

      # Put feeds in right folder


    end
  end
end

if __FILE__ == $0
  puts Vnews::Config.generate_config 
end
