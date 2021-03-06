#ruby_scrapper/cyclist_ranker.rb
require 'mechanize'
require 'pry'
require 'pp'

BASE_URL = "http://www.procyclingstats.com/"

def say(message)
  puts "- " + message 
end

agent = Mechanize.new

say "Ready for web scrapping" if agent.class == Mechanize

rankings_page = agent.get(BASE_URL + "rankings.php")

rider = agent.page.parser.css("table#list9 td > a").first.text

rider_url = agent.page.parser.css("table#list9 td > a").first["href"]

binding.pry
rider_page = agent.get(BASE_URL + rider_url)

teams = rider_page.links_with(href: %r{team/} ).map(&:text)

teams = rider_page.links_with(href: %r{team/} ).map do |link|
  link.text
end



say "#{rider} has been on at least #{teams.count} teams"

say "unique teams #{teams.uniq}"
say "#{rider} is currently on the #{teams.first} team" 