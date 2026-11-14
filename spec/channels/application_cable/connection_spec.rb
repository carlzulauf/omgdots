require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:session_key) { Rails.application.config.session_options[:key] }

  it "is identified by the session's uid" do
    cookies.encrypted[session_key] = { value: { "uid" => "alice" } }

    connect

    expect(connection.uid).to eq("alice")
  end

  # Players still hold cookies from the Rails 7.2 app, which ran without
  # `load_defaults`: AES-256-CBC + HMAC-SHA1, keys derived through SHA1, and a
  # bare JSON payload (no purpose metadata). config/initializers/cookie_rotator
  # must let the cable connection read them, or live games lock everyone out.
  context "with a session cookie from before the Rails 8 upgrade" do
    let(:old_cookie) do
      keys = ActiveSupport::KeyGenerator.new(
        Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
      )
      encryptor = ActiveSupport::MessageEncryptor.new(
        keys.generate_key("encrypted cookie", 32), keys.generate_key("signed encrypted cookie"),
        cipher: "aes-256-cbc", digest: "SHA1", serializer: JSON
      )
      encryptor.encrypt_and_sign({ "session_id" => "abc123", "uid" => "legacy-bob" })
    end

    # The test case's own jar fakes encryption, so hand the connection a real
    # one, built the way ActionCable::Connection::Base#request builds it.
    def cookies
      @real_cookies ||= ActionDispatch::Request.new(
        Rails.application.env_config.merge(
          Rack::MockRequest.env_for("/cable", "HTTP_COOKIE" => "#{session_key}=#{CGI.escape(old_cookie)}")
        )
      ).cookie_jar
    end

    it "is identified by the uid in it" do
      connect

      expect(connection.uid).to eq("legacy-bob")
    end
  end

  it "rejects a connection without a session uid" do
    expect { connect }.to have_rejected_connection
  end

  it "ignores a uid passed in the URL" do
    expect { connect "/cable?user=alice" }.to have_rejected_connection
  end
end
