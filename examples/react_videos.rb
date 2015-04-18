require 'mechanize'
require 'pry'

BASE_URL = "https://egghead.io"
EMAIL = "loganrice72@gmail.com"
PASSWORD = "meetup"

agent = Mechanize.new
agent.user_agent_alias = 'iPhone'

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

  say "Counting page numbers"
  pagination_text = agent.page.parser.css('ul.pagination a').map(&:text)
  page_numbers = pagination_text.map(&:to_i).uniq - [0]

  video_counter = 1
  page_number = 1

  while page_number <= page_numbers.count + 1 
    agent.page.parser.css('ul.series-lessons-list > a').each do |lesson|
      lesson_title = lesson.css('h5').text rescue nil

      lesson_title ? say("Found lesson: " + lesson_title, true) : next
      file_name = lesson_title.gsub( /\W/, '_')

      if File.exists?("#{file_name}.mp4")
        say "#{file_name} already exists, skipping..."
        next
      else
        say "creating file: " + file_name + "in dir: " + `pwd`
      end

      url = lesson.attributes["href"].value

      if url
        download_page = agent.get(BASE_URL + url)
        say "downloading file at: " + download_page.title
        link = download_page.link_with(id: /clicker1/)
        agent.get(link.href).save_as file_name + ".mp4" 
      else
        next
      end
    end

    say "Going to page #{page_number}"
    page_number += 1
    binding.pry if page_number == 4
    react_page = agent.click(react_page.link_with(text: "#{page_number}")) rescue nil 
  end

  say "Download complete"
end

