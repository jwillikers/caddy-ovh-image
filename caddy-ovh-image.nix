{
  cacert,
  caddy-ovh,
  dockerTools,
  stdenv,
}:
dockerTools.buildLayeredImage {
  name = "localhost/caddy-ovh";
  tag = "${stdenv.hostPlatform.system}";
  compressor = "zstd";

  contents = [
    caddy-ovh
    cacert
  ];

  extraCommands = ''
    mkdir --parents config/caddy data/caddy etc/caddy srv usr/share/caddy
  '';

  config = {
    Cmd = [
      "${caddy-ovh}/bin/caddy"
      "run"
      "--config"
      "/etc/caddy/Caddyfile"
      "--adapter"
      "caddyfile"
    ];
    Env = [
      "XDG_CONFIG_HOME=/config"
      "XDG_DATA_HOME=/data"
    ];
    ExposedPorts = {
      "80" = { };
      "443" = { };
      "443/udp" = { };
      "2019" = { };
    };
    WorkingDir = "/srv";
  };
}
