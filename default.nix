{
  # deadnix: skip
  stdenv,
  buildGoModule,
}:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./caddy-src;
  # todo Update this automatically.
  # https://nixos.org/manual/nixpkgs/unstable/#sec-pkgs-fetchers-updating-source-hashes
  # nix-prefetch -E "{ sha256 }: ((import ./. { }).caddy-ovh.overrideAttrs { vendorHash = sha256; }).goModules"
  vendorHash = "sha256-51SNBJlUBE9H8+vYjlXypy6thgjnvw4wTPQBA9K2zyk=";
  postInstall = ''
    mkdir --parents $out/etc/caddy/
    cp Caddyfile $out/etc/caddy/
  '';
  meta = {
    mainProgram = "caddy";
  };
}
