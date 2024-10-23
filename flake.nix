{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-update-scripts.url = "github:jwillikers/nix-update-scripts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
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
        caddy-ovh = pkgs.callPackage ./caddy-ovh.nix { };
        caddy-ovh-image = pkgs.callPackage ./caddy-ovh-image.nix { inherit caddy-ovh; };
        treefmt = {
          config = {
            programs = {
              actionlint.enable = true;
              jsonfmt.enable = true;
              just.enable = true;
              gofmt.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              taplo.enable = true;
              typos.enable = true;
              yamlfmt.enable = true;
            };
            projectRootFile = "flake.nix";
            settings.formatter = {
              typos.excludes = [ ".vscode/settings.json" ];
            };
          };
        };
        treefmtEval = treefmt-nix.lib.evalModule pkgs treefmt;
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            check-added-large-files.enable = true;
            check-builtin-literals.enable = true;
            check-case-conflicts.enable = true;
            check-executables-have-shebangs.enable = true;

            # todo Not integrated with Nix?
            check-format = {
              enable = true;
              entry = "${treefmtEval.config.build.wrapper}/bin/treefmt --fail-on-change";
            };

            check-json.enable = true;
            check-shebang-scripts-are-executable.enable = true;
            check-toml.enable = true;
            check-yaml.enable = true;
            deadnix.enable = true;
            detect-private-keys.enable = true;
            editorconfig-checker.enable = true;
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            # todo Broken for 24.05 branch
            # flake-checker.enable = true;
            forbid-new-submodules.enable = true;
            # todo Enable lychee when asciidoc is supported.
            # See https://github.com/lycheeverse/lychee/issues/291
            # lychee.enable = true;
            mixed-line-endings.enable = true;
            nil.enable = true;
            trim-trailing-whitespace.enable = true;
            yamllint.enable = true;
          };
        };
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
                  rm --force caddy-src/go.{mod,sum}
                  (cd caddy-src && ${pkgs.go}/bin/go mod init caddy)
                  (cd caddy-src && ${pkgs.go}/bin/go mod tidy)
                  oldVendorHash=$(${pkgs.nix}/bin/nix eval --quiet --raw .#caddy-ovh.vendorHash)
                  newVendorHash=$(${pkgs.nix-prefetch}/bin/nix-prefetch \
                      --expr "{ sha256 }: ((callPackage (import ./caddy-ovh.nix) { }).overrideAttrs"\
                        " { vendorHash = sha256; }).goModules" \
                      --option extra-experimental-features flakes \
                  )
                  sed --in-place "s/vendorHash = \"$oldVendorHash\";/vendorHash = \"$newVendorHash\";/" caddy-ovh.nix
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
              # Make formatters available for IDE's.
              (lib.attrValues treefmtEval.config.build.programs)
            ]
            ++ pre-commit.enabledPackages;
        };
        formatter = treefmtEval.config.build.wrapper;
        packages = {
          default = self.packages.${system}.caddy-ovh-image;
          inherit caddy-ovh;
          inherit caddy-ovh-image;
        };
      }
    );
}
