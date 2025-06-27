require "sorbet-runtime"


require_relative "User"
require_relative "Enums"


class Review
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_accessor :reviewer

  sig { returns(ReviewState) }
  attr_accessor :state

  sig { returns(Time) }
  attr_accessor :submitted_at

  sig { params(reviewer: User, state: ReviewState, submitted_at: Time).void }
  def initialize(reviewer, state, submitted_at)

    @reviewer = reviewer
    @state = state
    @submitted_at = submitted_at
    
  end
end
