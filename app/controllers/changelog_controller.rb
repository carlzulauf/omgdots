# Development-only change log (see doc/changelog/README.md). The routes are
# only drawn in development; the guard below is a backstop.
class ChangelogController < ApplicationController
  before_action { head :not_found unless Rails.env.development? }
  layout "changelog"

  def show
    @changelog = Changelog.load
  end

  def media
    name = File.basename(params[:filename].to_s)
    path = Changelog::MEDIA_DIR.join(name)
    return head :not_found if name.start_with?(".") || !File.file?(path)

    send_file path, disposition: :inline, type: Rack::Mime.mime_type(File.extname(name))
  end
end
