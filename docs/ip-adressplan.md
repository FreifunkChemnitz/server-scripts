# IP-Adressplan

Zentrale Referenz für alle IPv4-/IPv6-Adressbereiche und Adress-Schemata, die im Backbone
verwendet werden. Die Details zu den einzelnen Bausteinen stehen in
[Backbone-Netzwerk](backbone-netzwerk.md) und [Komponenten](komponenten.md); dieses
Dokument fasst nur die Zahlen an einem Ort zusammen.

## Regionen: Chemnitz und Umland

Das Freifunk-Chemnitz-Mesh ist in zwei Regionen mit eigenen Adressbereichen aufgeteilt:
die Stadt Chemnitz und das „Chemnitzer Umland“. Ein Server wird durch seine Konfiguration
(`conf/bird.local.conf`, `conf/dnsmasq.local.conf`, `BATMAN_IFS` in `general.local.conf`)
einer der beiden Regionen zugeordnet — es gibt keinen eigenen Feature-Flag dafür, sondern
schlicht andere Werte in denselben Konfigurationsdateien.

| | Chemnitz (Standard) | Umland |
|---|---|---|
| Statische BIRD-Route (`protocol static` in `bird.conf`) | `10.149.0.0/20` | `10.149.16.0/20` |
| DHCP-Range (`dnsmasq.conf`) | `10.149.1.0`–`10.149.14.255` (`/20`, 30 min Lease) | `10.149.17.0`–`10.149.30.255` (`/20`, 30 min Lease) |
| `BATMAN_IFS` | GRE-Interfaces der Chemnitz-Backbone-Server | GRE-Interfaces der für das Umland zuständigen Server |

Beide Regionen liegen im selben `10.149.0.0/16`, das insgesamt über BIRD als Mesh-Netz
announced wird (siehe [Backbone-Netzwerk](backbone-netzwerk.md)) — die Aufteilung in zwei
`/20`-Bereiche dient nur der Adressvergabe innerhalb des Mesh, nicht einer Trennung auf
Routing- oder batman-adv-Ebene.

## IPv4-Adressbereiche

| Bereich | Zweck |
|---|---|
| `10.149.0.0/16` | Gesamtes Mesh-Netz (Freifunk-Router und Endgeräte), über BIRD announced. |
| `10.149.0.0/20` | Statische Route/DHCP-Pool für die Region Chemnitz (siehe oben). |
| `10.149.16.0/20` | Statische Route/DHCP-Pool für die Region Umland (siehe oben). |
| `SERVICE_ADDRESSES` (frei, pro Server) | Adresse(n) auf `bat0`, z. B. DNS-/DHCP-Gateway-Adresse; wird beim Freifunk-Chemnitz-Team erfragt und in `general.local.conf` sowie `dnsmasq.local.conf` eingetragen. |
| `169.254.<3. Oktett>.<4. Oktett>` | Link-Local-Adresse eines Backbone-Servers auf seinen GRE-Tunnel-Interfaces, abgeleitet aus den letzten beiden Oktetten seiner öffentlichen IPv4. Dient nur als BGP-Session-Endpunkt, nicht dem Mesh-Verkehr. |
| `__WANIP__/32` | Die öffentliche IPv4 des jeweiligen Servers selbst, wird als eigene Route ins Mesh announced. |

## IPv6-Adressbereiche

| Bereich | Zweck |
|---|---|
| `2001:bc8:3f13:ffc2::/64` | IPv6-Präfix, das `radvd` auf `bat0` per Router Advertisement announced (SLAAC für Mesh-Clients). |
| `2001:bc8:3f13:ffc3::/64` | IPv6-Präfix der Region Umland, das `radvd` auf `bat0` per Router Advertisement announced. Läuft auf den für Umland zuständigen Backbone-Servern (aktuell descartes, kohn) — `USE_RADVD` muss dort in `general.local.conf` aktiviert werden. |
| `fe80::ffc:<hex 3. Oktett>:<hex 4. Oktett>/64` | IPv6-Link-Local-Adresse eines Backbone-Servers auf seinen GRE-Tunnel-Interfaces, das IPv6-Gegenstück zur `169.254.x.y`-Adresse oben. |
| DNS-Resolver (RDNSS, `radvd.conf`) | `2001:0bc8:3f13:ffc2::1` und `…ffc2::53` (mesh-interne Resolver), sowie `2a01:4f8:110:1405::1` (externer Resolver) werden den Mesh-Clients announced. |

## Abgeleitete Kennungen

| Kennung | Ableitung | Zweck |
|---|---|---|
| BIRD-Router-ID | `169.254.<3. Oktett>.<4. Oktett>` der öffentlichen IPv4 | Eindeutige Router-ID pro Server ohne zentrale Vergabestelle. |
| BGP-AS-Nummer | `<3. Oktett><4. Oktett>` der öffentlichen IPv4 (z. B. aus `5.199.142.119` wird AS `142119`) | Eindeutige AS-Nummer pro Server für die BGP-Vollvermaschung, ebenfalls ohne zentrale Vergabestelle. |

## DHCP/DNS-Optionen (`dnsmasq.conf`)

| Option | Wert | Zweck |
|---|---|---|
| `dhcp-option=3` | `SERVICE_ADDRESSES[0]` | Default-Gateway für Mesh-Clients. |
| `dhcp-option=6` | `10.149.0.1`, `SERVICE_ADDRESSES[0]` | DNS-Server für Mesh-Clients — bevorzugt ein mesh-interner (Site-Local) Resolver vor dem eigenen Server, statt eines rein externen. |
| `dhcp-option=119` | `ffcmesh` | DNS-Suchdomäne im Mesh. |
