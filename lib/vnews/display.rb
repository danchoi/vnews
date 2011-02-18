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
    def feeds(folder=nil)
      @sqliteclient.feeds(folder).map do |x|
        x.inspect
      end
    end

    # returns items as a list, most recent first
    def items(feed=nil)
      @sqliteclient.items(feed).map do |x|
        x.inspect
      end
    end

  end
end



if __FILE__ == $0
  puts Vnews::Display.new.send *ARGV
end
