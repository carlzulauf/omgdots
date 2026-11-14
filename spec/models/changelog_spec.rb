require "rails_helper"

RSpec.describe Changelog do
  def entry(id, status, priority: 2, completed: nil, **rest)
    { "id" => id, "title" => "Entry #{id}", "status" => status, "priority" => priority, "completed" => completed, **rest.transform_keys(&:to_s) }
  end

  subject(:changelog) do
    described_class.new([
      entry(1, "done", completed: "2026-11-13"),
      entry(2, "queued", priority: 1),
      entry(3, "blocked", priority: 1, blocked_by: [2]),
      entry(4, "in_progress", priority: 3),
      entry(5, "queued", priority: 1),
      entry(6, "done", completed: "2026-11-14"),
      entry(7, "dropped"),
      entry(8, "queued", priority: 2),
    ])
  end

  it "orders the queue by status (in progress, queued, blocked), then priority, then id" do
    expect(changelog.queue.map(&:id)).to eq [4, 2, 5, 8, 3]
  end

  it "lists done entries newest first" do
    expect(changelog.done.map(&:id)).to eq [6, 1]
  end

  it "lists dropped entries separately" do
    expect(changelog.dropped.map(&:id)).to eq [7]
  end

  it "rejects unknown statuses" do
    expect { described_class.new([entry(1, "finished")]) }.to raise_error(ArgumentError, /unknown status/)
  end

  it "parses media and tells videos from images" do
    e = described_class::Entry.new(entry(1, "done", media: [{ "file" => "001-a.png" }, { "file" => "001-b.webm", "caption" => "B" }]))
    expect(e.media.map(&:video?)).to eq [false, true]
    expect(e.media.last.caption).to eq "B"
  end

  describe "summary blocks" do
    it "splits paragraphs and bullet lists" do
      text = "Intro line\nstill intro.\n\n- one\n- two\n  continued\nAfter.\n"
      expect(described_class::Entry.blocks(text)).to eq [
        [:p, "Intro line still intro."],
        [:ul, ["one", "two continued"]],
        [:p, "After."],
      ]
    end

    it "is empty for a blank summary" do
      expect(described_class::Entry.blocks(nil)).to eq []
    end
  end

  describe "doc/changelog/changelog.yml" do
    let(:real) { described_class.load }

    it "loads, with unique ids, valid blocked_by references and existing media" do
      ids = real.entries.map(&:id)
      expect(ids).to eq ids.uniq
      expect(real.entries.flat_map(&:blocked_by) - ids).to eq []
      missing = real.entries.flat_map(&:media).map(&:file).reject { |f| described_class::MEDIA_DIR.join(f).file? }
      expect(missing).to eq []
    end

    it "names media after the entry id" do
      real.entries.each do |e|
        e.media.each { |m| expect(m.file).to start_with(format("%03d-", e.id)) }
      end
    end
  end
end
