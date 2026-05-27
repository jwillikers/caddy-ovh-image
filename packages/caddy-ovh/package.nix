{ buildGoModule }:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./src;
  vendorHash = "sha256-EIopDmAIVV9TPqZw8Y9F5ktcBDb6xiMdY1PLWqeSK+8=";
  postInstall = ''
    install -D --mode=0644 --target-directory=$out/etc/caddy/ Caddyfile
  '';
  meta = {
    mainProgram = "caddy";
  };
}
