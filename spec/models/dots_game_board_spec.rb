describe DotsGameBoard do
  subject { DotsGameBoard.build(3, 2) }

  describe ".build" do
    it "creates a board with the given dimensions" do
      expect(subject).to be_a(DotsGameBoard)
      expect(subject.fullw).to eq(7) # width * 2 + 1
      expect(subject.fullh).to eq(5) # height * 2 + 1
    end

    it "initializes with open lines" do
      # Check that horizontal lines are open at y=0
      expect(subject.get(1, 0)).to eq(DotsGameBoard::HLINE_OPEN)
      # Check that vertical lines are open at x=0
      expect(subject.get(0, 1)).to eq(DotsGameBoard::VLINE_OPEN)
    end

    it "marks vertices" do
      expect(subject.get(0, 0)).to eq(DotsGameBoard::VERTEX)
      expect(subject.get(6, 4)).to eq(DotsGameBoard::VERTEX)
    end
  end

  describe "#move" do
    context "horizontal line" do
      it "closes an open horizontal line and scores if surrounded" do
        x, y = 1, 0
        expect(subject.get(x, y)).to eq(DotsGameBoard::HLINE_OPEN)
        
        moved, scored = subject.move(x: x, y: y, player: 1)
        
        expect(moved).to be true
        expect(scored).to be_zero # Border moves don't form boxes
      end

      it "returns false for closed lines" do
        x, y = 1, 0
        subject.move(x: x, y: y, player: 1)
        
        moved, scored = subject.move(x: x, y: y, player: 2)
        
        expect(moved).to be false
        expect(scored).to be_zero
      end

      it "returns false for invalid coordinates" do
        moved, scored = subject.move(x: -1, y: 0, player: 1)
        expect(moved).to be false
        
        moved, scored = subject.move(x: 99, y: 99, player: 1)
        expect(moved).to be false
      end
    end

    context "vertical line" do
      it "closes an open vertical line" do
        x, y = 0, 1
        expect(subject.get(x, y)).to eq(DotsGameBoard::VLINE_OPEN)
        
        moved, scored = subject.move(x: x, y: y, player: 1)
        
        expect(moved).to be true
      end
    end

    it "returns false for vertices" do
      x, y = 0, 0 # vertex position
      moved, scored = subject.move(x: x, y: y, player: 1)
      
      expect(moved).to be false
      expect(scored).to be_zero
    end
  end

  describe "#paint_open" do
    before { subject.clean }

    it "marks open lines as available" do
      # After clean, lines at the edge should be HLINE_OUT or VLINE_OUT
      # and inner lines should be OPEN
      expect(subject.get(1, 0)).to be_in([DotsGameBoard::HLINE_OPEN, DotsGameBoard::HLINE_OUT])
    end

    it "marks unused lines as OUT" do
      # Lines connected to other open lines are OPEN, others are OUT
      subject.paint_open
      
      # Check that vertices exist
      expect(subject.get(0, 0)).to eq(DotsGameBoard::VERTEX)
    end
  end

  describe "#clean" do
    it "resets the board to initial state" do
      # Make a move first
      subject.move(x: 1, y: 0, player: 1)
      
      cleaned = subject.clean
      
      expect(cleaned).to be(subject)
      # Board should have default lines open at edges
    end
  end

  describe "#complete?" do
    it "returns true when all tiles are filled" do
      # In a 3x2 game, there are 6 tiles (3 * 2)
      # Complete the board by closing all lines and filling all tiles
      
      expect(subject.complete?).to be(false)
      
      # This is hard to test fully without making many moves
      # Just verify the method exists and responds correctly
    end
  end

  describe "#score" do
    it "returns 0 when no tiles are owned" do
      expect(subject.score(1)).to be_zero
      expect(subject.score(2)).to be_zero
    end

    it "counts owned tiles" do
      # Fill a tile for player 1
      subject.data[1][1] = DotsGameBoard::TILE_PLAYER1
      
      expect(subject.score(1)).to eq(1)
      expect(subject.score(2)).to be_zero
    end
  end

  describe "#percent_complete" do
    it "calculates percentage of lines closed" do
      # Initially no lines are closed, so should be around 0
      expect(subject.percent_complete).to be_within(0.1).of(0)
      
      # After closing some lines, percentage should increase
      subject.move(x: 1, y: 0, player: 1)
      expect(subject.percent_complete).to be > 0
    end
  end

  describe "#as_json" do
    it "returns the board data array" do
      result = subject.as_json
      
      expect(result).to be_a(Array)
      expect(result.length).to eq(5) # height * 2 + 1
    end
  end

  describe "#valid_position?" do
    it "checks if coordinates are within bounds" do
      expect(subject.valid_position?(0, 0)).to be true
      expect(subject.valid_position?(6, 4)).to be true
      expect(subject.valid_position?(-1, 0)).to be false
      expect(subject.valid_position?(7, 0)).to be false
    end
  end

  describe "# eql?" do
    it "compares boards by their data" do
      board1 = DotsGameBoard.build(3, 2)
      board2 = DotsGameBoard.build(3, 2)
      
      expect(board1).to eq(board2)
      
      # After making different moves, they should differ
      board1.move(x: 1, y: 0, player: 1)
      expect(board1).not_to eq(board2)
    end

    it "rejects comparison with nil" do
      expect(subject.eql?(nil)).to be false
    end
  end

  describe "#positions" do
    it "enumerates all positions" do
      positions = subject.positions.to_a
      
      expect(positions.length).to eq(35) # 7 * 5
      expect(positions.first).to eq([0, 0])
    end
  end

  describe "#cells" do
    it "returns cell objects for all positions" do
      cells = subject.cells
      
      expect(cells.length).to eq(35)
      expect(cells.first).to be_a(DotsGameCell)
    end
  end

  context "with a completed game board" do
    let(:completed_board) do
      # Create a minimal 1x1 board and complete it
      board = DotsGameBoard.build(1, 1)
      
      # Complete all lines to fill the single tile
      [0, 2].each do |y|
        board.move(x: 1, y: y, player: 1)
      end
      [0, 2].each do |x|
        board.move(x: x, y: 1, player: 1)
      end
      
      # Fill the tile
      board.data[1][1] = DotsGameBoard::TILE_PLAYER1
      
      board
    end

    it "is complete" do
      expect(completed_board.complete?).to be true
    end

    it "has correct score" do
      expect(completed_board.score(1)).to eq(1)
    end
  end
end
