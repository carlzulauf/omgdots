class DotsGamePlayer
  include JsonObject

  TIMEOUT = 1.minute

  field :number, :integer
  field :name, :string, default: :random_name
  field :owner, :string
  field :last_seen_at, :time

  def self.build(num)
    self.new(number: num)
  end

  def own(owner)
    self.owner = owner
    self.last_seen_at = Time.now
  end

  def can_by_owned_by?(other)
    return true unless owner.present?
    owner == other || last_seen_at < TIMEOUT.ago
  end

  private

  def random_name
    "Player #{SecureRandom.base58 3}"
  end
end
