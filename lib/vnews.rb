require 'vnews/version'
require 'vnews/aggregator'
require 'logger'
require 'drb'


class Vnews
  
  class << self

    # starts the drb outline_server
    def start
      puts "starting vnews #{Vnews::VERSION}"
      vim = ENV['VMAIL_VIM'] || 'vim'

      logfile = (vim == 'mvim') ? STDERR : 'vnews.log'
      data = ARGV.first ? YAML::load(File.read(ARGV.first)) : {}

      config = {:logfile => logfile, :data => data}
      drb_uri = begin 
                  Vnews::Aggregator.start_drb_server config
                rescue 
                  puts "Failure:", $!
                  exit(1)
                end
      outline = DRbObject.new_with_uri drb_uri

      vimscript = File.expand_path("../../vnews.vim", __FILE__)
      # todo, change buffer file to match file basename of yaml vnews file
      buffer_file = "buffer.txt"
      vim_command = "DRB_URI='#{drb_uri}' #{vim} -S #{vimscript} #{buffer_file}"

      File.open(buffer_file, "w") do |file|
        # file.puts outline
      end
      STDERR.puts vim_command

      system(vim_command)

      if vim == 'mvim'
        DRb.thread.join
      end

      #File.delete(buffer_file)
      exit
    end

  end
end


if __FILE__ == $0
  Vnews.start
end
