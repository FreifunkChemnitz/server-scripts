#!/bin/bash

bird_init() {
	local ipL1=$(echo $WANIP | awk -F '.' '{print $3}')
	local ipL2=$(echo $WANIP | awk -F '.' '{print $4}')
	sed -e "s/__BIRD_ROUTER_ID__/169.254.${ipL1}.${ipL2}/g" \
		-e "s/__BIRD_ROUTER_ASN__/${ipL1}${ipL2}/g" \
		conf/bird.conf > conf/bird.local.conf

	echo -n "" > conf/bird-peers.local.conf
	for p in "${GRE_PEERS[@]}"; do
		local remoteHost=$(echo $p | awk -F ':' '{print $1}')
		local remoteIP=$(echo $p | awk -F ':' '{print $2}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" != "$WANIP" ]; then
				bird_add_peer "${remoteHost}" "$remoteIP"
			fi
		else
			log_error "Syntax error in peer definition: ${p}"
		fi
	done

	echo -n "" > conf/bird-routes.local.conf
	for s in "${SERVICE_ADDRESSES[@]}"; do
		if [ "$(bird_check_route "$s")" ]; then
			bird_add_route "$s"
		fi
	done

	touch conf/bird-routes.country.conf

	ip rule add from 10.149.0.0/16 lookup 100
	ip rule add to 10.149.0.0/16 lookup 100
	ip route add default via 127.0.0.1 table 100 metric 1024

	iptables -t nat -A POSTROUTING -o $WANIF -j MASQUERADE
}

# Check for route
#	$1		IPv4 route
bird_check_route() {
	[[ "$1" =~ ^[0-9.]*/[0-9]+ ]] && echo "1"
}

bird_start() {
	mkdir /run/bird
	bird -c conf/bird.local.conf
}

bird_stop() {
	killall bird >> /dev/null 2>&1
}

bird_cron() {
	if [ -n $WANGW -a -n $APIKEY ]; then
		wget "http://api.chemnitz.freifunk.net/request.php?region=$COUNTRY" -q -O conf/bird-routes.country.conf
		sed -e "s/NEXTHOP/$WANGW/g" -i "conf/bird-routes.country.conf"
		killall bird -s SIGHUP
	fi
}

# Add BGP peer
# 	$1		Hostname
# 	$2		Peer IPv4 address
bird_add_peer() {
	local ipR1=$(echo $2 | awk -F '.' '{print $3}')
	local ipR2=$(echo $2 | awk -F '.' '{print $4}')
	sed -e "s/__BIRD_REMOTE_HOST__/$1/g" \
		-e "s/__BIRD_REMOTE_IP__/169.254.${ipR1}.${ipR2}/g" \
		-e "s/__BIRD_REMOTE_ASN__/${ipR1}${ipR2}/g" \
		conf/bird-peers.conf >> conf/bird-peers.local.conf
}

# Add BGP route
# 	$1		IPv4 Route
#	$2		Next hop (optional)
#	$3		Next hop interface (optional)
bird_add_route() {
	local via="\"bat0\""
	[ "$2" ] && local via="$2"
	[ "$3" ] && local via="\"$3\""
	sed -e "s|__BIRD_ROUTE__|$1|g" \
		-e "s/__BIRD_VIA__/$via/g" \
		conf/bird-routes.conf >> conf/bird-routes.local.conf
}
