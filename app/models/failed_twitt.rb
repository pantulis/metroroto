class FailedTwitt < ActiveRecord::Base
  belongs_to :line

  attr_accessible :twitter_id, :date, :user, :station_string, :twitt_body
  
  def self.last_twitterid
    maximum(:twitter_id)
  end

end

