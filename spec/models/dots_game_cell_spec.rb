describe DotsGameCell do
  let(:board_data) do
    Array.new(5) { Array.new(7).fill(DotsGameBoard::HLINE_OPEN) }
  end
  
  subject { DotsGameCell.new(board_data, x, y) }

  context "horizontal line cell" do
    let(:x) { 1 }
    let(:y) { 0 }

    it "has correct type" do
      expect(subject.type).to eq(:hline)
    end

    it "returns the value from board" do
      expect(subject.value).to eq(board_data[y][x])
    end
  end

  context "vertical line cell" do
    let(:x) { 0 }
    let(:y) { 1 }

    before do
      board_data[y][x] = DotsGameBoard::VLINE_CLOSE
    end

    it "has correct type" do
      expect(subject.type).to eq(:vline)
    end

    it "returns drawn css state when closed" do
      expect(subject.css_state).to eq(:drawn)
    end
  end

  context "dot (vertex) cell" do
    let(:x) { 0 }
    let(:y) { 0 }

    before do
      board_data[y][x] = DotsGameBoard::VERTEX
    end

    it "has dot type" do
      expect(subject.type).to eq(:dot)
    end
  end

  context "tile cell" do
    let(:x) { 1 }
    let(:y) { 1 }

    before do
      board_data[y][x] = DotsGameBoard::TILE_PLAYER1
    end

    it "has tile type" do
      expect(subject.type).to eq(:tile)
    end

    it "returns player1 css state when owned by player 1" do
      expect(subject.css_state).to eq(:player1)
    end
  end

  context "disabled line" do
    let(:x) { 0 }
    let(:y) { 1 }

    before do
      board_data[y][x] = DotsGameBoard::VLINE_OUT
    end

    it "returns disabled css state" do
      expect(subject.css_state).to eq(:disabled)
    end
  end

  describe "#css_classes" do
    let(:subject) { DotsGameCell.new(board_data, x, y) }
    
    context "horizontal line at edge" do
      let(:x) { 1 }
      let(:y) { 0 }

      it "includes type and optional state" do
        css = subject.css_classes
        
        expect(css.length).to be >= 1
        expect(css.first).to eq(:hline)
      end

      it "includes both type and state when present" do
        board_data[y][x] = DotsGameBoard::HLINE_CLOSE
        css = subject.css_classes
        
        expect(css).to include(:hline)
        expect(css).to include(:drawn)
      end
    end
  end

  context "with player2 tile" do
    let(:x) { 1 }
    let(:y) { 1 }

    before do
      board_data[y][x] = DotsGameBoard::TILE_PLAYER2
    end

    it "returns player2 css state" do
      expect(subject.css_state).to eq(:player2)
    end
  end

  context "with modified board array" do
    let(:custom_board) { Array.new(3) { Array.new(3) } }
    
    before do
      # Set up a small 3x3 board
      custom_board[0][0] = DotsGameBoard::VERTEX
    end

    it "works with smaller boards" do
      cell = DotsGameCell.new(custom_board, 0, 0)
      
      expect(cell.value).to eq(DotsGameBoard::VERTEX)
      expect(cell.type).to eq(:dot)
    end
  end

  context "with custom values in board" do
    let(:custom_board) { Array.new(3) { Array.new(3).fill(0) } }
    
    it "returns whatever is in the board array" do
      cell = DotsGameCell.new(custom_board, 1, 1)
      
      # Value at [1][1] is 0 (TILE_EMPTY)
      expect(cell.value).to eq(0)
    end

    it "returns specific values from board" do
      custom_board[1][1] = DotsGameBoard::TILE_PLAYER2
      cell = DotsGameCell.new(custom_board, 1, 1)
      
      expect(cell.value).to eq(DotsGameBoard::TILE_PLAYER2)
    end
  end

  context "board access beyond size" do
    let(:small_board) { Array.new(3) { Array.new(3).fill(0) } }
    
    # Note: board[y][x] where y is out of bounds -> board[y] = nil, then nil[x] raises NoMethodError
    # board[y][x] where y is in bounds but x is out -> returns nil
    
    it "raises NoMethodError when y is too large" do
      expect { 
        DotsGameCell.new(small_board, 0, 10).value 
      }.to raise_error(NoMethodError)
    end

    it "returns nil when x is too large but y is valid" do
      cell = DotsGameCell.new(small_board, 10, 0)
      
      expect(cell.value).to be_nil
    end
    
    # Negative indices work in Ruby arrays (count from end), so this will return elements
    it "can use negative indices to access from end" do
      small_board[-1][-1] = DotsGameBoard::TILE_PLAYER1
      cell = DotsGameCell.new(small_board, -1, -1)
      
      expect(cell.value).to eq(DotsGameBoard::TILE_PLAYER1)
    end
  end
end
