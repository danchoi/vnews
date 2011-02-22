$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'yaml'
require 'json'
require 'rake'
require 'rake/testtask'
require 'bundler'
require 'vnews'
require 'vnews/version'

Bundler::GemHelper.install_tasks

desc "release and build and push new website"
task :push => [:release, :web]

desc "Bumps version number up one and git commits"
task :bump do
  basefile = "lib/vnews/version.rb"
  file = File.read(basefile)
  oldver = file[/VERSION = '(\d.\d.\d)'/, 1]
  newver_i = oldver.gsub(".", '').to_i + 1
  newver = ("%.3d" % newver_i).split(//).join('.')
  puts oldver
  puts newver
  puts "Bumping version: #{oldver} => #{newver}"
  newfile = file.gsub("VERSION = '#{oldver}'", "VERSION = '#{newver}'") 
  File.open(basefile, 'w') {|f| f.write newfile}
  `git commit -am 'Bump'`
end

desc "build and push website"
task :web => :build_webpage do
  puts "Building and pushing website"
  `scp website/vnews.html zoe2@instantwatcher.com:~/danielchoi.com/public/software/`
  `scp -r website/images-vnews zoe2@instantwatcher.com:~/danielchoi.com/public/software/`
  `open http://danielchoi.com/software/vnews.html`
end

desc "build webpage"
task :build_webpage do
  `cp README.markdown ../project-webpages/src/vnews.README.markdown`
  Dir.chdir "../project-webpages" do
    puts `ruby gen.rb vnews #{Vnews::VERSION}`
    `open out/vnews.html`
  end
end

