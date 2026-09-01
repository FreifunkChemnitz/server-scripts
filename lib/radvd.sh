#!/bin/bash

radvd_init() {
	if [ ! "$WANIF" ] || [ ! "$WANGW6" ]; then
		log_fatal_error "Missing WANIF or WANGW6 - please check configuration!"
	fi
	if [ "$USE_BIRD" != "1" ]; then
		log_fatal_error "You must enable BIRD to use RADVD - please check configuration!"
	fi
	# The IPv6 default route (::/0) that BIRD6 announces for this uplink is now
	# part of the Ansible-managed bird6 config: set
	# ffc_vpn_gateway_bird_ipv6_uplink: true for this host in the ffc-mash
	# playbook (ffc_vpn_gateway role).
}

radvd_start() {
	sleep 2
	radvd -C conf/radvd.conf
}

radvd_stop() {
	killall radvd >> /dev/null 2>&1
}

# Called by watchdog
radvd_cron() {
	pidof radvd > /dev/null
	if [[ $? -ne 0 ]] ; then
		radvd_start
	fi
}
