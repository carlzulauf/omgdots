unless File.exist?(Rails.root.join(".env"))
  File.write Rails.root.join(".env"), <<~CONFIG
    SECRET_KEY_BASE=#{SecureRandom.hex(32)}
    PORT=3222
  CONFIG
  Dotenv.load
end
