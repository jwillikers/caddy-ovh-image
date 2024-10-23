default: build

alias b := build

build attribute="caddy-ovh-image":
    nix build '.#{{ attribute }}'

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
run attribute="caddy-ovh-image": (build attribute)
    podman image load --input result
    podman run --cap-add NET_BIND_SERVICE --interactive --rm --tty "localhost/caddy-ovh:{{ arch() }}-linux"

alias u := update
alias up := update

update:
    nix flake update
    nix run '.#update-go-module'
