require 'mysql2'
class Vnews
  class Sql
    def initialize(config = {})
      defaults = {:host => 'localhost', :username => 'root', :database => 'vnews'}
      @config = defaults.update(config)
      @client = Mysql2::Client.new @config
    end

    def insert_feed(title, link)
      @client.query "INSERT IGNORE INTO feeds (title, link) VALUES ('#{e title}', '#{e link}')"
    end

    def insert_item(item)
      @client.query "DELETE from items WHERE guid = '#{item[:guid]}'"

      @client.query "INSERT IGNORE INTO items (guid, feed, feed_title, title, link, pub_date, author, text) 
        VALUES (
        '#{e item[:guid]}', 
        '#{e item[:feed]}', 
        '#{e item[:feed_title]}', 
        '#{e item[:title]}', 
        '#{e item[:link]}', 
        '#{item[:pub_date]}',  
        '#{e item[:author]}',  
        '#{e item[:content][:text]}'
        )"
    end

    # escape
    def e(value)
      return unless value
      @client.escape(value)
    end
  end
end
