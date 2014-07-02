class Project < ActiveRecord::Base
  attr_accessible :title, :refno, :fee, :scale

  has_many :addresses, :as => :addressable
  accepts_nested_attributes_for :addresses

  # has_many :countries, :through => :stakeholders

  has_many :countries, :through => :addresses

  has_many :schemes, :inverse_of => :standard
  has_many :standards, :through => :schemes

  has_many :webcrawls

  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions

  has_many :documents
  #has_many :documents, :through => :occasions, :source => :occasionable, :source_type => "Document"

  has_many :stakeholders, :inverse_of => :entity
  has_many :entities, :through => :stakeholders

  has_many :relationships, foreign_key: "main_proj_id", dependent: :destroy
  has_many :assoc_projects, through: :relationships, source: :assoc_proj 
end
