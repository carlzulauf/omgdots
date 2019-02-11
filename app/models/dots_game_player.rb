class DotsGamePlayer
  include JsonObject

  field :name, :string, default: :random_name
  field :owner, :string
  field :last_seen_at, :time

  def self.build
    self.new
  end

  private

  def random_name
    "Player #{SecureRandom.base58 3}"
  end
end
