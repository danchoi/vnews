require 'vnews/sql'
require 'yaml'
require 'thread_pool'

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

    def self.rewrite_config
      out = generate_config
      f = File.open(File.expand_path(CONFIGPATH), 'w') {|f| f.write(out)}
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

    def self.update_folders
      f = File.read(File.expand_path(CONFIGPATH))
      db, list = f.split(/^\s*$/,2)
      current_folder = nil
      ff = []
      list.split("\n").each do |line|
        line = line.strip
        if line =~ /^\s*http/ # feed
          ff << [line, current_folder]
        elsif line =~ /^\s*\w+/ # folder
          current_folder = line
        end
      end
      puts "Using feeds and folders: #{ff.inspect}"

      old_feeds = Vnews.sql_client.feeds(0).map {|x| x["feed_url"]}
      new_feeds = ff.map {|feed,folder| feed}
      rm_feeds = old_feeds - new_feeds
      puts "Removing feeds: #{rm_feeds.inspect}"
      rm_feeds.each {|x| Vnews.sql_client.delete_feed(x)}

      # ff is an association between a feed and a folder
      old_ff = Vnews.sql_client.configured_feeds_folders 
      rm_ff = old_ff - ff
      puts "Removing feed-folder associations: #{rm_ff.inspect}"
      rm_ff.each {|feed,folder| Vnews.sql_client.delete_feed_folder(feed,folder)}

      puts "Adding feeds: #{(new_feeds - old_feeds).inspect}"
      puts "Adding folder-feed associations: #{(ff - old_ff).inspect}"
      feeds2 = []
      pool = ThreadPool.new(10)
      puts "Using thread pool size of 10"
      # TODO sometimes feeds are downloaded twice;
      ff.each do |feed_url, folder|
        pool.process do 
          feeds2 << Vnews::Feed.fetch_feed(feed_url, folder)
        end
      end
      pool.join
      feeds2.each do |x|
        feed_url, f, folder = *x
        folder ||= "Misc"
        if f.nil?
          $stderr.print "\nNo feed found for #{feed_url}\n"
        else
          Vnews::Feed.save_feed(feed_url, f, folder)
        end
      end
      $stderr.puts "\nDone."
    end

    def self.load_config
      if ! File.exists?(File.expand_path(CONFIGPATH))
        return false
      end
      return if $sql_client
      f = File.read(File.expand_path(CONFIGPATH))
      top, bottom = f.split(/^\s*$/,2)
      dbconfig = YAML::load top
      Sql.new(dbconfig)
    end
  end
end

if __FILE__ == $0
  puts Vnews::Config.generate_config 
end
