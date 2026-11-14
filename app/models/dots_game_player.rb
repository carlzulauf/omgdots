class DotsGamePlayer
  include JsonObject

  # How long a seat stays reserved for an owner who has gone quiet. A
  # connected owner is seen at least every HEARTBEAT (see PlayGameChannel), so
  # this allows several missed heartbeats: a page reload, a dropped mobile
  # connection or a briefly backgrounded tab won't cost the seat, while a seat
  # that was really abandoned frees up within a couple of minutes.
  TIMEOUT = 2.minutes
  HEARTBEAT = 20.seconds

  field :number, :integer
  field :name, :string, default: :random_name
  field :owner, :string
  field :last_seen_at, :time
  # True once the owner's last connection to the game closed. Cleared the next
  # time they are seen. The seat stays theirs until TIMEOUT runs out.
  field :away,         :boolean, default: false

  def self.build(num)
    self.new(number: num)
  end

  def own(owner)
    self.owner = owner
    seen!
  end

  def release
    self.owner = nil
    self.away = false
  end

  def owned_by?(other)
    other.present? && owner == other
  end

  # The owner is still around: keeps the seat reserved for another TIMEOUT.
  def seen!
    self.last_seen_at = Time.now
    self.away = false
  end

  # The owner's connection closed. Counts as a sighting, so the seat frees up
  # TIMEOUT after they left unless they come back.
  def left!
    self.last_seen_at = Time.now
    self.away = true
  end

  def can_be_owned_by?(other)
    return true unless owner.present?
    owner == other || last_seen_at.nil? || last_seen_at < TIMEOUT.ago
  end

  private

  def random_name
    "Player #{SecureRandom.base58 3}"
  end
end
