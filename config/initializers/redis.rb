config = YAML.load_file("config/redis.yml")[Rails.env]

redis = Redis.new(url: config["url"])
redis = Redis::Namespace.new(config["ns"], redis: redis) if config["ns"]

$model_redis = redis
