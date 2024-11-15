{ buildGoModule }:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./src;
  vendorHash = "sha256-51SNBJlUBE9H8+vYjlXypy6thgjnvw4wTPQBA9K2zyk=";
  postInstall = ''
    install -D --mode=0644 --target-directory=$out/etc/caddy/ Caddyfile
  '';
  meta = {
    mainProgram = "caddy";
  };
}
