{
  description = "OMGDOTS - A multiplayer browser game built with Ruby on Rails";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        rubyPackage = pkgs.rb.buildBundlerEnvironment {
          name = "omgdots-bundle";
          gemdir = self;
          # Add bundler explicitly to ensure proper version is used
          buildInputs = with pkgs; [ bundler ];
        };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            ruby
            bundler
            redis
            nodejs
          ];

          buildInputs = with pkgs; [
            postgresql
            sqlite
          ];

          RUBY_VERSION = "3.4.9";
          BUNDLER_VERSION = "2.5.10";
          
          shellHook = ''
            echo "Welcome to OMGDOTS dev shell!"
            echo "Redis is available at localhost:6379"
            echo ""
            echo "To start the Rails server:"
            echo "  rails server -b 0.0.0.0"
            echo ""
            echo "To run tests:"
            echo "  rspec"
          '';
        };

        packages.default = rubyPackage;
      });
}
