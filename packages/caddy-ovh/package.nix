{ buildGoModule }:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./src;
  vendorHash = "sha256-onQEOg2n2Y4sJnK7tI14zGjJWXfzD4hXrkEtLJ/Wm/k=";
  postInstall = ''
    install -D --mode=0644 --target-directory=$out/etc/caddy/ Caddyfile
  '';
  meta = {
    mainProgram = "caddy";
  };
}
