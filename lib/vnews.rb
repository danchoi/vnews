require 'vnews/version'
require 'vnews/feed'
require 'logger'
require 'drb'

class Vnews
  class << self

    def start
      puts "starting vnews #{Vnews::VERSION}"
      vim = ENV['VMAIL_VIM'] || 'vim'

      # TODO load a feed list file somewhere

      vimscript = File.expand_path("../../vnews.vim", __FILE__)

      # TODO buffer file should be feed list
      buffer_file = "buffer.txt"
      File.open(buffer_file, "w") do |file|
        # file.puts outline
      end

      vim_command = "#{vim} -S #{vimscript} #{buffer_file}"

      STDERR.puts vim_command

      system(vim_command)

      if vim == 'mvim'
        DRb.thread.join
      end
    end

  end
end


if __FILE__ == $0
  Vnews.start
end
