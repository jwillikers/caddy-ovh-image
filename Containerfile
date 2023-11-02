FROM docker.io/caddy:builder AS builder

RUN xcaddy build \
     --with github.com/caddy-dns/ovh \
     --with github.com/mholt/caddy-l4

FROM docker.io/caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
