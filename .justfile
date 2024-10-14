default: build

alias b := build

build:
    #!/bin/bash -eux
    nix build

alias ch := check

check: && format
    yamllint .
    asciidoctor *.adoc
    lychee --cache *.html

alias f := format
alias fmt := format

format:
    treefmt

alias r := run
run: build
    podman load < result
    podman run "quay.io/jwillikers/caddy-ovh-{{ arch() }}-linux:latest"

alias t := test

test: build
    nu update-nix-direnv-tests.nu

alias u := update
alias up := update

update:
    nu update-nixos-release.nu
    nix flake update
    cd caddy-src
    go get -u
    go mod tidy
    # Update go version in caddy-src/go.mod
    # todo Update Nix hashes...
    nu update-nix-direnv.nu
