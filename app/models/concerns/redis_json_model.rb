module RedisJsonModel
  class RecordMissing < StandardError; end

  # Raised when an optimistic update keeps losing the race: every attempt saw
  # the record change between reading it and writing it back.
  class ConflictError < StandardError; end

  # How many times #with_lock re-reads and re-applies its block when a
  # concurrent write invalidates the WATCH before giving up.
  LOCK_ATTEMPTS = 5

  # Records expire this long after their last save. Visiting any URL under
  # /games creates a game, so abandoned ones must not pile up forever.
  TTL = 30.days

  extend ActiveSupport::Concern
  include JsonObject

  mattr_accessor(:redis) { $model_redis }

  included do
    cattr_accessor(:redis, instance_reader: true) { RedisJsonModel.redis }

    field :id,         :string
    field :created_at, :time
    field :updated_at, :time

    alias_method :to_gid_param, :id
    alias_method :to_param, :id
  end

  def persisted?
    created_at.present?
  end

  def key
    self.class.key_for(id)
  end

  def save
    stamp_for_save
    redis.set(key, to_json, ex: TTL.to_i)
  end

  # Optimistic read-modify-write. Each attempt WATCHes the key, reloads the
  # record, yields it, and, if the block returns truthy, writes it back in a
  # MULTI/EXEC. EXEC aborts when another client wrote the key after the WATCH;
  # then the attempt starts over from a fresh read, so the block must be safe
  # to run more than once. Returns true when saved, false when the block
  # declined. Raises ConflictError after `attempts` aborted transactions.
  #
  # The WATCH block holds the client's lock, so other threads sharing this
  # connection wait their turn instead of interleaving commands with ours.
  def with_lock(attempts: LOCK_ATTEMPTS)
    attempts.times do
      outcome = redis.watch(key) do
        reload
        if yield(self)
          stamp_for_save
          json = to_json
          # nil when EXEC aborted because the watched key changed.
          redis.multi { |tx| tx.set(key, json, ex: TTL.to_i) } ? :saved : :conflict
        else
          redis.unwatch
          :declined
        end
      end
      return outcome == :saved unless outcome == :conflict
    end
    raise ConflictError, "#{key} kept changing; gave up after #{attempts} attempts"
  end

  def reload
    @object = self.class.find!(id).object
    self
  end

  def destroy
    redis.del key
    self
  end

  def generate_id
    loop do
      id = SecureRandom.base58(8)
      return id unless self.class.exists?(id)
    end
  end

  private

  def stamp_for_save
    ts = Time.now
    self.id = generate_id unless id.present?
    self.created_at ||= ts
    self.updated_at   = ts
  end

  class_methods do
    def key_for(id)
      "#{model_name.singular}:#{id}"
    end

    def exists?(id)
      redis.exists? key_for(id)
    end

    # Loads the record, yields it for changes, and saves it atomically,
    # retrying from a fresh read if another write lands in between (see
    # #with_lock). The block always saves; it may run more than once.
    def for_update(id)
      new(id: id).tap do |obj|
        obj.with_lock do
          yield obj
          true
        end
      end
    end

    def all
      block = -> (key) { self.new(JSON.parse(redis.get(key))) }
      redis.keys("#{model_name.singular}:*").map(&block)
    end

    def find(id)
      json = redis.get(key_for id)
      self.new(JSON.parse(json)) if json
    end

    def find!(id)
      find(id).tap do |game|
        raise RecordMissing, "Record '#{id}' does not exist" unless game
      end
    end

    def find_or_create(id)
      return create unless id.present?
      find(id) || self.new(id: id).tap(&:save)
    end

    def create(attrs = {})
      self.new(attrs).tap(&:save)
    end
  end
end
