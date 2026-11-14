module ChangelogHelper
  # A plain path rather than the named route helper, which only exists when
  # the development routes are drawn (the request spec draws its own).
  def changelog_media_src(file)
    "/changelog/media/#{ERB::Util.url_encode(File.basename(file.to_s))}"
  end

  # Escapes changelog text and turns `backticked` spans into <code>.
  def changelog_text(text)
    parts = text.to_s.split(/`([^`\n]+)`/)
    safe_join(parts.each_with_index.map { |part, i| i.odd? ? tag.code(part) : part })
  end
end
