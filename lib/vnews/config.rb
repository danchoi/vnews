require 'vnews/sql'
require 'yaml'

class Vnews
  def self.sql_client
    $sql_client ||= Config.load_config
  end

  module Config
    def self.generate_config
      config = Vnews.sql_client.config.inject({}) do |memo, (k, v)|
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

    def self.stub_config
      stub = <<-END.gsub(/^ */, '')
        host: localhost 
        database: vnews 
        username: root 
        password: 

        General News 
        http://feedproxy.google.com/economist/full_print_edition
        http://feeds.feedburner.com/TheAtlanticWire

        Humor
        http://feed.dilbert.com/dilbert/blog

        Tech 
        http://rss.slashdot.org/Slashdot/slashdot
        http://feeds2.feedburner.com/readwriteweb
        http://feedproxy.google.com/programmableweb
        http://news.ycombinator.com/rss
        http://daringfireball.net/index.xml
        http://dailyvim.blogspot.com/feeds/posts/default
      END
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

      Sql.new(dbconfig)
    end
  end
end

if __FILE__ == $0
  puts Vnews::Config.generate_config 
end
