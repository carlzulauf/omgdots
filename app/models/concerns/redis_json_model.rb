module RedisJsonModel
  extend ActiveSupport::Concern
  include JsonObject

  mattr_accessor(:redis) { $model_redis }

  included do
    cattr_accessor(:redis, instance_reader: true) { RedisJsonModel.redis }

    field :id,         :string, default: :generate_id
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
    ts = Time.now
    self.created_at ||= ts
    self.updated_at   = ts
    redis.set(key, to_json)
  end

  def with_lock
    redis.watch key
    reload
    redis.multi do
      save if yield
    end
  end

  def reload
    @object = self.class.find(id).object
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

  class_methods do
    def key_for(id)
      "#{model_name.singular}:#{id}"
    end

    def exists?(id)
      redis.exists key_for(id)
    end

    def find(id)
      json = redis.get(key_for id)
      self.new(JSON.parse(json)) if json
    end

    def find_or_create(id)
      find(id) || self.new(id: id).tap(&:save)
    end

    def create(attrs)
      self.new(attrs).tap(&:save)
    end
  end
end
