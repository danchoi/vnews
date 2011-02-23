require 'vnews/feed'
require 'thread_pool'

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
        feeds = []
        pool = ThreadPool.new(10)
        puts "Using thread pool size of 10"
        Vnews.sql_client.feeds_in_folder(folder.strip).each do |feed|
          pool.process do 
            sleep(rand(10))
            feeds << Vnews::Feed.fetch_feed(feed, folder)
          end
        end
        pool.join
        puts "Saving data to database"
        feeds.select {|x| x[1]}.compact.each do |feed_url, f, folder|
          Vnews::Feed.save_feed feed_url, f, folder
        end
        puts "\nDone"
      end
    end
  end
end
