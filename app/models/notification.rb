class Notification
  include JsonObject

  # Severity levels, mildest first. The client styles each one differently.
  LEVELS = %w[success info warning error].freeze
  DEFAULT_LEVEL = "info".freeze

  field :game_id,     :string
  field :owner,       :string
  field :level,       :string, default: -> { DEFAULT_LEVEL }
  field :message,     :string
  field :created_at,  :time,   default: -> { Time.now }

  LEVELS.each do |name|
    define_method(:"#{name}?") { level == name }
  end

  def channel_key
    ["game", game_id, owner].join(":")
  end

  def as_typed_json
    {
      type: 'notification',
      data: as_json
    }
  end
end
