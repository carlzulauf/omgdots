describe DotsGame do
  describe ".new" do
    it "initializes with no argument" do
      expect(DotsGame.new).to be_a(DotsGame)
    end

    it "initializes with attributes" do
      attrs = {id: "foo", must_touch: false}
      game = DotsGame.new(attrs)
      expect(game.id).to eq(attrs[:id])
      expect(game.must_touch).to eq(attrs[:must_touch])
    end
  end

  context "with default game" do
    subject { DotsGame.find_or_create("test") }
    let(:saved) { DotsGame.find("test") }

    after(:each) { subject.destroy }

    describe "#move" do
      it "moves when line is open horizontal" do
        subject.move(x: 1, y: 0)
        expect(subject).not_to eq(saved)
        expect(subject.board.get(1, 0)).to eq(DotsGameBoard::HLINE_CLOSE)
      end

      it "remains the same when line is closed" do
        subject.move(x: 1, y: 0)
        subject.save
        subject.move(x: 1, y: 0)
        expect(subject).to eq(saved)
      end

      it "remains the same when coordinate is a vertex" do
        subject.move(x: 0, y: 0)
        expect(subject).to eq(saved)
      end

      it "remains the same when coordinate is invalid" do
        subject.move(x: 99, y: 99)
        expect(subject).to eq(saved)
      end
    end
  end
end
