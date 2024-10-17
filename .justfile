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
    podman image load --input result
    podman run --cap-add NET_BIND_SERVICE --interactive --rm --tty "localhost/caddy-ovh:{{ arch() }}-linux"

alias u := update
alias up := update

update:
    nix flake update
    cd caddy-src
    go get -u
    go mod tidy
    # Update go version in caddy-src/go.mod?
    # todo Update Nix hash in default.nix: vendorHash = "sha256-...";
