#!/bin/bash

# BIRD6 (IPv6 / BGP)
#
# Like lib/bird.sh: the bird6 daemon configuration and the bird6 systemd service
# are managed by Ansible (ffc_vpn_gateway role, templates/bird/bird6.conf.j2).
# This module only sets up the IPv6 policy routing (table 100) and defers
# start/stop to systemd.

bird6_init() {
	ip -6 rule add from 2001:bc8:3f13:ffc2::/64 lookup 100
	ip -6 rule add to 2001:bc8:3f13:ffc2::/64 lookup 100
	ip -6 rule add from 2001:bc8:3f13:ffc3::/64 lookup 100
	ip -6 rule add to 2001:bc8:3f13:ffc3::/64 lookup 100
}

bird6_start() {
	systemctl restart bird6 >> /dev/null 2>&1
}

bird6_stop() {
	systemctl stop bird6 >> /dev/null 2>&1
}
