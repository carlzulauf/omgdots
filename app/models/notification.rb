class Notification
  include JsonObject

  field :game_id,     :string
  field :owner,       :string
  field :level,       :string, default: -> { "error" }
  field :message,     :string
  field :created_at,  :time,   default: -> { Time.now }

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