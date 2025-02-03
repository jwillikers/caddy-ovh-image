{ buildGoModule }:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./src;
  vendorHash = "sha256-OK5CR2oJaB8Pcs1wTefMIw5u78Wpzp7u2vv6EliraUM=";
  postInstall = ''
    install -D --mode=0644 --target-directory=$out/etc/caddy/ Caddyfile
  '';
  meta = {
    mainProgram = "caddy";
  };
}
