class WhenDate < ActiveRecord::Base
  attr_accessible :date
  has_many :occasions, :inverse_of => :project
  has_many :projects, :through => :occasions
  
  has_many :occasions, :inverse_of => :document
  has_many :documents, :through => :occasions

  has_many :occasions, :inverse_of => :standard
  has_many :standards, :through => :occasions
  
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
