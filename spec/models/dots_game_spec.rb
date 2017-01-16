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

    describe "#move!" do
      it "fails when move is already made in another instance" do
        other = DotsGame.find(subject.id)
        expect(other.move!(x: 1, y: 0)).to be_truthy
        expect(subject.move!(x: 1, y: 0)).to be_falsy
        expect(subject.board.get(1, 0)).to eq(DotsGameBoard::HLINE_CLOSE)
      end

      it "sees moves made in other instances" do
        other = DotsGame.find(subject.id)

        expect(other.move!(x: 1, y: 0)).to be_truthy
        expect(subject.move!(x: 3, y: 0)).to be_truthy

        expect(subject.board.get(1, 0)).to eq(DotsGameBoard::HLINE_CLOSE)
        expect(subject.board.get(3, 0)).to eq(DotsGameBoard::HLINE_CLOSE)
      end
    end

    describe "#winner" do
      it "defaults to nil" do
        expect(subject.winner).to be(nil)
      end
    end

    describe "#won" do
      it "defaults to false" do
        expect(subject.won?).to eq(false)
      end
    end

  end

  context "with late game board" do
    subject { load_saved_game "late" }

    describe "player2 makes winning move" do
      let(:make_move) do
        subject.move(x: 5, y: 2)
      end

      it "causes player2 to be the winner" do
        expect{ make_move }.to change{ subject.winner }.from(nil).to(2)
      end

      it "causes the game to be won" do
        expect{ make_move }.to change{ subject.won? }.from(false).to(true)
      end

      it "does not complete the game" do
        expect{ make_move }.not_to change{ subject.complete? }
      end
    end
  end
end
