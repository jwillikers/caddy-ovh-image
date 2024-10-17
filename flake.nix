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
        caddyOvh = pkgs.buildGoModule {
          pname = "caddy-ovh";
          version = "0.1.0";
          src = ./caddy-src;
          runVend = true;
          vendorHash = "sha256-51SNBJlUBE9H8+vYjlXypy6thgjnvw4wTPQBA9K2zyk=";
          # postBuild = ''
          #   cargo objcopy -- -O ihex pwm-fan-controller-attiny85.hex
          # '';
          meta = {
            mainProgram = "caddy";
          };
        };
        caddyImage = {
          aarch64-linux = pkgs.dockerTools.pullImage {
            imageName = "docker.io/library/caddy";
            imageDigest = "sha256:63d8776389cc6527e4a23bd9750489dc661923cffc3b9d7e0c20e062fa0325ec";
            sha256 = "sha256-msp0C1PVCJV1DYQEfOErqHsxOqLkWQ3jVyT7GpJRndw=";
          };
          x86_64-linux = pkgs.dockerTools.pullImage {
            imageName = "docker.io/library/caddy";
            imageDigest = "sha256:63d8776389cc6527e4a23bd9750489dc661923cffc3b9d7e0c20e062fa0325ec";
            # finalImageName = "docker.io/library/caddy";
            # finalImageTag = "latest";
            sha256 = "sha256-aN8AnRkheqyfshefC4gFDwF80GGs3bqRikxT3aqjGxw=";
            # os = "linux";
            # arch = "x86_64";
          };
        };
        # caddyOvhImage = pkgs.dockerTools.buildImage {
        caddyOvhImage = pkgs.dockerTools.buildLayeredImage {
          name = "localhost/caddy-ovh";
          tag = "${system}";
          compressor = "zstd";

          # architecture = "aarch64";

          fromImage = caddyImage.${system};

          # copyToRoot = pkgs.buildEnv {
          #   name = "image-root";
          #   paths = [
          #     caddyOvh
          #     pkgs.libcap
          #     pkgs.mailcap
          #   ];
          #   pathsToLink = [ "/bin" ];
          # };

          contents = [
            caddyOvh
            pkgs.libcap
            pkgs.mailcap
          ];

          # runAsRoot = ''
          #   #!${pkgs.runtimeShell}
          #   ${pkgs.libcap}/bin/setcap cap_net_bind_service=+ep ${caddyOvh}/bin/caddy;
          # '';

          # enableFakechroot = true;
          # fakeRootCommands = ''
          extraCommands = ''
            ${pkgs.libcap}/bin/setcap cap_net_bind_service=+ep ${caddyOvh}/bin/caddy;
          '';

          config = {
            Cmd = [
              "${caddyOvh}/bin/caddy"
              "run"
              "--config"
              "/etc/caddy/Caddyfile"
              "--adapter"
              "caddyfile"
            ];
            # Cmd = [ "/bin/caddy" ];
            # Cmd = [ "${pkgsLinux.hello}/bin/hello" ];
            # Env = with pkgs; [ "GEOLITE2_COUNTRY_DB=${clash-geoip}/etc/clash/Country.mmdb" ];
            # Volumes = { "/data" = { }; };
            # WorkingDir = "/data";
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
          default = self.packages.${system}.caddyOvhImage;
          inherit caddyOvh;
          inherit caddyOvhImage;
        };
      }
    );
}
