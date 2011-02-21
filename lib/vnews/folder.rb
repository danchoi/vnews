require 'vnews/feed'

class Vnews
  class Folder

    def self.update_folder(folder)
      if folder.strip == "Starred"
        puts "Sorry, you can't update the starred folder."
        return
      else
        require 'vnews/display'
        folder = Vnews::Display.strip_item_count(folder)
        puts "Updating folder: #{folder.inspect}"
        Vnews::SQLCLIENT.feeds_in_folder(folder.strip).each do |feed|
          puts "Updating feed: #{feed.inspect}"
          f = Vnews::Feed.get_feed feed
          Vnews::Feed.save_feed feed, f, nil
          puts "\nFeed updated"
        end
      end
    end
  end
end
