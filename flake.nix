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
        nativeBuildInputs = with pkgs; [
          asciidoctor
          fish
          dive
          just
          lychee
          nil
        ];
        buildInputs = with pkgs; [ ];
        caddy-ovh = pkgs.callPackage ./default.nix { };
        caddy-ovh-image = pkgs.dockerTools.buildLayeredImage {
          name = "localhost/caddy-ovh";
          tag = "${system}";
          compressor = "zstd";

          contents = [
            caddy-ovh
            pkgs.cacert
          ];

          extraCommands = ''
            mkdir --parents config/caddy data/caddy etc/caddy srv usr/share/caddy
          '';

          # todo It would be nice if I could get this to work.
          # enableFakechroot = true;
          # fakeRootCommands = ''
          #  ${pkgs.libcap}/bin/setcap cap_net_bind_service=+ep ${caddy-ovh}/bin/caddy;
          # '';

          config = {
            Cmd = [
              "${caddy-ovh}/bin/caddy"
              "run"
              "--config"
              "/etc/caddy/Caddyfile"
              "--adapter"
              "caddyfile"
            ];
            Env = [
              "XDG_CONFIG_HOME=/config"
              "XDG_DATA_HOME=/data"
            ];
            ExposedPorts = {
              "80" = { };
              "443" = { };
              "443/udp" = { };
              "2019" = { };
            };
            WorkingDir = "/srv";
          };
        };
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
        };
        devShells.default = mkShell {
          inherit buildInputs;
          inherit (pre-commit) shellHook;
          nativeBuildInputs =
            nativeBuildInputs
            ++ [
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
