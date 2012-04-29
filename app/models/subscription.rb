class Subscription < ActiveRecord::Base
   belongs_to :line
   validates_uniqueness_of :email, :scope => :line_id 
   attr_accessible :email, :line_id
   
   before_create :set_verification_token
   
   def set_verification_token
     self.verification_token = Digest::MD5.hexdigest((self.email ? self.email : "") + "metroroto" + %w(wadus larubyroom esequevayquedice osodiooo).sample)
   end
   
end
