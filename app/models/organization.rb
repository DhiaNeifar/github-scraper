# app/models/organization.rb

class Organization < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true

  has_many :repositories
end
