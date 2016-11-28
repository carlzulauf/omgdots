class TestModel
  include JsonObject

  many :players, "TestPlayer", default: :two_players

  field :name, :string, default: "Game1"
  field :count, :integer, default: -> { players.count }
  field :score, :float
  field :started, :boolean, default: false
  field :created_at, :time, default: -> { Time.now }
  field :expires_on, :date
  field :board, "TestBoard"
  field :options, :hash

  def two_players
    [
      TestPlayer.new(name: "Player1"),
      TestPlayer.new(name: "Player2"),
    ]
  end
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
  field :data, :array, default: :build_board

  def build_board
    Array.new(height) { Array.new(width) }
  end
end

describe "JsonObject" do

  describe ".new" do
    subject { TestModel.new *args }

    context "with no arguments" do
      let(:args) { [] }

      it "initializes successfully" do
        expect(subject).to be_a(TestModel)
      end

      it "initializes with defaults" do
        expect(subject.name).to eq("Game1")
        expect(subject.score).to eq(nil)
        expect(subject.started).to eq(false)
        expect(subject.created_at).to be_kind_of(Time)
        expect(subject.count).to eq(2)
        expect(subject.options).to eq(nil)
        expect(subject.expires_on).to eq(nil)
      end
    end

    context "with simple hash object" do
      let(:args) do
        [
          {
            name: "Kat",
            score: "101.25",
            started: "yes",
            created_at: "2016-11-01",
            options: {foo: "bar"},
          }
        ]
      end

      it "should return values from the hash" do
        expect(subject.name).to eq("Kat")
        expect(subject.score).to eq(101.25)
        expect(subject.started).to eq(true)
        expect(subject.created_at).to eq(Time.new(2016,11,1))
        expect(subject.options).to eq("foo" => "bar")
      end

      it "should coerce values that are not the correct type" do
        expect(subject.score).to be_a(Float)
        expect(subject.started).to be_a(TrueClass)
        expect(subject.created_at).to be_a(Time)
      end

      it "fields not supplied by hash should have default values" do
        expect(subject.count).to eq(2)
      end
    end

    context "with nested hash objects" do
      let(:args) do
        [
          {
            players: [
              {name: "George", age: 66},
              {name: "Lisa", age: 37}
            ],
            board: {width: 4, height: 4},
          }
        ]
      end

      it "populates collection objects correctly" do
        expect(subject.players[0].name).to eq("George")
        expect(subject.players[1].name).to eq("Lisa")
        expect(subject.players[0].age).to eq(66)
        expect(subject.players[1].age).to eq(37)
        expect(subject.players[0].score).to eq(0.0)
      end

      it "populates typed objects correctly" do
        expect(subject.board).to be_a(TestBoard)
        expect(subject.board.width).to eq(4)
        expect(subject.board.height).to eq(4)
        expect(subject.board.data.length).to eq(4)
        expect(subject.board.data[0].length).to eq(4)
      end
    end

    context "with unexpected hash attributes" do
      let(:args) do
        [{foo: "bar"}]
      end

      it "should silently hold on to the value" do
        expect(subject.object["foo"]).to eq("bar")
      end
    end

  end

  describe "typed field writers" do
    subject { TestModel.new }

    it "coerces from strings correctly" do
      subject.name = "foo"
      expect(subject.name).to eq("foo")

      subject.count = "3"
      expect(subject.count).to eq(3)

      subject.score = "42.42"
      expect(subject.score).to eq(42.42)
      subject.score = "$5,427.06"
      expect(subject.score).to eq(5427.06)

      subject.started = "yes"
      expect(subject.started).to eq(true)
      subject.started = "no"
      expect(subject.started).to eq(false)

      subject.expires_on = "2018-01-01"
      expect(subject.expires_on).to eq(Date.new(2018))
    end

    it "coerces and rounds floats for integer fields" do
      subject.count = 3.6
      expect(subject.count).to eq(4)
    end
  end

end
