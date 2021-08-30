#!/bin/bash

meshviewer_init() {
	if [ "$USE_MESHVIEWER" = "1" ]; then
		batman_wait_for_ll_address
		alfred -m -i bat0 &> /dev/null &
		batadv-vis -s &> /dev/null &
	fi
}

# Called by watchdog
meshviewer_cron() {
	batman_watchdog
}

meshviewer_stop() {
	killall alfred >> /dev/null 2>&1
}
