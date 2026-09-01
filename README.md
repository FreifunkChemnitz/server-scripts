# server-scripts

## Dokumentation

Eine Übersicht über die Architektur des Repositories sowie eine Erklärung, wie das
Freifunk-Backbone auf Netzwerkebene funktioniert, findet sich unter [`docs/`](docs/README.md).

## Skripte installieren

```
# aptitude install git
$ mkdir /opt/freifunk
$ git clone https://gitlab.com/FreifunkChemnitz/server-scripts.git /opt/freifunk/server-scripts
```

## Benötigte Software installieren
### B.A.T.M.A.N.

B.A.T.M.A.N. wird als Routing-Protokoll im Mesh genutzt. Die Version aus den Debian Paketquellen ist deutlich veraltet und nicht mehr nutzbar für unser Mesh.

Zuerst müssen die Abhängigkeiten für alfred, batctl und batman_adv installiert werden.
Für x86_64 z.B.:
```
# aptitude install build-essential linux-headers-amd64 pkg-config libnl-3-dev libnl-genl-3-dev libcap-dev
```

#### batman_adv
```
$ git clone -b maint git://git.open-mesh.org/batman-adv.git
$ cd path/to/batman
$ make
# make install
```

#### batctl
```
$ git clone -b maint git://git.open-mesh.org/batctl.git
$ cd batctl
$ make
# make install
```

#### alfred
```
$ git clone git://git.open-mesh.org/alfred.git
$ cd alfred
$ make
# make install
```

### BIRD

Ist ein Routing Deamon zur Verbindung mit anderen Netzen.

```
# aptitude install bird
```

Die BIRD-/BIRD6-Konfiguration (`/etc/bird/bird.conf`, `/etc/bird/bird6.conf`,
`/etc/bird/bird-routes.country.conf`) und die `bird`/`bird6`-Dienste werden vom
Ansible-Playbook [ffc-mash](https://github.com/FreifunkChemnitz/ffc-mash) verwaltet
(Rolle `ffc_vpn_gateway`), nicht von diesen Skripten. `lib/bird.sh` / `lib/bird6.sh`
richten nur noch das Policy-Routing (Tabelle 100) und NAT ein.

```
# systemctl enable bird
# systemctl enable bird6
```


### fastd

fastd wird genutzt um ein VPN zwischen den Freifunk-Knoten und den Uplink-Servern aufzubauen

fastd ist in debian jessie noch nicht verfügbar. Daher muss erst noch jessie-backports eingerichtet werden.
Dazu fügt man in /etc/apt/sources.list.d/backports.list folgendes ein:
```
deb http://httpredir.debian.org/debian/ jessie-backports main
```
Anschließend führt man noch folgendes aus:
```
# apt-get update
# apt-get install fastd
```

Wenn sys-V-init verwendet wird:
```
# update-rc.d fastd disable
```

Wenn systemd verwendet wird:
```
# systemctl disable fastd
```

Nach der Installation muss ein Schlüsselpaar erzeugt werden per:
```
fastd --generate-key	
```

Der public Key kommt in die site.conf der Domäne, in welcher der Server arbeiten soll.
Der private Key wird in der Datei fastd-secret.local.conf in folgender Form hinterlegt:
```
secret "000...fff";
```

### dnsmasq

Der von uns genutzte DHCP Server und DNS Cache.

```
# aptitude install dnsmasq-base
```

### radvd

Der von uns genutzte Service für IPv6 router advertisments. Dieser ist nur notwendig, wenn der Server ein IPv6-Gateway sein soll.

```
# aptitude install radvd
```

Wenn sys-V-init verwendet wird:
```
# update-rc.d radvd disable
```

Wenn systemd verwendet wird:
```
# systemctl disable radvd
```

## Freifunk Chemnitz Skripte einrichten
### Konfigurationsdateien anpassen

```
cd /opt/freifunk/server-scripts/conf
cp dnsmasq.conf dnsmasq.local.conf
cp general.conf general.local.conf
```

#### BIRD / BGP

Die BIRD-Konfiguration wird nicht mehr hier gepflegt, sondern vom Ansible-Playbook
[ffc-mash](https://github.com/FreifunkChemnitz/ffc-mash) (Rolle `ffc_vpn_gateway`)
nach `/etc/bird/` gerendert – inklusive Router-ID/ASN (aus der öffentlichen IPv4),
BGP-Peers, Mesh-Route (Umland: `ffc_vpn_gateway_bird_mesh_route_v4: 10.149.16.0/20`)
und der statischen Länder-/Ausnahmerouten. `lib/bird.sh` richtet nur noch
Policy-Routing (Tabelle 100) und NAT ein.

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
USE_MESHVIEWER="0"
```

Das Land des Servers (früher `COUNTRY`) und die Länder-/Ausnahmerouten werden jetzt
im ffc-mash-Playbook gepflegt (`ffc_vpn_gateway_country`,
`roles/custom/ffc_vpn_gateway/files/bird-routes/`).

`GRE_PEERS`, `LOG_DEBUG`, `LOG_TO` sollte gelöscht werden.

Im Umland ist `BATMAN_IFS` auf die für das Umland bestimmten Server zu ändern.


### Skript aktivieren

#### eigenes init system aktivieren
```
# ln -s /opt/freifunk/server-scripts/initd-ffc.sh /etc/init.d/ffc
# update-rc.d ffc defaults
# update-rc.d ffc enable
```

#### watchdog aktivieren
Die Zeile `* * * * * /opt/freifunk/server-scripts/initd-ffc.sh watchdog` zu CRON hinzufügen. Zum Beispiel per `crontab -e -uroot`

