require "sorbet-runtime"

require_relative "utils"


class Organization
  extend T::Sig

  sig { returns(String) }
  attr_accessor :url

  sig { returns(String) }
  attr_accessor :name


  sig { params(name: String).void }
  def initialize(name)
    @url = "#{GITHUB_URL}/orgs/#{name}"
    @name = name
  end
end
