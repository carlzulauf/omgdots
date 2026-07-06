{
  description = "omgdots - Multiplayer browser game built with Ruby on Rails";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              bundler = prev.buildRubyGem rec {
                inherit (prev) ruby;
                gemName = "bundler";
                name = "${gemName}-${version}";
                version = "4.0.15";
                source.sha256 = "sha256-pM64gv6UoOCsY80IE5Mrv9YxoU5awLeXUYmxmk0o2ec=";
                dontPatchShebangs = true;
                postFixup = ''
                  substituteInPlace $out/bin/bundle --replace-fail "activate_bin_path" "bin_path"
                '';
              };
            })
          ];
        };

        rubyPackage = pkgs.ruby_3_4.buildBundlerEnvironment {
          name = "omgdots-bundle";
          gemdir = self;
          buildInputs = with pkgs; [ bundler ];
        };

        bundlerVersion = pkgs.bundler.version;
        rubyVersion = pkgs.ruby_3_4.version;
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            ruby_3_4
            bundler
            redis
            nodejs
            fish
          ];

          RUBY_VERSION = rubyVersion;
          BUNDLER_VERSION = bundlerVersion;
          shellHook = ''
            echo "### omgdots dev shell ###"
            echo "Ruby ${rubyVersion} | Bundler ${bundlerVersion}"
            echo ""
          '';
        };

        packages.default = rubyPackage;
      });
}
