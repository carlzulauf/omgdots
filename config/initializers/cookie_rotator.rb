# Keep reading session cookies written before the Rails 8 upgrade.
#
# The app used to run without `load_defaults`, so its encrypted cookies were
# AES-256-CBC with keys derived through SHA1. `load_defaults` 5.2+ switched to
# AES-256-GCM and 7.0+ derives keys through SHA256. Without this rotation every
# player's session (and so ownership of their seat in a running game) would
# be dropped on deploy. Old cookies are re-written in the new format the next
# time the session changes, so this can go once old sessions have aged out.
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    key_generator = ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    cipher = "aes-256-cbc"
    secret = key_generator.generate_key("encrypted cookie", ActiveSupport::MessageEncryptor.key_len(cipher))
    sign_secret = key_generator.generate_key("signed encrypted cookie")

    cookies.rotate :encrypted, secret, sign_secret, cipher: cipher, digest: "SHA1"
  end
end
