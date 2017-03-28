#!/bin/bash

batman_init() {
	modprobe batman-adv
	modprobe dummy
	batctl interface add dummy0
	batctl bridge_loop_avoidance 1
	batctl bonding 1
	[ "$USE_DNSMASQ" = "1" ] && batctl gw_mode server
}

# Add interface to batman-adv
#	$1		Interface name
batman_add_interface() {
	batctl interface add $1
	echo 1 > /sys/class/net/"$1"/batman_adv/no_rebroadcast
}

# Remove interface from batman-adv
#	$1		Interface name
batman_del_interface() {
	batctl interface del $1 >> /dev/null 2>&1
}

batman_setup_interface() {
	local macAddress=$(sed -e "s/^[a-z0-9]*:/02:/g" /sys/class/net/$WANIF/address)
	ip link set address $macAddress up dev bat0
	for a in "${SERVICE_ADDRESSES[@]}"; do
		[ "$a" ] && ip addr add $a dev bat0
	done
	
	if [ "$USE_MESHVIEWER" != "1" ]; then
		batman_wait_for_ll_address
		alfred -i bat0 -m &> /dev/null &
		batadv-vis -s &> /dev/null &
	fi
}

batman_wait_for_ll_address() {
	local iface="bat0"
	local timeout=30

	for i in $(seq $timeout); do
		# We look for
		# - the link-local address (starts with fe80)
		# - without tentative flag (bit 0x40 in the flags field; the first char of the flags field begins 38 columns after the fe80 prefix
		# - on interface $iface
		if awk '
			BEGIN { RET=1 }
			/^fe80............................ .. .. .. [012389ab]./ { if ($6 == "'"$iface"'") RET=0 }
			END { exit RET }
		' /proc/net/if_inet6; then
			return
		fi
		sleep 1
	done
}
# the check if alfred is running
batman_watchdog(){
	if [ "$USE_MESHVIEWER" != "1" ]; then
		if ! pgrep -x "alfred" > /dev/null
		then
    			alfred -i bat0 -m &> /dev/null &
		fi
	fi
}

# adds all peer-interfaces to the mesh
batman_add_all_peers(){
 	for p in "${BATMAN_IFS[@]}"; do
		batman_add_interface "$p"
 	done

 	batman_setup_interface
}

batman_stop() {
	rmmod batman-adv >> /dev/null 2>&1
}
