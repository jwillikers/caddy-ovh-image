{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-update-scripts = {
      url = "github:jwillikers/nix-update-scripts";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      # deadnix: skip
      self,
      nix-update-scripts,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ ];
        pkgs = import nixpkgs { inherit system overlays; };
        packages = import ./packages { inherit pkgs; };
        pre-commit = pre-commit-hooks.lib.${system}.run (
          import ./pre-commit-hooks.nix { inherit treefmtEval; }
        );
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      with pkgs;
      {
        apps = {
          inherit (nix-update-scripts.apps.${system}) update-nix-direnv;
          inherit (nix-update-scripts.apps.${system}) update-nixos-release;
          update-go-module =
            let
              script = pkgs.writers.writeNu "update-go-module" ''
                cd packages/caddy-ovh/src
                rm --force ...(glob go.{mod,sum})
                ^${pkgs.lib.getExe pkgs.go} mod init caddy
                ^${pkgs.lib.getExe pkgs.go} mod tidy
                cd -
                let oldVendorHash = (^${pkgs.lib.getExe pkgs.nix} eval --quiet --raw ".#caddy-ovh.vendorHash")
                let newVendorHash = (
                  ^${pkgs.lib.getExe pkgs.nurl}
                  --expr "((import <nixpkgs> { }).callPackage ./packages/caddy-ovh/package.nix { }).goModules"
                  --nixpkgs ${nixpkgs}
                )
                (
                  open packages/caddy-ovh/package.nix |
                  str replace $"vendorHash = \"($oldVendorHash)\";" $"vendorHash = \"($newVendorHash)\";" |
                  save --force packages/caddy-ovh/package.nix
                )
              '';
            in
            {
              type = "app";
              program = "${script}";
            };
        };
        devShells.default = mkShell {
          inherit (pre-commit) shellHook;
          nativeBuildInputs =
            with pkgs;
            [
              asciidoctor
              fish
              just
              lychee
              nurl
              treefmtEval.config.build.wrapper
              (builtins.attrValues treefmtEval.config.build.programs)
            ]
            ++ pre-commit.enabledPackages;
        };
        formatter = treefmtEval.config.build.wrapper;
        packages = packages // {
          default = self.packages.${system}.caddy-ovh-image;
        };
      }
    );
}
