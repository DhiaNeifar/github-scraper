require "sorbet-runtime"


class Repository
  extend T::Sig

  sig { returns(String) }
  attr_accessor :organization

  sig { returns(String) }
  attr_accessor :name

  sig { returns(Boolean) }
  attr_accessor :is_public

  sig { returns(Boolean) }
  attr_accessor :is_archived

  sig { params(organization: String, repository_name: String).void }
  def initialize(organization, repository_name)
    @organization = organization
    @name = repository_name

    @repository_url = "#{GITHUB_URL}/#{@organization}/#{@name}"
    repository_document = test_connection(@repository_url)
    css_class_archive = ".flash.flash-warn.flash-full.border-top-0.text-center.text-bold.py-2"
    variable = repository_document.css(css_class_archive)
    puts variable
    @is_public = nil
    @is_archived = nil
  end


  sig { return Repository }
  def par

  end
end
