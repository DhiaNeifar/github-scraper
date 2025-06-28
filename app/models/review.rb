# app/models/review.rb
class Review < ActiveRecord::Base
  belongs_to :pull_request
  belongs_to :user

  validates :state, presence: true
  validates :submitted_at, presence: true
end
