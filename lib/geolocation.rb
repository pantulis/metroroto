# encoding: utf-8

require 'iconv'

class Geolocation
  def self.geolocate(station="")
    puts "Buscando lat long de la estacion #{station}"
    ic = Iconv.new('US-ASCII//IGNORE', 'UTF-8')
    utf8location = ic.iconv(station)
    
    res = Geokit::Geocoders::GoogleGeocoder.geocode("#{utf8location} metro madrid")
    puts res.lat
    puts res.lng  
    return res.lat, res.lng
  end
  
end
