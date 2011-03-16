require 'vnews/feed'
require 'vnews/constants'

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
        Vnews.sql_client.feeds_in_folder(folder.strip).each do |feed|
          begin
            Timeout::timeout(Vnews::TIMEOUT) do 
              feed_url, f, folder = *Vnews::Feed.fetch_feed(feed, folder)
              Vnews::Feed.save_feed feed_url, f, folder
            end
          rescue Timeout::Error
            puts "TIMEOUT ERROR: #{feed_url}"
          end
        end
        puts "\nDone"
      end
    end
  end
end
