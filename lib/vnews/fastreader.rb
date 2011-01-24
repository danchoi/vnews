$KCODE = 'u'
require 'jcode'
require 'rubygems' # I thought of using datamapper, but using activerecord will avoid installation
# problems for people with macs
require 'simple-rss'
require 'activerecord'
require 'action_view/helpers/date_helper.rb'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'hpricot'
$:.unshift File.dirname(__FILE__)
require 'curses'
require 'curses_extensions'
require 'feed'
require 'virtual_feed'
require 'entry'
require 'autodiscovery'
require 'character_cleaner'
require 'display'
require 'entry_controller'
require 'feeds_controller'
require 'entries_controller'
require 'curses_controller'
require 'menu_window'
require 'entry_window'
require 'command_window'
require 'menu_pager'
require 'opml'
require 'logger'
require 'fileutils'
include FileUtils
include ActionView::Helpers::DateHelper

class Fastreader
  VERSION = '1.0.8'

  attr_accessor :database_path

  def setup_database(database_path)
    unless File.exist?(database_path)
      # copy the stock starter feed database (which just contains a few feed
      # subscriptions) to the database_path
      default_db = File.dirname(__FILE__) + "/../db/default.sqlite3"
      cp(default_db, database_path)
    end
  end

  def initialize(options={})
    @curses = options[:curses] # If true it is in curses mode
    @debug = false # change if there is an option
    @environment = options[:environment] 

    if ['test', 'development'].include?(@environment)
      config = File.open(File.dirname(__FILE__) + '/../config/database.yml')
      dbconfig = YAML::load(config)[@environment]
    else
      dbconfig = {"timeout"=>5000, "adapter"=>"sqlite3"}.merge({'database' => options[:database]})
      database_path = options[:database] || ENV['HOME'] + '/fastreader.sqlite3'
      setup_database(database_path)
    end

    ActiveRecord::Base.establish_connection(dbconfig)

    # establish logging if in development mode
    if @debug
      log_file_path = File.dirname(__FILE__) + "/../log/#{@environment}.log"
      log_file = File.open(log_file_path, 'a') 
      log_file.sync = true
    else
      log_file = STDOUT
    end
    ActiveRecord::Base.logger = Logger.new(log_file)
    ActiveRecord::Base.logger.level = Logger::INFO


    # get Display object
    @display = Display.new(options)
  end

  def parse(command)
    self.instance_eval(command)
  end

  def auto_discover_and_subscribe(url)
    uri = URI.parse(url)
    feed_url = Autodiscovery.new(fetch(url)).discover
    if feed_url
      feed_url = uri.merge(feed_url).to_s
      puts "Found feed: #{feed_url}" 
      return feed_url
    else
      puts "Can't find feed for #{url}" 
      return nil
    end
  end

  def puts(string)
    if @output_block
      @output_block.call(string)
    else
      STDOUT.puts( string )
    end
  end

  def import_opml(opml)
    importer = OPMLImporter.new(opml)
    feeds = importer.feed_urls.each do | url |
      subscribe(url)
    end
  end
 
  def subscribe(feed_url, &block)

    if @output_block.nil? && (block_given? || block)
      @output_block = block
    end
    
    # try to repair the URL if possible
    unless feed_url =~ /^http:\/\//
      feed_url = "http://" + feed_url
    end

    puts "Subscribing to #{feed_url}"
    begin
      xml = fetch(feed_url)
    rescue SocketError
      puts "Error trying to load page at #{feed_url}"
      return
    end
    if xml.nil?
      puts "Can't find any resource at #{feed_url}"
      return
    end

    LOGGER.debug( "xml length: %s, feed_url: %s, block: %s" % [xml.length, feed_url, block.class])
    feed = Feed.create_feed( xml, feed_url.strip, &block )
    LOGGER.debug(feed.class)

    if feed.nil?
    
      puts "Can't find feed at #{feed_url}"
      puts "Attempting autodiscovery..."
   
      feed_url = auto_discover_and_subscribe(feed_url)
      if feed_url
        puts "Subscribing to #{feed_url}"
        xml = fetch(feed_url)

        feed = Feed.create_feed( xml, feed_url.strip, &block )
      end
    end
    feed
  end

  def update(options = {}, &block)
    if @output_block.nil? && (block_given? || block)
      @output_block = block
    end

    num = 0 
    if feed_id = options[:feed_id]

      f = Feed.find(feed_id)

      puts "Updating from #{f.feed_url}"

      result =  f.update_self( fetch(f.feed_url), options[:force], &block ) 
      num += result || 0

    else
      Feed.find(:all).each {|f| 
        
        begin 
          puts f.feed_url
          result = f.update_self( fetch(f.feed_url) )  
          num += result || 0
        rescue
          puts "Error trying to update from #{f.feed_url}! Skipping for now."
        end
       
      }
    end
    # Return the number updated 
    return num
  end

  def delete_all
    Feed.delete_all
  end

  # Shows the +number+ most recent posts across all feeds
  def most_recent(number=10)
    entries = Entry.find(:all,
                         :order => "last_updated desc",
                         :limit => number)
    @display.display_entries(entries)
  end

  def list
    # Add virtual feeds here
    feeds = Feed.feeds_list
    @display.list_feeds( feeds )
  end

  alias_method :ls, :list

  # a simple wrapper over open-uri call. Easier to mock in testing.
  def fetch(url)
    begin
      open(url).read
    rescue Timeout::Error 
      puts "-> attempt to fetch #{url} timed out"
    rescue Exception => e
      puts "-> error trying to fetch #{url}: #{$!}"
    end
  end

  def get_binding
    return binding()
  end
end


# for development
def reload
  puts "Reloading " + __FILE__ 
  load __FILE__
end

def preprocess(command_string)
  
  # Preprocessing steps to make the command a valid Ruby statement:
 
  # If the command is simply a url, then subscribe to it
  if command_string.strip =~ /^http:/
    command_string = "subscribe " + command_string
  end
  
  
  # Surround any url with quotes:
  command_string = command_string.gsub(/(http:[^\s]*)/, '"\1"')

  # default action is list feeds
  if command_string.strip == ""
    command_string = "ls"
  end
  command_string
end

# set up logging, especially for the curses part
#logfile = File.open(File.dirname(__FILE__) + "/../textfeeds_development.log", "a")
logfile = STDOUT #production mode
LOGGER = Logger.new(logfile)
LOGGER.level = Logger::INFO

database = ENV['HOME'] + '/fastreader.sqlite3'
FASTREADER_CONTROLLER = Fastreader.new(:database => database,
                          :no_links => true, 
                          :simple => true, 
                          :curses => true, 
                          :width => 60)

def run(argv)
  # If there are arguments, then interpret them directly. Otherwise, start
  # an interactive session.
  
  command = preprocess(argv.join(' '))

  # If the command is an OPML file, import the feeds in it 
  if command.strip =~ /\.opml$/
    puts "Importing OPML: #{command}"
    FASTREADER_CONTROLLER.import_opml File.read(command.strip)
  else
    eval(command, FASTREADER_CONTROLLER.get_binding)
  end

end

if __FILE__ == $0
  run(ARGV)
end

