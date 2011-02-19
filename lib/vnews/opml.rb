require 'nokogiri'
require 'vnews/feed'

class Vnews
  class Opml

    CONCURRENCY = 18

    def self.fetch_feed(feed_node, folder=nil)
      xml_url = feed_node.attributes['xmlUrl'].to_s
      f = Vnews::Feed.get_feed(xml_url)
      [xml_url, f, folder]
    end

    def self.import(opml)
      sqlclient = Vnews::SQLCLIENT
      doc = Nokogiri::XML.parse(opml) 
      feeds = []
      doc.xpath('/opml/body/outline').each_slice(CONCURRENCY) do |xs|
        threads = []
        xs.each do |n|
          threads << Thread.new do 
            if n.attributes['xmlUrl']
              feeds << fetch_feed(n)
            else
              folder = n.attributes["title"].to_s
              $stderr.puts "folder: #{folder}"
              n.xpath("outline[@xmlUrl]").each do |m|
                feeds << fetch_feed(m, folder)
              end
            end
          end
        end
        threads.each {|t| t.join}
      end

      $stderr.puts "Making database records"
      feeds.each do |x|
        feed_url, f, folder = *x
        if f.nil?
          $stderr.print "\nNo feed found for #{feed_url}\n"
        else
          Vnews::SQLCLIENT.insert_feed(f[:meta][:title], feed_url, f[:meta][:link], folder)
          f[:items].each do |item|
            if item[:guid].nil? || item[:guid].strip == ''
              item[:guid] = [f[:meta][:link], f[:link]].join(":::")
            end
            Vnews::SQLCLIENT.insert_item item.merge(:feed => feed_url, :feed_title => f[:meta][:title])
            $stderr.print "."
          end
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
