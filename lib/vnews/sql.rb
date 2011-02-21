require 'mysql2'
class Vnews
  class Sql
    def initialize(config = {})
      defaults = {:host => 'localhost', :username => 'root', :database => 'vnews'}
      @config = defaults.update(config)
      @client = Mysql2::Client.new @config
    end

    def insert_feed(title, feed_url, link, folder=nil)
      if folder.nil?
        folder = 'Main'
      end
      @client.query "INSERT IGNORE INTO feeds (title, feed_url, link) VALUES ('#{e title}', '#{e feed_url}', '#{e link}')"
      if folder
        @client.query "INSERT IGNORE INTO feeds_folders (feed, folder) VALUES ('#{e feed_url}', '#{e folder}')"
      end
    end

    def delete_feed_items feed_url
      puts @client.query("DELETE from items where feed = '#{e feed_url}'")
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
      starred = @client.query("SELECT 'Starred' as folder, count(*) as count from items
                    where items.starred = true").first

      folders = @client.query("SELECT folder, count(*) as count from feeds_folders 
                    inner join items i on i.feed = feeds_folders.feed
                    group by folder order by folder")

      folders = [starred] + folders.to_a 
      folders
    end

    def feeds
      @client.query("SELECT feeds.*, count(*) as item_count from feeds 
                    inner join items i on i.feed = feeds.feed_url
                    group by feeds.feed_url
                    order by feeds.title asc") 
    end

    # Not perfect because some feeds may have dup titles
    def feed_items(feed_title) 
      query = "SELECT items.title, guid, feed, feed_title, pub_date, word_count, starred, unread from items where items.feed_title = '#{e feed_title}' order by pub_date asc"
      @client.query(query)
    end

    def folder_items(folder) 
      query = case folder 
              when 'Starred' 
                "SELECT items.title, items.guid, items.feed, 
                items.feed_title, items.pub_date, items.word_count, items.starred, items.unread from items 
                      where items.starred = true order by items.pub_date asc"
              else 
                "SELECT items.title, items.guid, items.feed, 
                items.feed_title, items.pub_date, items.word_count, items.starred, items.unread from items 
                      inner join feeds_folders ff on  ff.feed = items.feed
                      where ff.folder = '#{e folder}' order by items.pub_date asc"
              end
      @client.query query
    end

    def show_item(guid)
      # mark item as read
      @client.query "UPDATE items set unread = false where guid = '#{e guid}'"
      query = "SELECT items.* from items where guid = '#{e guid}'"
      @client.query query
    end

    def star_item(guid, star=true)
      @client.query "UPDATE items set starred = #{star} where guid = '#{e guid}'"
    end

    def delete_item(guid)
      @client.query "DELETE from items where guid = '#{e guid}'" 
    end

    def search_items(term)
      query = "select * from items where match(title, text) against('#{e term}')"
      @client.query query
    end

    def e(value)
      return unless value
      @client.escape(value)
    end

  end

  SQLCLIENT = Sql.new() # TODO inject config here
end
