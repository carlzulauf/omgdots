require "yaml"

# Reads doc/changelog/changelog.yml for the development-only /changelog page.
class Changelog
  ROOT = Rails.root.join("doc", "changelog")
  DEFAULT_PATH = ROOT.join("changelog.yml")
  MEDIA_DIR = ROOT.join("media")

  STATUSES = %w[in_progress queued blocked done dropped].freeze
  QUEUE_ORDER = { "in_progress" => 0, "queued" => 1, "blocked" => 2 }.freeze
  VIDEO_EXTENSIONS = %w[.webm .mp4].freeze

  Media = Struct.new(:file, :caption, keyword_init: true) do
    def video? = VIDEO_EXTENSIONS.include?(File.extname(file.to_s).downcase)
  end

  class Entry
    ATTRIBUTES = %i[id title status priority requested completed blocked_by request summary commits media].freeze
    attr_reader(*ATTRIBUTES)

    def initialize(attrs)
      attrs = attrs.to_h.transform_keys(&:to_sym)
      @id = Integer(attrs.fetch(:id))
      @title = attrs[:title].to_s
      @status = attrs[:status].to_s.presence || "queued"
      raise ArgumentError, "entry #{@id}: unknown status #{@status.inspect}" unless STATUSES.include?(@status)

      @priority = attrs[:priority]&.to_i || 9
      @requested = attrs[:requested]&.to_s
      @completed = attrs[:completed]&.to_s
      @blocked_by = Array(attrs[:blocked_by]).map(&:to_i)
      @request = attrs[:request].to_s
      @summary = attrs[:summary].to_s
      @commits = Array(attrs[:commits]).map(&:to_s)
      @media = Array(attrs[:media]).map { |m| Media.new(file: m["file"] || m[:file], caption: m["caption"] || m[:caption]) }
    end

    def queued? = QUEUE_ORDER.key?(status)
    def done? = status == "done"
    def dropped? = status == "dropped"
    def status_label = status.tr("_", " ")

    # The summary as simple blocks: [:p, "text"] for paragraphs and
    # [:ul, ["item", ...]] for runs of "- " bullet lines.
    def summary_blocks = self.class.blocks(summary)

    def self.blocks(text)
      text.to_s.strip.split(/\n\s*\n/).flat_map do |chunk|
        chunk.lines.map(&:rstrip).reject(&:blank?).each_with_object([]) do |line, blocks|
          last = blocks.last
          if line.lstrip.start_with?("- ")
            item = line.strip.delete_prefix("- ")
            last&.first == :ul ? last[1] << item : blocks << [:ul, [item]]
          elsif last&.first == :ul && line.start_with?(" ")
            last[1][-1] += " #{line.strip}" # indented continuation of a bullet
          elsif last&.first == :p
            last[1] += " #{line.strip}"
          else
            blocks << [:p, line.strip]
          end
        end
      end
    end
  end

  attr_reader :entries

  def self.load(path = DEFAULT_PATH)
    data = YAML.safe_load_file(path, permitted_classes: [Date]) || {}
    new(data.fetch("entries", []))
  end

  def initialize(entries)
    @entries = entries.map { |e| e.is_a?(Entry) ? e : Entry.new(e) }
  end

  def find(id) = entries.find { |e| e.id == id }

  def queue
    entries.select(&:queued?).sort_by { |e| [QUEUE_ORDER.fetch(e.status), e.priority, e.id] }
  end

  def done
    entries.select(&:done?).sort_by { |e| [e.completed.to_s, e.id] }.reverse
  end

  def dropped
    entries.select(&:dropped?).sort_by(&:id)
  end
end
