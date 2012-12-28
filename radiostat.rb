# Config
stationID = 2169

# ---- do not edit below this line ----
# Dependencies
require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'json'
require 'sqlite3'
require 'nokogiri'

require 'pp'

# Constants
baseURI = 'http://www.iheart.com/live/ajax/now_playing/' + stationID.to_s +  '/?_rel=435'
url = baseURI

dbname = "stat_station_" + stationID.to_s + ".db"
if (!File.exist?(dbname)) 
	`cp database.template #{dbname}`
	puts "created database"
end
db = SQLite3::Database.new("stat_station_" + stationID.to_s + ".db")

mostrecentsongs = []
mostrecentartists = []

while true do
	json = JSON.parse(RestClient.get(url))
	content = json["html"]
	doc = Nokogiri::HTML(content)

	artists = []
	songs = []
	doc.xpath("//ul/li/p").each do |a|
		tmp = a.text.split("\n            ")
		songs.push(tmp[1])
		artists.push(tmp[2].gsub("\n          ",""))
	end

	newSong = songs - mostrecentsongs
	newArtist = artists - mostrecentartists

	if (newSong.length > 0) 
		query = "BEGIN;"
		0.upto(newSong.length-1) do |i|
			query += "insert into songs(time, artist, song) values('#{Time.now.to_i}', '#{newArtist[i].to_s.gsub("'", "")}', '#{newSong[i].to_s.gsub("'", "")}');"
			puts newArtist[i].to_s + ": " + newSong[i].to_s
		end
		query += "END;"
		#puts query
		db.execute_batch(query);
	end

	mostrecentsongs = songs
	mostrecentartists = artists

	sleep 30
#	puts "new round"
end
