# -*- coding: utf-8 -*-

class Metrotwitt

  def self.last_metrorotos(interval=5.minutes)
    since = [Incident.last_twitterid || 0,FailedTwitt.last_twitterid || 0].max || 0

    twitts = Twitter.search('#metroroto', :since_id => since)
    new_tweets = 0

    twitts.reverse! #Esto se hace para que guarde primero los más antiguos, y se retwitteen en orden.
    Rails.logger.info "Cargando #{twitts.size} nuevos twitts" unless twitts.size == 0

    twitts.each do |twitt|     
      Rails.logger.info("Analizando #{twitt.inspect}")
      if !(twitt.from_user == "metroroto" || Incident.find_by_twitter_id(twitt["id"]) || twitt.text.match("RT")) then
        self.parse_twitt(twitt)
        new_teets = new_teets + 1
      end
    end

    mention_twitts = Twitter.search('@metroroto', :since_id => since)
    mention_twitts.reverse! #Esto se hace para que guarde primero los más antiguos, y se retwitteen en orden.

    mention_twitts.each do |twitt|
      Rails.logger.info("Analizando #{twitt.inspect}")
      if !(twitt.from_user == "metroroto" || Incident.find_by_twitter_id(twitt["id"]) || twitt.text.match("RT")) then
        self.parse_twitt(twitt) 
        new_tweets = new_tweets + 1
      end
    end

    return new_tweets
  end

  def self.parse_twitt(twitt)

    normalized_text = twitt["text"].strip.gsub("\n","")
    text_arr=normalized_text.scan(/([^#]*)\s*#(\S*)\s#(\S*)\s?#?(\S*)\s*(.*)/).flatten
    text = normalized_text
    incident = Incident.new(:source => Incident::SOURCE[:twitter])
    # Transformamos la fecha del twitt, que viene en utc, a nuestra hora local
    incident.date = twitt["created_at"].to_time.getlocal
    incident.user = twitt["from_user"]
    incident.twitter_id = twitt["id"]
    not_found = true
    unless text_arr.blank?
      not_found = false
      # si entramos aqui, hemos encontrado una estructura standar del twitt
      # #metroroto #l1 #estrecho wadu wadus o wadus wadus #metroroto #l1 #estrecho


      text_arr = text_arr.reject{|x| x.blank?}
      #A partir del hashtag metroroto, buscamos los dos siguientes, el orden de los dos es lo mismo

      if index = text_arr.index('metroroto')
        if text_arr[index+1] &&  text_arr[index+1].match(/[lL]\d{1,2}/)
          line_number = text_arr[index+1].gsub(/[lL]/,"")
          station_string = text_arr[index+2]
          i = 3
        elsif text_arr[index+2] && text_arr[index+2] && text_arr[index+2].match(/[lL]\d{1,2}/)
          line_number = text_arr[index+2].gsub(/[lL]/,"")
          station_string = text_arr[index+1]
          i = 3
        else
          #suponemos que no hay linea y cogemos lo siguiente a metroroto para la estación
          station_string=text_arr[index+1]
          # ultimo intento para la linea
          if text.match(/[lL]\d{1,2}/)
            line_number = text.match(/[lL]\d{1,2}/).to_s.gsub(/[lL]/,"")
          else
            line_number = nil
          end
          i = 2
        end
        i.times do
          text_arr.delete_at(index)
        end
      end

      if line = Line.find_by_number(line_number)
        incident.line_id = line.id
        stations = self.search_stations(station_string,line.stations)
        unless stations.blank?
          incident.station_id = stations.all.uniq.first.id
        end
      else
        # no nos manda la linea en el twitt
        stations = self.search_stations(station_string,Station)
        unless stations.blank? || stations.size > 1
          incident.station_id = stations.first.id
          # asignamos la estacion si solo tiene una linea (sino es ambigua)
          incident.line_id = stations.first.lines.first.id if stations.first.lines.size == 1
        end

      end

      if incident.station.blank?
        # Tratamos de encontrar la estacion a la fuerza bruta
        text = text.gsub('#', '')
        Station.all.each do |station|
          next unless (text.match(station.name) || text.parameterize.match(station.nicename))
          station_string = if text.match(station.name)
            text.match(station.name).to_s
          else
            text.parameterize.match(station.nicename).to_s
          end
          if line
            stations = self.search_stations(station_string,line.stations)
            unless stations.blank?
              incident.station_id = stations.all.uniq.first.id
            end
          else
            incident.station_id = station.id
          end
          break
        end
        not_found = true if incident.station_id.blank? || incident.line_id.blank?
      end
    end

    if not_found
      #no cuadra la estructura estandar del twitt, buscamos a la fuerza bruta!!
      if incident.line_id.blank?
        if text.match(/[lL]\d{1,2}/)
          line_number = text.match(/[lL]\d{1,2}/).to_s.gsub(/[lL]/,"")
          if line = Line.find_by_number(line_number)
            incident.line_id = line.id
          end
        elsif text.match(/[linea|Linea|Línea|línea]\s?(\d{1,2})/)
          line_number = $1
          if line = Line.find_by_number(line_number)
            incident.line_id = line.id
          end
        end
      end
      if incident.station_id.blank?
        Station.all.each do |station|
          text = text.gsub('#', '')

          next unless (text.match(station.name) || text.parameterize.match(station.nicename) || text.parameterize.match(station.nicename.gsub('-','')) || text.parameterize.match(station.nicename.gsub('-de-','-')))

          station_string = if text.match(station.name)
            text.match(station.name).to_s
          elsif text.parameterize.match(station.nicename.gsub('-',''))
            text.parameterize.match(station.nicename.gsub('-','')).to_s
          else
            text.parameterize.match(station.nicename).to_s
          end
          if line
            stations = self.search_stations(station_string,line.stations)
            unless stations.blank?
              incident.station_id = stations.all.uniq.first.id
            end
          else
            incident.station_id = station.id
          end
          break
        end
      end
    end

    Rails.logger.debug("#{incident.inspect}")

    if incident.station && incident.line_id
      incident.station_string = station_string
      incident.comment = text_arr.blank? ? text.gsub(/#(.*)/,'') : text_arr.join(' ')
      incident.save! unless Incident.find_by_twitter_id(twitt["id"])
      
      # FIXME genero un FailedTwitt con :status => ok 
      fail = FailedTwitt.new(:twitter_id => incident.twitter_id,
                             :date => incident.date, :user => incident.user,
                             :station_string => station_string,
                             :twitt_body => text,
                             :status => FailedTwitt::STATUS_OK)
      if incident.line_id 
        fail.line_id = incident.line_id
      end

      fail.save!
      res = true
      
    else
      # aleprosos que no encuentra nada
      station_string ||= ""

      fail = FailedTwitt.new(:twitter_id => incident.twitter_id, 
                             :date => incident.date, :user => incident.user, 
                             :station_string => station_string, 
                             :twitt_body => text,
                             :status => FailedTwitt::STATUS_FAIL)
      if incident.line_id
        fail.line_id = incident.line_id
      end
      fail.save!
      res = false
    end
    res
  end

  def self.search_stations(name,stations)
    begin
      if !stations.find_from_twitt(name).blank?
        stations.find_from_twitt(name)
      elsif !stations.find_outspaces(name.downcase).blank?
        stations.find_outspaces(name)
      else
        nil
      end
    rescue
    end

  end

  def self.retwitt(incident)
    Rails.logger.info "Retwitt..."
    metroroto_hashtag = Settings.app.metroroto_hashtag

    user = incident.user ? "by @#{incident.user}" : ""
    with_metroroto = incident.user ? "" : "#{metroroto_hashtag}"
    begin
      str = ("#{with_metroroto} ##{incident.station.nicename.gsub("-","")} #l#{incident.line.number} #{user} #{incident.comment}" )
      Twitter.update(str[0..139]) unless Rails.env == "test"
      Rails.logger.info "TWEET: #{str[0..139]}"
    rescue Exception => e
      Rails.logger.error "No se ha podido retwittear la incidencia #{incident.id} por alguna razón: #{e}"
    end
  end


  private

  def self.connect_twitter
    oauth = Twitter::OAuth.new(OAUTH_CONSUMER_TOKEN, OAUTH_CONSUMER_SECRET_TOKEN)
    oauth.authorize_from_access(OAUTH_ACCESS_TOKEN, OAUTH_ACCESS_SECRET_TOKEN)
    return Twitter::Base.new(oauth)
  end

end

