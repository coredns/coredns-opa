package main

import (
	"github.com/coredns/coredns/core/dnsserver"
	_ "github.com/coredns/coredns/core/plugin"
	"github.com/coredns/coredns/coremain"

	_ "github.com/coredns/policy/plugin/firewall"
	_ "github.com/coredns/policy/plugin/opa"
)

func init() {
	directives := make([]string, len(dnsserver.Directives)+2)
	n := 0
	for _, d := range dnsserver.Directives {
		directives[n] = d
		n++
		if d == "acl" {
			directives[n] = "firewall"
			n++
			directives[n] = "opa"
			n++
		}
	}
	dnsserver.Directives = directives
}

func main() {
	coremain.Run()
}
