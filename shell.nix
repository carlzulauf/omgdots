{ pkgs ? import <nixpkgs> {} }:

let
  ruby_3_4 = pkgs.ruby;
in
pkgs.mkShell {
  name = "omgdots-dev";
  
  buildInputs = with pkgs; [
    ruby_3_4
    bundler
    redis
    nodejs
    sqlite
  ];

  RUBY_VERSION = "3.4.9";
  BUNDLER_VERSION = "2.5.10";
  
  shellHook = ''
    echo "Welcome to OMGDOTS dev shell!"
    echo "Ruby: $(ruby --version)"
    echo ""
    echo "To install gems:"
    echo "  bundle config set --local path .bundle/gems"
    echo "  bundle install"
    echo ""
    echo "To start Redis (if not running):"
    echo "  redis-server --daemonize yes"
    echo ""
    echo "To start the Rails server:"
    echo "  rails server -b 0.0.0.0"
    echo ""
    echo "To run tests:"
    echo "  rspec"
  '';
}
