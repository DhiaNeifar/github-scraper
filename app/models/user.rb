# app/models/user.rb

class User < ActiveRecord::Base
  has_many :pull_requests
  has_many :reviews

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
  validates :nickname, presence: true
end
