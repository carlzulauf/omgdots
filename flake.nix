{
  description = "omgdots - Multiplayer browser game built with Ruby on Rails";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        ruby = pkgs.ruby_4_0;

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # Gemfile.lock is BUNDLED WITH 4.0.x, but nixpkgs still ships
            # bundler 2.7.x, so build the matching version.
            (final: prev: {
              bundler = prev.buildRubyGem rec {
                inherit ruby;
                gemName = "bundler";
                name = "${gemName}-${version}";
                version = "4.0.24";
                source.sha256 = "sha256-Fspk4ggWoM8VGpSPsUHXiGApltK01zV3t0OI/oT6mLw=";
                dontPatchShebangs = true;
                postFixup = ''
                  substituteInPlace $out/bin/bundle --replace-fail "activate_bin_path" "bin_path"
                '';
              };
            })
          ];
        };

        # BUNDLE_PATH installs into <path>/ruby/<abi version>, so point
        # GEM_HOME at that same directory, keeping each ruby version's gems
        # apart because native extensions link against one exact libruby.
        gemEnv = ''
          export BUNDLE_PATH="$HOME/.local/share/gems/omgdots/ruby-${ruby.version}"
          export GEM_HOME="$BUNDLE_PATH/ruby/${ruby.version.libDir}"
          export GEM_PATH="$GEM_HOME"
          export PATH="$GEM_HOME/bin:$PATH"
        '';
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bundler # ahead of ruby, so its bundle wins over ruby's own
            ruby
            pkgs.git
            pkgs.pkg-config
            pkgs.redis
          ];

          # Headers for the gems bundle install compiles
          buildInputs = [
            pkgs.libyaml.dev
            pkgs.openssl
            pkgs.zlib
            pkgs.libffi
          ];

          shellHook = ''
            ${gemEnv}
          '';
        };
      });
}
