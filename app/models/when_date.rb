class WhenDate < ActiveRecord::Base
  attr_accessible :date
  
  has_many :documents, :through => :occasions, :source => :occasionable, :source_type => "Document"
  has_many :standards, :through => :occasions, :source => :occasionable, :source_type => "Standard"
  has_many :addresses, :through => :occasions, :source => :occasionable, :source_type => "Address"
  has_many :stakeholders, :through => :occasions, :source => :occasionable, :source_type => "Stakeholder"
  has_many :schemes, :through => :occasions, :source => :occasionable, :source_type => "Scheme"

  has_many :occasions, :inverse_of => :project
  has_many :projects, :through => :occasions

  has_many :occasions, :inverse_of => :user, :foreign_key => :created_by_user_id
  has_many :users, :through => :occasions, :foreign_key => :created_by_user_id
  
  has_many :occasions, :inverse_of => :entity
  has_many :entities, :through => :occasions

  require 'chronic'

  def date_string
    date.to_s(:just_date)
  end

  def date_string=(value)
    self.date = Chronic.parse(value)
	rescue ArgumentError
  	@date_invalid = true
  end

  def validate
    errors.add(:date, "is invalid") if @date_invalid
  end
end
