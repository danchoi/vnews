require 'vnews/sql'
require 'yaml'

class Vnews
  class Display

    def initialize
      @sqliteclient = Vnews::SQLCLIENT
      @window_width = 140
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
      return unless string
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

    def format_item_summary(i, width)
      varwidth = width.to_i - 31
      feed_title = col i['feed_title'], varwidth * 0.25
      title = col i['title'], varwidth * 0.75
      word_count = i['word_count'].to_s.rjust(6)
      date = col format_date(i['pub_date']), 20 # to push guid all the way off screen
      guid = i['guid']

      flag = i['unread'] == 1 ? '+' : ' '
      flag = i['starred'] == 1 ? '*' : flag
      "%s | %s | %s | %s | %s | %s" % [flag, feed_title, title, word_count, date, guid]
    end

    # look up feed up idx
    def feed_items(*feed_selection)
      window_width = feed_selection[0]
      feed_title = feed_selection[1].split(' ')[0..-2].join(' ') 
      @sqliteclient.feed_items(feed_title).map do |x|
        format_item_summary x, window_width
      end
    end

    def self.strip_item_count(folder)
      folder.gsub(/\(\d+\)$/, '').strip
    end

    def folder_items(window_width, folder)
      # strip off the count summary
      folder = self.class.strip_item_count(folder)
      @sqliteclient.folder_items(folder).map do |x|
        format_item_summary x, window_width
      end
    end

    def format_item(item)
      res = <<-END
#{item['feed']}

#{format_date item['pub_date']}, #{item['word_count']} words, #{item['feed_title']}
 

#{item['title']}#{item['author'] ? ("\n" + item['author']) : '' }  

#{item['text']}

---
#{item['link']}

      END
    end

    def show_item(guid)
      res = @sqliteclient.show_item(guid.strip).first
      if res
        format_item(res)
      else
        "No item found"
      end
    end

    def star_item(guid)
      @sqliteclient.star_item guid, true
    end

    def unstar_item(guid)
      @sqliteclient.star_item guid, false
    end

    def delete_item(guid)
      @sqliteclient.delete_item guid
    end


    def search_items(window_width, term)
      res = @sqliteclient.search_items(term).map do |x|
        format_item_summary x, window_width
      end
      res.empty? ? "No matches" : res
    end

  end

end

if __FILE__ == $0
  puts Vnews::Display.new.send *ARGV
end
