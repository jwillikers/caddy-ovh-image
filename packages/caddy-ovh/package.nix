{ buildGoModule }:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./src;
  vendorHash = "sha256-V1CaWedgldL3BB0CsRalD7Q5zajWzCdm0Wjlhj06l3U=";
  postInstall = ''
    install -D --mode=0644 --target-directory=$out/etc/caddy/ Caddyfile
  '';
  meta = {
    mainProgram = "caddy";
  };
}
