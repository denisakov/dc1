class Document < ActiveRecord::Base
  attr_accessible :link, :version, :short_title, :title, :process_type, :project_id
  belongs_to :project
  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions

require 'chronic'

  def date_string
    date.to_s(:date)
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
