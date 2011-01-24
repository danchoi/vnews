class Feed < ActiveRecord::Base
  serialize :urls
  serialize :authors
  serialize :skip_hours
  serialize :skip_days
  has_many :entries, 
    :order => "date_published desc, created_at desc, id desc", 
    :dependent => :destroy # TODO make sure the user can override this
  
  # Takes a url an creates a feed object and subscription
  def self.create_feed(xml, feed_url, &block)

    if block_given? || block
      @output_block = block
    end

    feed = FeedNormalizer::FeedNormalizer.parse(xml, :force_parser => FeedNormalizer::SimpleRssParser)
    return nil unless feed.is_a?(FeedNormalizer::Feed)

    puts "Looking for #{feed_url} in the database"
    if found_feed=Feed.find_by_feed_url(feed_url)

      puts "Feed already exists"

      # Update it
      puts found_feed.import_entries(feed)

      return found_feed

    end
    puts "Not found. Subscribing."

    new_feed = Feed.create(:feed_id => feed.id,
                :title => feed.title.strip,
                # It's very importannt that this is feed_url and not feed.url:
                :feed_url => feed_url.strip, 
                :urls => feed.urls.map {|x| x.strip},
                :parser => feed.parser,
                :last_updated => feed.last_updated || Time.now,
                :authors => feed.authors,
                :copyright => feed.copyright,
                :image => feed.image,
                :generator => feed.generator,
                :ttl => feed.ttl,
                :skip_hours => feed.skip_hours,
                :skip_days => feed.skip_days)
    # create entries
    new_feed.import_entries(feed)
    new_feed
  end

  def self.feeds_list
    feeds = []
    feeds = feeds + Feed.find(:all, :order => "title asc")

    flagged_entries = VirtualFeed.new
    flagged_entries.title = "Flagged Entries"
    flagged_entries.finder_params = {:conditions => "flagged is not null", :order => "flagged desc"}

    feeds << flagged_entries 

    all_entries = VirtualFeed.new
    all_entries.title = "All Entries"
    all_entries.finder_params = {:order => "id desc"}

    feeds << all_entries 

    feeds
  end

  def puts(string)
    if @output_block
      @output_block.call(string)
    else
      STDOUT.puts( string )
    end
  end
  
  # Takes a FeedNormalizer::Feed object
  def import_entries(feed)

    num_new_items = 0

    # Reverse the entries because they are most recent first.
    feed.entries.reverse.each do |entry| 
      # Check if the entry already exists
      # puts "Looking for existing entry with id #{entry.id}"
      if (existing_entry = self.entries.find(:first, 
                                             :conditions => ["entry_id = ?", entry.id ? entry.id : entry.url ]))

        # Do nothing if the entry has not been updated
        if existing_entry.last_updated == entry.last_updated
          #puts "Skipping #{entry.title}. Already exists."
          next

        # The entry has been updated, so update it.
        else
          puts "Updating #{entry.title}"
          update_entry(existing_entry, entry)
          next 
        end

      else 
        puts "Importing #{entry.title}"
        num_new_items += 1
        import_entry(entry)
      end
    end

    num_new_items
  end

  # Takes a FeedNormalizer::Entry object
  def import_entry(entry)
    unless entry.id || entry.url 
      puts "Skipping #{entry.title}. Bad item. No entry id or url detected."
      return 
    end   

    self.entries.create(:title => entry.title,
                        :description => entry.description,
                        :content => entry.content,
                        :categories => entry.categories,
                        :date_published => entry.date_published || entry.last_updated,
                        :url => entry.url,
                        :urls => entry.urls,
                        # If the entry.id is nil, use the entry.url (this
                        # happens for some reason on Slashdot and maybe other
                        # websites.
                        :entry_id => entry.id ? entry.id.strip : entry.url.strip, 
                        :authors => entry.authors,
                        :copyright => entry.copyright, 
                        # Apparently entry.last_updated is a Time object
                        :last_updated => entry.last_updated ? entry.last_updated.to_datetime : nil)
  end

  # The old entry is ActiveRecord. The new one is a FeedNormalizer::Entry
  def update_entry(old, new)
    old.update_attributes(:title => new.title,
                        :description => new.description,
                        :content => new.content,
                        :categories => new.categories,
                        :date_published => new.date_published,
                        :url => new.url,
                        :urls => new.urls,
                        :authors => new.authors,
                        :copyright => new.copyright, 
                        # Apparently new.last_updated is a Time object
                        :last_updated => new.last_updated ? new.last_updated.to_datetime : nil)

  end


  # This field is used to determine whether an entry in the feed is new, in
  # which case it is colored in a special way
  def previously_updated_at
    unless self['previously_updated_at']
      return self['created_at']
    end
    self['previously_updated_at']
  end

  # Takes a new version of the feed xml
  # Can't call this "update" because that's an important ActiveRecord method
  # The block is the output method. If no block is given it a standard block is
  # created that just outputs to stdout.
  # +puts+ calls the output lambda when it's available; otherwise it prints to
  # STDOUT.

  def too_soon_to_update?
    self.updated_at.to_time > (Time.now - 3600)
  end

  def update_self(xml, force=false, &block)
    num_new_items = 0
    if block_given?
      @output_block = block
    end

    unless force
      # To be courteous, don't update feeds that have been downloaded in the last
      # hour.
      if too_soon_to_update?
        puts "-> skipping. last update was with the last hour."
        return
      end
    end

    # :updated_at is used for this program's internal bookkeeping, and tracks when the feed was last
    # accessed. :last_updated is the property of the feed.
    
    begin 

      # We're forcing the SimpleRssParser because the other one led to errors with DaringFireball's Atom feed.
      new_feed_content = FeedNormalizer::FeedNormalizer.parse(xml, :force_parser => FeedNormalizer::SimpleRssParser)
      # Trye another parser
      unless new_feed_content.is_a?(FeedNormalizer::Feed)
        puts "Failed to update #{self.title}. Try again later."
        LOGGER.debug("FAILED TO UPDATE #{self.title}")
        LOGGER.debug(xml)
        return
      end

      # At this point we're definitely updating the feed.

      # create entries
      # The import_entries method should silently skip entries that already exist
      num_new_items += import_entries(new_feed_content)
      
      # This updates the last_updated timestamp
      self.last_updated = Time.now 

      self.save
      puts "-> %s new items found." % num_new_items
    rescue
      puts "-> There was an error updating the feed #{self.feed_url}."
      raise
    end
    return num_new_items 
  end
end

