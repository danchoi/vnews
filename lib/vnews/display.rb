require 'vnews/sql'

class Vnews
  class Display

    def initialize
      @sqliteclient = Vnews::SQLCLIENT
    end

    # returns folders as a list
    def folders
      @sqliteclient.folders.map do |x|
        "#{x["folder"]} (#{x['count']})"
      end.join("\n")
    end

    # returns feeds as a list, sorted alphabetically
    # e.g.
    # {"title"=>"Bits",
    # "feed_url"=>"http://bits.blogs.nytimes.com/feed/",
    # "link"=>"http://bits.blogs.nytimes.com/"}
    def feeds(folder=nil)
      @sqliteclient.feeds(folder).map do |x|
        x.inspect
      end
    end

    # returns items as a list, most recent first
    # e.g.
    # {"title"=>"Episode 96: Git on Rails", "guid"=>"git-on-rails",
    # "feed"=>"http://feeds.feedburner.com/railscasts",
    # "feed_title"=>"Railscasts", "pub_date"=>2008-03-10 00:00:00 -0400,
    # "word_count"=>41}

    def feed_items(feed=nil)
      @sqliteclient.feed_items(feed).map do |x|
        x.inspect
      end
    end

    def folder_items(folder=nil)
      # strip off the count summary
      folder = folder.gsub(/\(\d+\)$/, '').strip
      @sqliteclient.folder_items(folder).map do |x|
        x.inspect
      end
    end


  end
end

if __FILE__ == $0
  puts Vnews::Display.new.send *ARGV
end
