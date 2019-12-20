module github.com/coredns/coredns-opa

go 1.12

require (
	github.com/coredns/coredns v1.6.6
	github.com/coredns/policy v0.0.0-00010101000000-000000000000
	github.com/onsi/ginkgo v1.8.0 // indirect
	github.com/onsi/gomega v1.5.0 // indirect
)

replace (
	github.com/Azure/go-autorest => github.com/Azure/go-autorest v13.0.0+incompatible
	github.com/coredns/policy => ../policy
)
