#!/bin/bash

# BIRD (IPv4 / BGP)
#
# The BIRD daemon configuration (/etc/bird/bird.conf, bird-routes.country.conf,
# BGP peers) and the bird/bird6 systemd services are managed by Ansible - see the
# ffc_vpn_gateway role in the ffc-mash playbook (templates/bird/*.j2). This module
# only sets up the kernel-side policy routing (table 100) and NAT that BIRD's
# learned routes depend on, and defers start/stop to systemd.

bird_init() {
	ip rule add from 10.149.0.0/16 lookup 100
	ip rule add to 10.149.0.0/16 lookup 100
	ip route add default via 127.0.0.1 table 100 metric 1024

	iptables -t nat -A POSTROUTING -o $WANIF -j MASQUERADE
}

bird_start() {
	systemctl restart bird >> /dev/null 2>&1
}

bird_stop() {
	systemctl stop bird >> /dev/null 2>&1
}
