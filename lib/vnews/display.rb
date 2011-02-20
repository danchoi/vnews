require 'vnews/sql'
require 'yaml'

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
    def feeds
      @sqliteclient.feeds.map.with_index do |x, idx|
        "#{ x['title'] } (#{x['item_count']})"
      end
    end

    # returns items as a list, most recent first
    # e.g.
    # {"title"=>"Episode 96: Git on Rails", "guid"=>"git-on-rails",
    # "feed"=>"http://feeds.feedburner.com/railscasts",
    # "feed_title"=>"Railscasts", "pub_date"=>2008-03-10 00:00:00 -0400,
    # "word_count"=>41}

    def col(string, width)
      string[0,width].ljust(width)
    end

    def format_date(d)
      if d.nil?
        "no date"
      elsif d.year != Time.now.year
        d.strftime("%b %Y")
      else
        d.strftime("%b %d")
      end 
    end

    def format_item_summary(i)
      feed_title = col i['feed_title'], 20
      title = col(i['title'], 50)
      d = i['pub_date']
      date_string = format_date(d)
      date = col(date_string, 9)
      guid = i['guid']
      word_count = col i['word_count'].to_s, 6
      "%s %s %s %s %s" % [feed_title, title, word_count, date, guid]
    end

    # look up feed up idx
    def feed_items(*feed_selection)
      idx = feed_selection.join(' ')[/\d+$/, 0]
      raise "Need an idx for feed #{feed_selection.inspect}: #{idx.inspect}" unless idx
      @sqliteclient.feed_items(idx).map do |x|
        format_item_summary x
      end
    end

    def folder_items(folder=nil)
      # strip off the count summary
      folder = folder.gsub(/\(\d+\)$/, '').strip
      @sqliteclient.folder_items(folder).map do |x|
        format_item_summary x
      end
    end

    def format_item(item)
      res = <<-END
#{format_date item['pub_date']}, #{item['word_count']} words, #{item['feed_title']}, #{item['feed']}
 

#{item['title']}#{item['author'] ? ("\n" + item['author']) : '' }  

#{item['text']}
      END
    end

    def show_item(guid)
      res = @sqliteclient.show_item(guid).first
      if res
        format_item(res)
      else
        "No item found"
      end
    end

  end
end

if __FILE__ == $0
  puts Vnews::Display.new.send *ARGV
end
