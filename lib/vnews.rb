require 'vnews/version'
require 'vnews/config'
require 'vnews/feed'
require 'logger'
require 'drb'

class Vnews
  
  def self.start

    ["tidy", "fmt"].each do |x|
      if `which #{x}` == ''
        puts "Before you can run Vnews, you need to install #{x}."
        exit
      end
    end

    if ! File.exists?(File.expand_path(Vnews::Config::CONFIGPATH))
      puts "Missing #{Vnews::Config::CONFIGPATH}"
      # generate this file
      puts "Generating stub config file at #{Vnews::Config::CONFIGPATH}"
      File.open(Vnews::Config::CONFIGPATH, 'w') {|f| f.write(Config.stub_config)}
      puts "Please edit this file and then run `vnews --create-db` to create your Vnews MySQL database."
      exit
    end

    if ['--version', '-v', "--help", "-h"].include?(ARGV.first)
      puts "vnews #{Vnews::VERSION}"
      puts "by Daniel Choi dhchoi@gmail.com"
      puts
      puts <<-END
---
Usage: vnews 

When you run Vnews for the first time, a .vnewsrc configuration file will be
generated in your home directory.  You must edit this file to match your MySQL
settings, and then run `vnews --create-db`.

After that you can run `vnews` to read your feeds.

Specific options:

  -u, --update           Update all feeds and folders before starting vnews
  --opml [opml file]     Import feeds from an OPML file
  --create-db            Create MySQL database configured in .vnewrc 
  -v, --version          Show version
  -h, --help             Show this message

Please visit http://danielchoi.com/software/vnews.html for more help.

--- 
        END
      exit
    end


    if ARGV.first == "--create-db"
      c = File.read(Vnews::Config::CONFIGPATH) 
      top, bottom = c.split(/^\s*$/,2)
      dbconfig = YAML::load(top)
      puts "Creating database: #{dbconfig['database']}"
      Vnews::Sql.create_db dbconfig
      puts "OK if everything went ok, you can create your feeds and folders with `vnews -u`."
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

    if ['--update', '-u'].include?(ARGV.first)
      Vnews::Config.update_folders
    end

    puts "Starting vnews #{Vnews::VERSION}"
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
