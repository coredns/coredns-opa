package dns

import input.name
import input.client_ip

default action = "allow"

# Action Priority
action = "allow" {
  allow
} else = "refuse" {
  refuse
} else = "block" {
  block
} else = "drop" {
  drop
}

block { name == "a.example.com." }

refuse { name == "b.example.com." }

drop { name == "x.example.com." }

allow { net.cidr_contains("1.2.3.0/24", client_ip) }
