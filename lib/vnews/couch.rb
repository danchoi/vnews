require 'couchrest'
class Vnews
  class Couch
    DB = CouchRest.database!("http://127.0.0.1:5984/vnews")

    class << self
      def find_or_create(doc)
        if doc["_id"].nil?
          raise RestClient::ResourceNotFound
        end
        $stderr.puts "Looking up document: #{doc['_id']}"
        doc = DB.get(doc['_id']) # the url is the document id
        $stderr.puts "Found document: #{doc['_id']}"
        doc
      rescue RestClient::ResourceNotFound
        # create the doc
        response = DB.save_doc doc
        doc = DB.get response['id']
        $stderr.puts "Created document: #{doc.inspect}"
        doc
      end

      def create_or_update(doc)
        raise RestClient::ResourceNotFound if doc['_id'].nil?
        doc = DB.get(doc['_id']) # the url is the document id
        doc = doc.update(doc)
        doc.save
        doc
      rescue RestClient::ResourceNotFound
        find_or_create(doc)
      end

      def get_html_attachment(doc)
        attachment = DB.fetch_attachment(doc, 'page.html')
      rescue RestClient::ResourceNotFound
        nil
      end

      def get(feed_url)
        DB.get feed_url
      end
   


      def show_view(view, keys={})
        DB.view("vnews/#{view}")
      end

    end
  end
end

