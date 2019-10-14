#!/bin/bash

fastd_init() {
	if [ ! -r "conf/fastd-secret.local.conf" ]; then
		log_fatal_error "Missing fastd-secret.local.conf - please check configuration!"
	fi
}

fastd_start() {
	for ((i=0; i<$(nproc||echo -n 1); i++)); do
		fastd -d -c conf/fastd.conf --bind any:$(expr 10000 + $i) --interface mesh-vpn$i
        done
}

fastd_stop() {
	killall fastd >> /dev/null 2>&1
}
