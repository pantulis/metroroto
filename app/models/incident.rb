# encoding: utf-8

class Incident < ActiveRecord::Base

  belongs_to :station
  belongs_to :line
  belongs_to :direction, :class_name => "Station"

  attr_accessible :comment, :line_id, :station_id, :direction_id, :source

  before_save :geolocate
  after_create :retwitt, :send_subscriptions
  validates_presence_of :station, :line
  
  INCIDENT_LEVELS={"inmediato" => 0,
                   "hace_un_rato" => 1,
                   "hace_mucho" => 2}

  SOURCE = { :web => 0, :twitter => 1, :android => 2}
  
  scope :last_incidents,:conditions => "date > '#{(Time.now.beginning_of_day + 5.hours).to_s(:db)}'", :order => "date DESC"
  scope :by_line, lambda { |line|
    { :conditions => "line_id = '#{line.id}'"}
  }
  scope :by_station, lambda { |station|
    { :conditions => "station_id = '#{station.id}'"}
  }

  def self.last_twitterid
    Incident.maximum(:twitter_id)
  end

  def options_for_feed
    {
      :id => id,
      :title => "Incidencia en Línea #{self.line.number} en la estación de #{self.station.name}",
      :content => comment,
      :date => date
    }
  end
  

  def status
    if date > Time.now - 15.minutes
      INCIDENT_LEVELS["inmediato"]
    elsif date > Time.now - 1.hour
      INCIDENT_LEVELS["hace_un_rato"]
    else
      INCIDENT_LEVELS["hace_mucho"]
    end
  end
  
  # Devuelve un Hash con los incidentes dados agrupados por nombre de estación
  def self.group_by_station_name(incidents)
    incidents.sort_by{|i| (-i.date.to_i)}.inject({}) do |hash, incident|
      hash[incident.station.name] ||= []
      hash[incident.station.name] << incident
      hash[incident.station.name].sort{|a,b| -(a.date <=> b.date)}
      hash
    end
  end
  
  # Devuelve un Hash con los incidentes dados agrupados por estación y línea
  def self.group_by_station_and_line(incidents)
    incidents.sort_by{|i| (-i.date.to_i)}.inject(ActiveSupport::OrderedHash.new) do |hash, incident|
      hash[incident.station] ||= {}
      hash[incident.station][incident.line] ||= []
      hash[incident.station][incident.line] << incident
      hash
    end
  end
  
  def self.group_by_line(incidents)
    incidents.sort_by{|i| (-i.date.to_i)}.inject(ActiveSupport::OrderedHash.new) do |hash, incident|
      hash[incident.line] ||= []
      hash[incident.line] << incident
      hash
    end
  end
  
  private

  def geolocate
    self.lat, self.long = if self.station && self.station.lat && self.station.long
        [self.station.lat,self.station.long]
     else
       #Geolocation.geolocate(self.station.name)
     end
  end
  
  def retwitt
    # Metrotwitt.send_later(:retwitt,self)
    Metrotwitt.retwitt(self) # if Rails.env.production?
  end
  
  def send_subscriptions
    # descomentar para activar el envio de notificaciones por correo

    #line.subscriptions.each do |subscription|
    #  Notifications.deliver_new_incident(subscription,self)
    #  Notifications.send_later(:deliver_new_incident,subscription,self)
    #end

  end

end

