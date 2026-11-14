module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # The player's session uid, read from the same encrypted session cookie
    # that GamesController#show fills in (the cookie rotator lets it read
    # sessions written before the Rails 8 upgrade too). Identity comes only
    # from here, never from subscription params, so a seat owner's uid showing
    # up in a broadcast can't be used to act as them.
    identified_by :uid

    def connect
      self.uid = session_uid || reject_unauthorized_connection
    end

    private

    def session_uid
      cookies.encrypted[Rails.application.config.session_options[:key]]&.dig("uid").presence
    end
  end
end
