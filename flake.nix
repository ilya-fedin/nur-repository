{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-croscore.url = "github:NixOS/nixpkgs/a6ab4bfac4447bd550a5d20da282881136c31c4a";

  inputs.flake-compat = {
    url = github:edolstra/flake-compat;
    flake = false;
  };

  outputs = { nixpkgs, ... }: let
    lib = import (nixpkgs + "/lib");
    forAllSystems = f: lib.genAttrs lib.systems.flakeExposed (system: f system);
  in {
    packages = forAllSystems (system: import ./. {
      pkgs = import nixpkgs { inherit system; };
    });

    nixosModules = import ./modules;
  };
}
