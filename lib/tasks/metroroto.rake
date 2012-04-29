namespace :metroroto do
  desc "Busca los ultimos twitts"
  task :search => :environment do
    Metrotwitt.last_metrorotos
  end

  desc "Carga las estaciones de metro y su localizacion"
  task :load_stations => :environment do
    Metroparser.load_stations
    Station.update_wrong_stations
  end
end

