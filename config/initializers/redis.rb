config = YAML.load_file("config/redis.yml")[Rails.env]
redis = Redis.new(url: config["url"])

$model_redis =  if config["ns"]
                  Redis::Namespace.new(config["ns"], redis: redis)
                else
                  redis
                end
