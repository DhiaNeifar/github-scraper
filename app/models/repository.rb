class Repository < ActiveRecord::Base
  belongs_to :organization

  validates :name, presence: true
  validates :url, presence: true
  validates :is_public, inclusion: { in: [true, false] }
  validates :is_archived, inclusion: { in: [true, false] }
end
