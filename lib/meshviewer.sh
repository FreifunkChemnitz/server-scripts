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
        /opt/freifunk/meshviewer/ffmap-backend/backend.py -d /opt/freifunk/meshviewer/data/ --prune 30 --with-graphite --graphite-host 'gianotti.routers.chemnitz.freifunk.net' --graphite-metrics 'clients,loadavg,memory_usage,rootfs_usage,uptime,traffic.rx.bytes,traffic.tx.bytes,traffic.mgmt_tx.bytes,traffic.mgmt_rx.bytes,traffic.forward.bytes'

        jq -c '.nodes = (.nodes | map(del(.value.nodeinfo.owner)))' < /opt/freifunk/meshviewer/data/nodes.json > /opt/freifunk/meshviewer/data/nodes.json.priv.tmp
        if json_pp < /opt/freifunk/meshviewer/data/nodes.json.priv.tmp >& /dev/null; then
                mv /opt/freifunk/meshviewer/data/nodes.json.priv.tmp /opt/freifunk/meshviewer/data/nodes.json.priv
        fi
}

meshviewer_stop() {
	killall alfred >> /dev/null 2>&1
}
