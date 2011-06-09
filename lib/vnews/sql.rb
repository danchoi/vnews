require 'mysql2'
class Vnews
  class Sql
    attr_accessor :config, :client

    def self.shell_escape(string)
      require 'shellwords'
      Shellwords.shellescape(string)
    end

    def self.create_db(config)
      config = symbolize_config(config)
      create_sql = File.join(File.dirname(__FILE__), '..', 'create.sql')
      passwordarg = config[:password] ? ("-p#{shell_escape(config[:password])}") : ''
      puts `mysqladmin -h #{shell_escape config[:host]} -u #{shell_escape config[:username]} #{passwordarg} create #{shell_escape config[:database]}`
      puts `mysql -h #{shell_escape config[:host]} -D #{shell_escape config[:database]} -u #{shell_escape config[:username]} #{passwordarg} < #{create_sql}`
    end

    def self.symbolize_config(config)
      config = config.inject({}) do |memo, (key, value)|
        memo[key.to_sym] = value
        memo
      end
      config
    end

    def initialize(config = {})
      config = Vnews::Sql.symbolize_config(config)
      defaults = {:host => 'localhost',  :database => 'vnews', :username => 'root', :password => nil}
      @config = defaults.update(config)
      @client = Mysql2::Client.new @config
    end

    def insert_feed(title, feed_url, link, folder=nil)
      if folder.nil?
        folder = 'Misc'
      end
      @client.query "INSERT IGNORE INTO feeds (title, feed_url, link) VALUES ('#{e title}', '#{e feed_url}', '#{e link}')"
      if folder
        @client.query "INSERT IGNORE INTO feeds_folders (feed, folder) VALUES ('#{e feed_url}', '#{e folder}')"
      end
    end

    def delete_feed_items(feed_url)
      puts @client.query("DELETE from items where feed = '#{e feed_url}'")
    end

    def delete_feed(feed_url)
      @client.query "DELETE from feeds where feed_url = '#{e feed_url}'"
      # Delete all unstarred items from these feeds
      @client.query "DELETE from items where feed = '#{e feed_url}' and starred = false"
    end

    def delete_feed_folder(feed, folder)
      @client.query "DELETE from feeds_folders where feed = '#{e feed}' and folder = '#{e folder}'"
    end

    def insert_item(item)
      # not sure if this is efficient
      @client.query "DELETE from items WHERE guid = '#{e item[:guid]}' and feed = '#{e item[:feed_title]}'"
      @client.query "INSERT IGNORE INTO items (guid, feed, feed_title, title, link, pub_date, author, text, word_count) 
        VALUES (
        '#{e item[:guid]}', 
        '#{e item[:feed]}', 
        '#{e item[:feed_title]}', 
        '#{e item[:title]}', 
        '#{e item[:link]}', 
        '#{item[:pub_date]}',  
        '#{e item[:author]}',  
        '#{e item[:content][:text]}',
        '#{item[:content][:text].scan(/\S+/).size}'
        )"
    end

    # queries:

    def folders
      all = @client.query("SELECT 'All' as folder, count(*) as count from items").first
      starred = @client.query("SELECT 'Starred' as folder, count(*) as count from items where items.starred = true").first
      folders = @client.query("SELECT folder, count(*) as count from feeds_folders 
                    inner join items i on i.feed = feeds_folders.feed
                    group by folder order by folder")
      folders = [all, starred] + folders.to_a 
      folders
    end

    def configured_folders
      folders = @client.query("SELECT distinct(folder) from feeds_folders order by folder asc")
    end

    def configured_feeds_folders
      @client.query("SELECT feed,folder from feeds_folders order by folder asc").map {|x| [x['feed'], x['folder']]}
    end


    def feeds(order)
      if order == 0 
        # "feeds.title asc" 
        @client.query("SELECT feeds.*, count(i.unread) as item_count from feeds 
                      left outer join items i on i.feed = feeds.feed_url
                      group by feeds.feed_url
                      order by feeds.title asc") 
      else
        @client.query("SELECT feeds.*, feeds.num_items_read as item_count from feeds 
                      order by num_items_read desc, title asc") 
      end
    end

    def feeds_in_folder(folder)
      case folder
      when "All"
        @client.query("SELECT feed_url from feeds order by title asc").map {|x| x['feed_url']}
      when "Starred"
        return []
      else
        @client.query("SELECT feed from feeds_folders ff where ff.folder = '#{e folder}'").map {|x| x['feed']}
      end
    end

    # Not perfect because some feeds may have dup titles, but ok for now
    def feed_items(feed_title) 
      # update last_viewed_at 
      @client.query "UPDATE feeds SET last_viewed_at = now() where title = '#{e feed_title}'"
      query = "SELECT items.title, guid, feed, feed_title, pub_date, word_count, starred, unread from items where items.feed_title = '#{e feed_title}' order by pub_date asc"
      @client.query(query)
    end

    def feed_by_title(feed_title)
      query = "SELECT * from feeds where title = '#{e feed_title}'"
      @client.query(query).first["feed_url"]
    end

    def folder_items(folder) 
      query = case folder 
              when 'Starred' 
                "SELECT items.title, items.guid, items.feed, 
                items.feed_title, items.pub_date, items.word_count, items.starred, items.unread from items 
                      where items.starred = true order by items.starred_at, items.pub_date asc"
              when 'All' 
                "SELECT items.title, items.guid, items.feed, 
                items.feed_title, items.pub_date, items.word_count, items.starred, items.unread from items 
                      order by items.pub_date asc"
              else 
                # update last_viewed_at 
                @client.query "UPDATE feeds_folders SET last_viewed_at = now() where folder = '#{e folder}'"

                "SELECT items.title, items.guid, items.feed, 
                items.feed_title, items.pub_date, items.word_count, items.starred, items.unread from items 
                      left join feeds_folders ff on  ff.feed = items.feed
                      where ff.folder = '#{e folder}' order by items.pub_date asc"
              end
      @client.query query
    end

    def show_item(guid, inc_read_count=false)
      # mark item as read
      @client.query "UPDATE items set unread = false where guid = '#{e guid}'"

      if inc_read_count
        # increment the read count for the feed 
        @client.query "UPDATE feeds set num_items_read = num_items_read + 1 where feed_url = (select feed from items where items.guid = '#{e guid}' limit 1)"
      end

      query = "SELECT items.* from items where guid = '#{e guid}'"
      @client.query query
    end

    def star_item(guid, star=true)
      @client.query "UPDATE items set starred = #{star}, starred_at = now() where guid = '#{e guid}'"
    end

    def delete_item(guid)
      @client.query "DELETE from items where guid = '#{e guid}'" 
    end

    def search_items(term)
      query = "select items.*, MATCH(title, text) against('#{e term}') as score from items where MATCH(title, text) against('#{e term}') order by pub_date asc"
      @client.query query
    end

    def e(value)
      return unless value
      @client.escape(value)
    end

  end

end
