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
      puts "OK if everything went ok, you can start Vnews with `vnews`."
      exit
    end

    vim = ENV['VMAIL_VIM'] || 'vim'
    vimscript = File.join(File.dirname(__FILE__), "vnews.vim")
    vim_command = "#{vim} -S #{vimscript}"
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
