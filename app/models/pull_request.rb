# app/models/pull_request.rb

class PullRequest < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user, optional: true

  has_many :reviews

  validates :number, presence: true
  validates :url, presence: true
end
