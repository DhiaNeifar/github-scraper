require "sorbet-runtime"

require_relative "utils"

class User
  extend T::Sig

  sig { returns(String) }
  attr_accessor :url

  sig { returns(String) }
  attr_accessor :name

  sig { returns(String) }
  attr_accessor :nickname

  sig { params(name: String).void }
  def initialize(name)

    @name = name
    @url = "#{GITHUB_URL}/#{@name}"

    get_nickname

  end

  sig { void }
  def get_nickname

    @nickname = ""
    user_document = connect(@url)
    if user_document

      user_nickname = user_document.css(CSS_CLASSES["user_nickname"])
      @nickname = user_nickname

    end

  end

end


if __FILE__ == $0

  user = User.new("DhiaNeifar")
  
end
