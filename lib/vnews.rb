require 'vnews/version'
require 'vnews/config'
require 'vnews/feed'
require 'logger'
require 'drb'

class Vnews
  
  def self.start
    puts "Starting vnews #{Vnews::VERSION}"

    if ! File.exists?(File.expand_path(Vnews::Config::CONFIGPATH))
      puts "Missing #{Vnews::Config::CONFIGPATH}"
      # generate this file
      puts "Generating stub config file at #{Vnews::Config::CONFIGPATH}"
      File.open(Vnews::Config::CONFIGPATH, 'w') {|f| f.write(Config.stub_config)}
      puts "Please edit this file and then run `vnews --create-db` to create your Vnews MySQL database."
      exit
    end

    if ARGV.first == "--create-db"
      c = File.read(Vnews::Config::CONFIGPATH) 
      top, bottom = c.split(/^\s*$/,2)
      dbconfig = YAML::load(top)
      puts "Creating database: #{dbconfig['database']}"
      Vnews::Sql.create_db dbconfig
      puts "OK if everything went ok, you can create your feeds and folders with `vnews --update`."
      exit
    end

    if ARGV.first == "--opml"
      require 'vnews/opml'
      # opml file must be second arg
      puts "Importing OPML file #{ARGV[1]}"
      Vnews::Opml.import File.read(ARGV[1])
      # rewrite .vnewsrc config
      puts "Rewriting config file #{Vnews::Config::CONFIGPATH} to reflect changes."
      Vnews::Config.rewrite_config
      puts "Done."
    end

    if ARGV.first == "--update"
      Vnews::Config.update_folders
    end

    Vnews.sql_client # loads the config

    vim = ENV['VMAIL_VIM'] || 'vim'
    vimscript = File.join(File.dirname(__FILE__), "vnews.vim")
    vim_command = "#{vim} -S #{vimscript} "
    STDERR.puts vim_command
    system(vim_command)
    if vim == 'mvim'
      DRb.thread.join
    end
  end

end


if __FILE__ == $0
  Vnews.start
end
