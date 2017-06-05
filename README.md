# server-scripts

## Skripte installieren

```
# aptitude install git
$ mkdir /opt/freifunk
$ git clone https://github.com/FreifunkChemnitz/server-scripts.git /opt/freifunk/server-scripts
```

## Benötigte Software installieren
### B.A.T.M.A.N.

B.A.T.M.A.N. wird als Routing-Protokoll im Mesh genutzt. Die Version aus den Debian Paketquellen ist deutlich veraltet und nicht mehr nutzbar für unser Mesh.

Zuerst müssen die Abhängigkeiten für alfred batctl und batman_adv.
Für x64 z.B.:
```
# aptitude install build-essential linux-headers-amd64 pkg-config libnl-3-dev libnl-genl-3-dev libcap-dev
```

#### batman_adv
```
$ git clone $URL
$ cd path/to/batman
$ make
# make install
```

#### batctl
```
$ wget -O - $realeaseFromHomepage | tar xz
$ cd batctl
$ make
# make install
```

#### alfred
```
$ wget -O - $releaseFromHomepage | tar xz
$ cd alfred
$ make
# make install
```

### BIRD

Ist ein Routing Deamon zur Verbindung mit anderen Netzen.

```
# aptitude install bird
```

Wenn sys-V-init verwendet wird:
```
# update-rc.d bird disable
# update-rc.d bird6 disable
```

Wenn systemd verwendet wird:
```
# systemctl disable bird
# systemctl disable bird6
```


### fastd

fastd wird genutzt um ein VPN zwischen den Freifunk-Knoten und den Uplink-Servern aufzubauen

fastd ist in debian jessie noch nicht verfügbar. Daher muss erst noch jessie-backports eingerichtet werden.
```
deb http://httpredir.debian.org/debian/ jessie-backports main
```

Wenn sys-V-init verwendet wird:
```
# update-rc.d fastd disable
```

Wenn systemd verwendet wird:
```
# systemctl fastd disable
```

### dnsmasq

Der von uns genutzte DHCP Server und DNS Cache.

```
# aptitude install dnsmasq-base
```

### OpenVPN

OpenVPN wird genutzt, wenn sich mit dem VPN03 vom Freie Netze e.V. verbunden werden soll. Soll dies nicht gemacht werden, braucht man auch kein OpenVPN.

```
# aptitude install openvpn
```

Wenn sys-V-init verwendet wird:
```
# update-rc.d openvpn disable
```

Wenn systemd verwendet wird:
```
# systemctl openvpn disable
```

## Freifunk Chemnitz Skripte einrichten
### Konfigurationsdateien anpassen

```
cd /opt/freifunk/server-skripte/conf
cp bird.conf bird.local.conf
cp dnsmasq.conf dnsmasq.local.conf
cp general.conf general.local.conf
touch bird-routes.local.conf
touch vpn03.local.key
```

#### bird.local.conf
In der `bird.local.conf` muss `__BIRD_ROUTER_ID__` angepasst werden. Es ist mit mit 169.254.x.y zu ersetzen, wobei x das 3. Oktet und y das 4. Oktet der öffentlichen IPv4 des Servers sind. Wenn der Server die öffentliche IPv4 5.199.142.119 hat, wäre das 169.254.142.119.

`__BIRD_ROUTER_ASN__` muss durch das 3. und 4. Oktet der öffentlichen IPv4 ersetzt werden, wobei der Punkt wegzulassen ist. Zum Beispiel wird aus 5.199.142.119 dann 142119.

Auf Servern, die für das Chemnitzer Umland bestimmt sind ist das `route` unter `protocol static` anzupassen. Es muss auf `10.149.16.0/20` geändert werden.

#### dnsmasq.local.conf

`__DNSMASQ_SERVICE_IP__` muss durch eine freie IPv4 Adresse im Service Netzbereich von Freifunk Chemnitz ersetzt werden. Eine Adresse ist beim Team zu erfragen.

Auf Servern für das Chemnitzer Umland muss "dhcp-range" auf "10.149.17.0,10.149.30.255,255.255.240.0,30m"

#### general.local.conf

Alle Zeilen, die nicht geändert werden, sollten aus der Datei gelöscht werden.

`WANIP` ist durch die öffentliche IPv4 Adresse des Server zu ersetzen. `ip -4 addr show dev eth0`
`WANGW6` ist durch das IPv6 Gateway des Servers zu ersetzen. `ip -6 route show`
`SERVICE_ADDRESSES` ist durch die IPv4 Adresse zu ersetzen, die auch in der `dnsmasq.local.conf` als `__DNSMASQ_SERVICE_IP__` genutzt wurde.

Wenn die entsprechende Funktion genutzt werden soll, ist die Variable auf 1 zu setzen. Nicht zu nutzende Funktionen sind auf 0 zu setzen.
```
USE_FASTD="1"
USE_BIRD="1"
USE_DNSMASQ="0"
USE_RADVD="0"
USE_VPN03="0"
USE_MESHVIEWER="0"
```

`COUNTRY` ist auf den 2 stelligen ISO-Code des Landes zu ändern, in dem der Server betrieben wird.
`APIKEY` wird vom Freifunk Chemnitz Team vergeben und ist daher zu erfragen.
`WANGW` ist das IPv4 Gateway des Server. `ip route show`

`GRE_PEERS`, `LOG_DEBUG`, `LOG_TO` sollte gelöscht werden.

Im Umland ist `BATMAN_IFS` auf die für das Umland bestimmten Server zu ändern.


#### vpn03.local.key

Wenn der Server sich mit dem VPN03 vom Freie Netze e.V. verbinden soll, muss man sich einen Schlüssel unter https://wiki.freifunk.net/VPN03 organisieren und diesen als `vpn03.local.key` speichern.

### Skript aktivieren

#### eigenes init system aktivieren
```
# ln -s /opt/freifunk/server-scripts/initd-ffc.sh /etc/init.d/ffc
# update-rc.d ffc defaults
# update-rc.d ffc enable
```

#### watchdog aktivieren
Die Zeile `* * * * * /opt/freifunk/server-scripts/initd-ffc.sh watchdog` zu CRON hinzufügen. Zum Beispiel per `crontab -e -uroot`

