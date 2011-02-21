require 'vnews/version'
require 'vnews/config'
require 'vnews/feed'
require 'logger'
require 'drb'

class Vnews
  
  def self.start
    puts "Starting vnews #{Vnews::VERSION}"

    # check config
    if ! Config.load_config
      puts "Missing #{Vnews::Config::CONFIGPATH}"
      # generate this file
      puts "Generating stub config file at #{Vnews::Config::CONFIGPATH}."
      File.open(Vnews::Config::CONFIGPATH, 'w') {|f| f.write(Config.stub_config)}
      puts "Please edit this file and then run `vnews --create-db` to create your Vnews MySQL database."
      exit
    end

    if ARGV.first == "--create-db"

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
