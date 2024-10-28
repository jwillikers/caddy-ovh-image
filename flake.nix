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
              script = pkgs.writeShellApplication {
                name = "update-go-module";
                text = ''
                  set -eou pipefail
                  rm --force packages/caddy-ovh/src/go.{mod,sum}
                  (cd packages/caddy-ovh/src && ${pkgs.go}/bin/go mod init caddy 2>/dev/null)
                  (cd packages/caddy-ovh/src && ${pkgs.go}/bin/go mod tidy 2>/dev/null)
                  oldVendorHash=$(${pkgs.nix}/bin/nix eval --quiet --raw .#caddy-ovh.vendorHash)
                  newVendorHash=$(${pkgs.nix-prefetch}/bin/nix-prefetch \
                      --expr "{ sha256 }: ((callPackage (import ./packages/caddy-ovh/package.nix) { }).overrideAttrs \
                        { vendorHash = sha256; }).goModules" \
                      --option extra-experimental-features flakes \
                      --quiet \
                  )
                  sed --in-place "s/vendorHash = \"$oldVendorHash\";/vendorHash = \"$newVendorHash\";/" \
                    packages/caddy-ovh/package.nix
                '';
              };
            in
            {
              type = "app";
              program = "${script}/bin/update-go-module";
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
              nil
              nix-prefetch
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
