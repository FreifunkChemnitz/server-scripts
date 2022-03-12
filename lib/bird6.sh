#!/bin/bash

bird6_init() {
	local ipL1=$(echo $WANIP | awk -F '.' '{print $3}')
	local ipL2=$(echo $WANIP | awk -F '.' '{print $4}')
	local ip6L1=$(printf '%x' $ipL1)
	local ip6L2=$(printf '%x' $ipL2)
	sed -e "s/__BIRD_ROUTER_ID__/169.254.${ipL1}.${ipL2}/g" \
		-e "s/__BIRD_ROUTER_IP__/fe80::ffc:${ip6L1}:${ip6L2}/g" \
		-e "s/__BIRD_ROUTER_ASN__/${ipL1}${ipL2}/g" \
		conf/bird6.conf > conf/bird6.local.conf

	echo -n "" > conf/bird6-peers.local.conf
	for p in "${GRE_PEERS[@]}"; do
		local remoteHost=$(echo $p | awk -F ':' '{print $1}')
		local remoteIP=$(echo $p | awk -F ':' '{print $2}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" != "$WANIP" ]; then
				bird6_add_peer "${remoteHost}" "$remoteIP"
			fi
		else
			log_error "Syntax error in peer definition: ${p}"
		fi
	done

	echo -n "" > conf/bird6-routes.local.conf
	for s in "${SERVICE_ADDRESSES[@]}"; do
		if [ "$(bird6_check_route "$s")" ]; then
			bird6_add_route "$s"
		fi
	done

	ip -6 rule add from 2001:bc8:3f13:ffc2::/64 lookup 100
	ip -6 rule add to 2001:bc8:3f13:ffc2::/64 lookup 100
	ip -6 rule add from 2001:bc8:3f13:ffc3::/64 lookup 100
	ip -6 rule add to 2001:bc8:3f13:ffc3::/64 lookup 100
}

# Check for route
#	$1		IPv6 route
bird6_check_route() {
	[[ "$1" =~ ^[a-f0-9:]*/[0-9]+ ]] && echo "1"
}

bird6_start() {
	bird6 -c conf/bird6.local.conf
}

bird6_stop() {
	killall bird6 >> /dev/null 2>&1
}

# Add BGP peer
# 	$1		Hostname
# 	$2		Peer IPv6 address
bird6_add_peer() {
	local ipR1=$(echo $2 | awk -F '.' '{print $3}')
	local ipR2=$(echo $2 | awk -F '.' '{print $4}')
	local ip6R1=$(printf '%x' $ipR1)
	local ip6R2=$(printf '%x' $ipR2)
	sed -e "s/__BIRD_REMOTE_HOST__/$1/g" \
		-e "s/__BIRD_REMOTE_IP__/fe80::ffc:${ip6R1}:${ip6R2} % 'gre-$1'/g" \
		-e "s/__BIRD_REMOTE_ASN__/${ipR1}${ipR2}/g" \
		conf/bird-peers.conf >> conf/bird6-peers.local.conf
}

# Add BGP route
# 	$1		IPv6 Route
#	$2		Next hop (optional)
#	$3		Next hop interface (mandatory, if $2 is selected)
bird6_add_route() {
	local via="\"bat0\""
	if [ "$2" ] && [ "$3" ]; then
		local via="$2 % $3"
	fi
	sed -e "s|__BIRD_ROUTE__|$1|g" \
		-e "s/__BIRD_VIA__/$via/g" \
		conf/bird-routes.conf >> conf/bird6-routes.local.conf
}
