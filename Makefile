# Makefile for building CoreDNS / OPA
GITCOMMIT:=$(shell git describe --dirty --always)
BINARY:=coredns
SYSTEM:=
BUILDOPTS:=-v
GOPATH?=$(HOME)/go
CGO_ENABLED:=0

.PHONY: all
all: coredns

.PHONY: coredns
coredns:
	GO111MODULE=on CGO_ENABLED=$(CGO_ENABLED) $(SYSTEM) go build $(BUILDOPTS) -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=coredns-opa/$(GITCOMMIT)" -o $(BINARY)
