require 'rubygems'
require 'mechanize'
require 'pry'

DOWNLOAD_BATCH_SIZE = 1
EMAIL = 'email@example.com'
PASSWORD = 'PASSWORD'

def say(msg, important = false)
  puts "" if important
  puts " #{important ? '-->' : '-'} " + msg
end

def exit_with(msg)
  say msg
  say "...exiting..."
  exit
end


say "Logging in..."

def login
  a = Mechanize.new

  content_page = a.get('https://rubytapas.dpdcart.com/subscriber/content') do |page|
    page.form_with(id: 'login-form') do |f|
      f.username = EMAIL
      f.password = PASSWORD
    end
    
  end

  content_page.click_button

  say "Got page: " + content_page.uri.to_s
  exit_with("Couldn't log in") if content_page.title =~ /Login/
end

login 

count = 0
while count < 1
  binding.pry
  a.page.parser.css('div.blog-entry').each do |entry|
    entry_title = entry.css('h3').first.content rescue nil

    entry_title ? say("Found entry: " + entry_title, true) : next

    dir_name = entry_title.gsub( /\W/, '_')

    if Dir.exists?(dir_name)
      say "#{dir_name} already exists, skipping..."
      next
    else
      say "creating dir: " + dir_name
      Dir.mkdir(dir_name)
    end

    Dir.chdir(dir_name)
    say "in dir: " + `pwd`

    url = entry.css('div.content-post-meta a').first['href'] rescue nil

    if url
      download_page = a.get(url)
      say "downloading files at: " + download_page.title
      download_page.links_with(:href => /subscriber\/download/).each do |link|
        say "downloading... " + link.inspect
        file = a.click(link)
        File.open(file.filename, 'w+b') do |f|
          f << file.body.strip
        end
      end
    else
      next
    end

    Dir.chdir('..')
    say "back out: " + `pwd`

    exit if count >= DOWNLOAD_BATCH_SIZE
    count += 1
  end
end