{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    astal = {
      url = "github:cold-leopard/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    astal,
  }: let

    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: (forSystem system f));
    forSystem = system: f: f rec {
      inherit system;
      inherit (astal.packages.${system}) astal3 astal4 io gjs;
      pkgs = nixpkgs.legacyPackages.${system};

      astal-io = io;
      astal-gjs = "${gjs}/share/astal/gjs";

      agsPackages = {
	default = self.packages.${system}.ags;
	ags = pkgs.callPackage ./nix {
	  inherit astal3 astal4 astal-io astal-gjs;
	};
	agsFull = pkgs.callPackage ./nix {
	  inherit astal3 astal4 astal-io astal-gjs;
	  extraPackages = builtins.attrValues (
	    builtins.removeAttrs astal.packages.${system} ["docs"]
	  );
	};
      };
    };

  in {
    lib.bundle = forAllSystems({pkgs, ...}: import ./nix/bundle.nix {inherit self pkgs;});

    packages= forAllSystems({system, agsPackages, ...}:  astal.packages.${system} // agsPackages);

    templates.default = {
      path = ./nix/template;
      description = "Example flake.nix that shows how to package a project.";
      welcomeText = ''
        # Getting Started
        - run `nix develop` to enter the development environment
        - run `ags init -d . -f` to setup an initial ags project
        - run `ags run .`   to run the project
      '';
    };

    homeManagerModules = {
      default = self.homeManagerModules.ags;
      ags = import ./nix/hm-module.nix self;
    };
  };
}
