require 'mechanize'
require 'pry'

BASE_URL = "https://egghead.io"
agent = Mechanize.new
agent.user_agent_alias = 'iPhone'

EMAIL = "youremail@example.com"
PASSWORD = "PASSWORD"

def say(msg, important = false)
  puts "" if important
  puts " #{important ? '-->' : '-'} " + msg
end

def exit_with(msg)
  say msg
  say "...exiting..."
  exit
end

def next?

end

agent.get(BASE_URL + "/users/sign_in") do |page|
  say "Signing in ..."
  
  my_page = page.form_with(:action => "/users/sign_in") do |f|
    f.field_with(:id => "user_email").value = EMAIL
    f.field_with(:id => "user_password").value = PASSWORD
  end.submit

  exit_with("Couldn't log in") if my_page.title =~ /Login/

  say "Going to react lessons"
  react_page = agent.click(my_page.link_with(:href => /technologies\/react/))

  say "Filtering lessons by oldest first"
  react_page = agent.click(react_page.link_with(:text => /Oldest first/))

  page_numbers = agent.page.parser.css('ul.pagination a').map(&:text)
  page_numbers = page_numbers.map(&:to_i).uniq - [0]

  page_numbers.each do |page_number| 
    agent.page.parser.css('ul.series-lessons-list > a').each do |lesson|
      lesson_title = lesson.css('h5').text rescue nil

      lesson_title ? say("Found lesson: " + lesson_title, true) : next
      dir_name = lesson_title.gsub( /\W/, '_')

      if Dir.exists?(dir_name)
        say "#{dir_name} already exists, skipping..."
        next
      else
        say "creating dir: " + dir_name
        Dir.mkdir(dir_name)
      end

      Dir.chdir(dir_name)
      say "in dir: " + `pwd`

      url = lesson.attributes["href"].value

      if url
        download_page = agent.get(BASE_URL + url)
        say "downloading files at: " + download_page.title
        download_page.links_with(id: /clicker1/).each do |link|
          url = link.href 
          say "downloading... " + url
          agent.get(url).save_as "#{download_page.title}.mp4"
        end
      else
        next
      end
      
      Dir.chdir('..')
      say "back out: " + `pwd`
    end

    say "Going to page #{page_number}"
    react_page = agent.click(react_page.link_with(text: "#{page_number}"))
    binding.pry
    
  end
end

