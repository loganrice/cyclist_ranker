require 'rubygems'
require 'mechanize'

DOWNLOAD_BATCH_SIZE = 10
EMAIL = ''
PASSWORD = ''

def say(msg, important = false)
  puts "" if important
  puts " #{important ? '-->' : '-'} " + msg
end

def exit_with(msg)
  say msg
  say "...exiting..."
  exit
end

a = Mechanize.new

say "Logging in..."

a.get('https://rubytapas.dpdcart.com/subscriber/content') do |page|
  content_page = page.form_with(id: 'login-form') do |f|
    f.username = EMAIL
    f.password = PASSWORD
  end.click_button

  say "Got page: " + content_page.uri.to_s

  exit_with("Couldn't log in") if content_page.title =~ /Login/

  count = 0
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