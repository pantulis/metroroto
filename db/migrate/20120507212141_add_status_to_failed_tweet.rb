class AddStatusToFailedTweet < ActiveRecord::Migration
  def change
    change_table :failed_twitts do |t|
      t.integer :status, :default => 0
    end
  end
end
