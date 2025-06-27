class PRStatus < T::Enum

  enums do

    Open    = new
    Closed  = new
    Merged  = new
    Draft   = new
    Unknown = new

  end

  STATUS_MAP = {
    "open"   => Open,
    "closed" => Closed,
    "merged" => Merged,
    "draft"  => Draft
  }

  def self.from_string(raw)

    STATUS_MAP[raw.strip.downcase] || Unknown

  end

end


class ReviewState < T::Enum

  enums do

    Approved          = new
    ChangesRequested  = new
    Reviewed          = new
    Unknown           = new

  end

  STATE_MAP = {
    "approved"           => Approved,
    "changes_requested"  => ChangesRequested,
    "reviewed"           => Reviewed
  }

  def self.from_string(raw)

    key = raw.strip.downcase.gsub(/\s+/, "_")
    STATE_MAP[key] || Unknown

  end
  
end
