require 'vnews/sql'
require 'yaml'

class Vnews
  module Config
    def self.generate_config
      config = Vnews.sqlite_client.config.inject({}) do |memo, (k, v)|
        memo[k.to_s] = v
        memo
      end
      out = [config.to_yaml.sub(/---\s+/, ''), '']
      Vnews.sql_client.configured_folders.map do |x| 
        folder = x["folder"]
        out << folder
        Vnews.sql_client.feeds_in_folder(folder).each do |feed|
          out <<  feed
        end
        out << ""
      end
      out.join("\n")
    end

    def self.parse_config(config)
    end

    CONFIGPATH = "#{ENV['HOME']}/.vnewsrc"
    def self.load_config
      if ! File.exists?(File.expand_path(CONFIGPATH))
        return false
      end
      f = File.read(File.expand_path(CONFIGPATH))
      # split into two parts
      top, bottom = f.split(/^\s*$/,2)
      dbconfig = YAML::load top
      # parse database config
      puts "Loaded database config for #{dbconfig['username']}@#{dbconfig['database']} at #{dbconfig['host']}"

      # track feeds that must be deleted

      # Put feeds in right folder
      $sql_client = Sql.new(dbconfig)
    end
  end
  def self.sql_client
    if ! $sql_client 
      Config.load_config
    end
    $sql_client
  end

end

if __FILE__ == $0
  puts Vnews::Config.generate_config 
end
