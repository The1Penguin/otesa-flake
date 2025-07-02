{
  description = "OpenTESArena goes flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    otesa = {
      url = "github:afritz1/OpenTESArena";
      flake = false;
    };
    JoltPhysics = {
      url = "github:jrouwe/JoltPhysics?ref=tags/v5.3.0";
      flake = false;
    };
    eawpats = {
      url = "https://github.com/afritz1/OpenTESArena/releases/download/opentesarena-0.1.0/eawpats.tar.gz";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, otesa, JoltPhysics, eawpats, ... }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem = {self', pkgs, system, ...}: {
        packages.default = self'.packages.otesa;
        packages.otesa = pkgs.stdenv.mkDerivation {
          pname = "otesa";
          version = "0.16.0";

          src = otesa;

          patches = [
            ./nix-fetch.patch
          ];

          nativeBuildInputs = with pkgs; [ cmake gnumake SDL2 SDL2.dev openal wildmidi ];
        buildInputs = with pkgs; [ unrar-wrapper ];

          JoltPhysics_SRC = JoltPhysics;
          Arena_SRC = (pkgs.fetchzip {
                          url = "https://cdnstatic.bethsoft.com/elderscrolls.com/assets/files/tes/extras/Arena106Setup.zip";
                          sha256 = "sha256-g9Qakm3ZU/IytEKlPqF4e9OUdcywn1blMA4Or7RLmMM=";
                          stripRoot = false;
                        });
          eawpats_SRC = eawpats;
          enableParallelBuilding = true;

          buildPhase = ''
            cp $Arena_SRC/Arena106.exe .
            unrar x Arena106.exe data/
            mkdir data/eawpats
            cp -r $eawpats_SRC/* data/eawpats/.
            make -j $NIX_BUILD_CORES
          '';

          installPhase = ''
            mkdir -p $out/bin/
            cp otesa $out/bin/
            cp -r data $out/bin/
            cp -r options $out/bin/

          '';
        };

      };
    };
}
