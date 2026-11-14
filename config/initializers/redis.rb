redis = Redis.new(url: ENV["REDIS_URL"])

# Specs default to their own namespace so they never read or wipe the
# development games sharing the same Redis database.
ns = ENV.fetch("REDIS_NAMESPACE") { "omgdots-test" if Rails.env.test? }
Rails.application.config.x.redis_namespace = ns.presence
redis = Redis::Namespace.new(ns, redis: redis) if ns.present?

$model_redis = redis
