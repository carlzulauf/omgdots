class TestModel
  include JsonObject

  field :name, :string, default: "Game1"
  field :players, "TestPlayerCollection", default: :two_players
  field :count, :integer, default: -> { players.count }
  field :score, :float
  field :started, :boolean, default: false
  field :created_at, :time, default: -> { Time.now }
  field :board, "TestBoard"

  def two_players
    TestPlayerCollection.new([
      TestPlayer.new(name: "Player1"),
      TestPlayer.new(name: "Player2"),
      ])
  end
end

class TestPlayerCollection
  include JsonCollection

  collection_of "TestPlayer"
end

class TestPlayer
  include JsonObject

  field :name, :string
  field :age, :integer
  field :score, :float, default: 0.0
end

class TestBoard
  include JsonObject

  field :width, :integer, default: 7
  field :height, :integer, default: 5
  field :board, default: :build_board

  def build_board
    Array.new(height) { Array.new(width) }
  end
end

describe "JsonObject" do

  describe ".new" do

    context "with no arguments" do
      subject { TestModel.new }

      it "initializes successfully" do
        expect(subject).to be_a(TestModel)
      end

      it "initializes with defaults" do
        expect(subject.name).to eq("Game1")
        expect(subject.score).to eq(nil)
        expect(subject.started).to eq(false)
        expect(subject.created_at).to be_kind_of(Time)
        expect(subject.count).to eq(2)
      end
    end

    context "with simple hash object" do
      let(:data) do
        {name: "Kat"}
      end
      subject { TestModel.new(data) }

      it "should return the value from the hash" do
        expect(subject.name).to eq("Kat")
      end
    end

  end

end
