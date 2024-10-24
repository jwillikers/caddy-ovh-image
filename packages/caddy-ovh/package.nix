{ buildGoModule }:
buildGoModule {
  pname = "caddy-ovh";
  version = "0.1.0";
  src = ./src;
  vendorHash = "sha256-51SNBJlUBE9H8+vYjlXypy6thgjnvw4wTPQBA9K2zyk=";
  postInstall = ''
    mkdir --parents $out/etc/caddy/
    cp Caddyfile $out/etc/caddy/
  '';
  meta = {
    mainProgram = "caddy";
  };
}
