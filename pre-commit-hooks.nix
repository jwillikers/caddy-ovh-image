{ pkgs, treefmtEval, ... }:
{
  src = ./.;
  hooks = {
    check-added-large-files.enable = true;
    check-builtin-literals.enable = true;
    check-case-conflicts.enable = true;
    check-executables-have-shebangs.enable = true;

    # todo Not integrated with Nix?
    check-format = {
      enable = true;
      entry = "${pkgs.lib.getExe treefmtEval.config.build.wrapper} --fail-on-change";
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
}
