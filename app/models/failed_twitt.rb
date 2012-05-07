class FailedTwitt < ActiveRecord::Base
  belongs_to :line

  STATUS_OK   = 1
  STATUS_FAIL = 0

  attr_accessible :twitter_id, :date, :user, :station_string, :twitt_body, :status

  scope :failed, :conditions => "status = #{FailedTwitt::STATUS_FAIL}"
  scope :ok, :conditions => "status = #{FailedTwitt::STATUS_OK}"

  def self.last_twitterid
    maximum(:twitter_id)
  end

end

