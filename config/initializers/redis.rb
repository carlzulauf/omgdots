redis = Redis.new(url: ENV["REDIS_URL"])

ns = ENV["REDIS_NAMESPACE"]
redis = Redis::Namespace.new(ns, redis: redis) if ns.present?

$model_redis = redis
