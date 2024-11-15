{ pkgs, ... }:
rec {
  caddy-ovh = pkgs.callPackage ./caddy-ovh/package.nix { };
  caddy-ovh-image = pkgs.callPackage ./caddy-ovh-image/package.nix { inherit caddy-ovh; };
}
