require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:session_key) { Rails.application.config.session_options[:key] }

  it "is identified by the session's uid" do
    cookies.encrypted[session_key] = { value: { "uid" => "alice" } }

    connect

    expect(connection.uid).to eq("alice")
  end

  it "rejects a connection without a session uid" do
    expect { connect }.to have_rejected_connection
  end

  it "ignores a uid passed in the URL" do
    expect { connect "/cable?user=alice" }.to have_rejected_connection
  end
end
