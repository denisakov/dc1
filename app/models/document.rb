class Document < ActiveRecord::Base
  attr_accessible :issue_date, :link, :version, :project_id, :title, :issue_date_string, :process_type
  belongs_to :project

  require 'chronic'

  def issue_date_string
    issue_date.to_s(:doc_date)
  end

  def issue_date_string=(value)
    self.issue_date = Chronic.parse(value)
	rescue ArgumentError
	@issue_date_invalid = true
  end

  def validate
  errors.add(:issue_date, "is invalid") if @dissue_date_invalid
  end
end
