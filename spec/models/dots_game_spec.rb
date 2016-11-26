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
end
