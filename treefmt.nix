_: {
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
}
