require 'nokogiri'
require 'vnews/feed'

class Vnews
  class Opml

    CONCURRENCY = 18

    def self.import(opml)
      sqlclient = Vnews.sql_client
      doc = Nokogiri::XML.parse(opml) 
      feeds = []
      doc.xpath('/opml/body/outline').each_slice(CONCURRENCY) do |xs|
        threads = []
        xs.each do |n|
          threads << Thread.new do 
            if n.attributes['xmlUrl']
              feeds << Vnews::Feed.fetch_feed(n.attributes['xmlUrl'].to_s)
            else
              folder = n.attributes["title"].to_s
              $stderr.puts "Found folder: #{folder}"
              n.xpath("outline[@xmlUrl]").each do |m|
                feeds << Vnews::Feed.fetch_feed(m.attributes['xmlUrl'].to_s, folder)
              end
            end
          end
        end
        threads.each {|t| t.join}
      end

      $stderr.puts "Making database records"
      feeds.each do |x|
        feed_url, f, folder = *x
        folder ||= "Misc"
        if f.nil?
          $stderr.print "\nNo feed found for #{feed_url}\n"
        else
          Vnews::Feed.save_feed(feed_url, f, folder)
        end
      end
      $stderr.puts "\nDone."

    end
  end
end

if __FILE__ == $0
  opml = STDIN.read
  Vnews::Opml.import(opml)
end
