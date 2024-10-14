// This file is based on https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go

// Package main is the entry point of the Caddy application.
// Most of Caddy's functionality is provided through modules,
// which can be plugged in by adding their import below.
//
// There is no need to modify the Caddy source code to customize your
// builds. You can easily build a custom Caddy with these simple steps:
//
//  1. Copy this file (main.go) into a new folder
//  2. Edit the imports below to include the modules you want plugged in
//  3. Run `go mod init caddy`
//  4. Run `go mod tidy`
//  5. Run `go install` or `go build` - you now have a custom binary!
package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// plug in Caddy modules here
	_ "github.com/caddy-dns/ovh"
	_ "github.com/caddyserver/caddy/v2/modules/standard"
)

func main() {
	caddycmd.Main()
}
