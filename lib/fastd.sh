#!/bin/bash

fastd_init() {
	if [ ! -r "conf/fastd-secret.local.conf" ]; then
		log_fatal_error "Missing fastd-secret.local.conf - please check configuration!"
	fi
}

fastd_start() {
	fastd -d -c conf/fastd.conf
}

fastd_stop() {
	killall fastd >> /dev/null 2>&1
}
