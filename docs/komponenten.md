# Komponenten

Dieses Dokument beschreibt jede Komponente des Backbone-Servers einzeln: was sie ist, wozu
sie dient und wo sie im Repository konfiguriert wird. Für das Zusammenspiel der Komponenten
siehe [Architektur](architektur.md) und [Backbone-Netzwerk](backbone-netzwerk.md).

## Externe Software

Diese Programme werden vom Server genutzt und in `README.md` installiert; die
`lib/*.sh`-Module (siehe unten) konfigurieren und steuern sie.

### B.A.T.M.A.N. advanced (`batman-adv`, `batctl`)

Mesh-Routing-Protokoll auf [Schicht 2](backbone-netzwerk.md#grundlagen-was-ist-ein-layer-2-netz)
(Kernelmodul `batman-adv` + Steuerwerkzeug `batctl`).
Es bildet das eigentliche Freifunk-Mesh: Alle GRE-Tunnel zu anderen Servern und alle
fastd-Verbindungen zu Freifunk-Routern werden als Slave-Interfaces in eine gemeinsame
batman-adv-Instanz (`bat0`) gehängt. batman-adv übernimmt Pfadwahl, Redundanz und
Schleifenvermeidung: Jeder Knoten flutet periodisch sogenannte Originator-Nachrichten
(OGMs) und muss dabei nur den jeweils besten nächsten Hop pro Ziel kennen, nicht die
komplette Netz-Topologie. Die Version aus den Debian-Paketquellen ist zu alt, daher wird
sie aus dem offiziellen `open-mesh.org`-Repo selbst gebaut.
([Kernel-Doku](https://docs.kernel.org/networking/batman-adv.html),
[Wikipedia](https://en.wikipedia.org/wiki/B.A.T.M.A.N.))

### alfred / batadv-vis

Zusatzwerkzeuge aus demselben `open-mesh`-Projekt. `alfred` verteilt beliebige
Metadaten (z. B. Knotennamen, Standort) im Mesh, `batadv-vis` exportiert die
Mesh-Topologie. Beides zusammen liefert die Rohdaten für die Freifunk-Kartendarstellung
(Meshviewer). Gestartet über `lib/batman.sh` bzw. `lib/meshviewer.sh`.
([open-mesh.org-Doku](https://www.open-mesh.org/doc/alfred/))

### fastd

Schlankes, für Embedded-Router geeignetes VPN auf
[Schicht 2](backbone-netzwerk.md#grundlagen-was-ist-ein-layer-2-netz) (`mode multitap`). Freifunk-Router
bauen darüber eine verschlüsselte Verbindung zum Server auf; jede neue Verbindung wird beim
Aufbau automatisch per `batctl interface add` in batman-adv eingehängt (siehe `on up`-Hook in
`conf/fastd.conf`). Damit ist fastd der Zugangspunkt der Endgeräte zum Mesh. Gesteuert über
`lib/fastd.sh`, ein Prozess pro CPU-Kern für bessere Lastverteilung.
([fastd-Doku](https://fastd.readthedocs.io/))

### GRE / `gretap` (Kernel-Feature, `iproute2`)

Kein separat zu installierendes Programm, sondern eine Tunnel-Technik des Linux-Kernels.
Zwischen den Backbone-Servern werden `gretap`-Tunnel (GRE mit Ethernet-Framing statt
reinem IP-GRE) aufgebaut — dadurch lassen sich die Tunnel wie normale Ethernet-Interfaces
direkt in batman-adv einhängen. Ergebnis: Ein
[vollvermaschtes](backbone-netzwerk.md#grundlagen-was-ist-eine-vollvermaschung)
[Layer-2-Netz](backbone-netzwerk.md#grundlagen-was-ist-ein-layer-2-netz) zwischen allen
Backbone-Servern über das öffentliche Internet. Konfiguriert über `lib/gre.sh`.
([Red Hat Developer: Linux-Tunnel-Interfaces](https://developers.redhat.com/blog/2019/05/17/an-introduction-to-linux-virtual-interfaces-tunnels))

### BIRD / BIRD6

Zwei getrennte Daemon-Binaries aus derselben BIRD-1.x-Codebasis: `bird` für IPv4, `bird6`
für IPv6 (BIRD 2.x hat diese Aufteilung später zu einem einzigen Binary zusammengeführt;
dieses Repository nutzt noch die klassische 1.x-Aufteilung, erkennbar an den getrennten
`lib/bird.sh`/`lib/bird6.sh`-Modulen und `bird.conf`/`bird6.conf`-Dateien).
Jeder Server betreibt darüber eine eigene BGP-Instanz und baut zu jedem GRE-Peer eine
interne BGP-Session auf. So lernen sich die Server gegenseitig Routen (eigene IP, Mesh-Netz,
Service-Adressen, Internet-Default-Route) und ermöglichen serverübergreifendes,
ausfallsicheres Routing zusätzlich zur reinen
[Layer-2](backbone-netzwerk.md#grundlagen-was-ist-ein-layer-2-netz)-Erreichbarkeit von batman-adv.
Konfiguriert über `lib/bird.sh`/`lib/bird6.sh`, nur aktiv wenn `USE_BIRD=1`.
([Ankündigung der Zusammenführung in BIRD 2](https://bird.network.cz/pipermail/bird-users/2011-August/002341.html))

### dnsmasq

DHCP-Server und DNS-Cache für Endgeräte im Mesh. Vergibt IPv4-Adressen aus
`10.149.0.0/16` an Clients auf `bat0` und dient als DNS-Resolver für die Domäne
`ffcmesh`. Nur auf ausgewählten Gateway-Servern aktiv (`USE_DNSMASQ=1`), gesteuert über
`lib/dnsmasq.sh`.

### radvd

Router-Advertisement-Daemon für IPv6. Kündigt auf `bat0` die IPv6-Präfixe
(`2001:bc8:3f13:ffc2::/64`, `ffc3::/64`) sowie DNS-Server per SLAAC an, sodass sich
Mesh-Clients selbst eine IPv6-Adresse konfigurieren können. Nur auf IPv6-Gateway-Servern
aktiv (`USE_RADVD=1`, erfordert `USE_BIRD=1`), gesteuert über `lib/radvd.sh`.

## Eigene Skripte (dieses Repository)

| Datei | Zweck |
|---|---|
| `ffc-server.sh` | Zentrales Steuerskript. Lädt Konfiguration und alle `lib/*.sh`-Module und bietet die Kommandos `start`, `stop`, `watchdog` an — orchestriert damit alle oben genannten Komponenten in der richtigen Reihenfolge. |
| `initd-ffc.sh` | Bindet `ffc-server.sh` als klassischen SysV-Init-Dienst (`/etc/init.d/ffc`) ein, damit der Server automatisch beim Boot startet. |
| `lib/log.sh` | Gemeinsames Logging für alle Module: Meldungen gehen nach syslog, im Watchdog-Kontext (`IS_CRON=1`) zusätzlich per Mail an `LOG_TO`. |
| `lib/gre.sh` | Baut die GRE-Tunnel zu allen in `GRE_PEERS` gelisteten Servern auf/ab und prüft im Watchdog per ICMPv6-Ping, ob sie noch erreichbar sind. |
| `lib/batman.sh` | Initialisiert batman-adv, hängt GRE- und fastd-Interfaces ein, konfiguriert `bat0` (Service-Adressen, Bridge-Loop-Avoidance, Bonding) und startet `alfred`/`batadv-vis`. |
| `lib/fastd.sh` | Startet/stoppt die fastd-Prozesse für den Client-Zugang. |
| `lib/bird.sh` / `lib/bird6.sh` | Generieren die BIRD-/BIRD6-Konfiguration aus den Templates in `conf/`, tragen BGP-Peers und Routen ein, richten Policy-Routing (Tabelle 100) und NAT ein, laden per Watchdog die Geoblocking-Routen nach. |
| `lib/dnsmasq.sh` | Generiert die dnsmasq-Konfiguration und startet/überwacht den Dienst. |
| `lib/radvd.sh` | Startet/überwacht radvd und trägt die IPv6-Default-Route in BIRD6 ein. |
| `lib/meshviewer.sh` | Startet `alfred`/`batadv-vis` eigenständig, falls der Server unabhängig von `lib/batman.sh` primär als Meshviewer-Datenquelle dienen soll. |

## Konfigurationsdateien (`conf/`)

| Datei | Zweck |
|---|---|
| `general.conf` (+ `general.local.conf`) | Zentrale Server-Konfiguration: Netzwerk-Interface/IP, Feature-Flags (`USE_*`), GRE-Peer-Liste, Geoblocking-Einstellungen. Die `.local.conf`-Variante enthält die serverspezifischen, nicht versionierten Werte. |
| `bird.conf`, `bird6.conf` | Templates für die BIRD-/BIRD6-Hauptkonfiguration inkl. Policy-Routing-Tabelle `ffc`. |
| `bird-peers.conf` | Template für eine einzelne BGP-Peer-Definition, wird pro GRE-Peer in `bird-peers.local.conf`/`bird6-peers.local.conf` dupliziert. |
| `bird-routes.conf` | Template für eine einzelne statische Route, wird pro Service-Adresse dupliziert. |
| `fastd.conf` | fastd-Konfiguration inkl. der Hooks, die neue Client-Interfaces automatisch in batman-adv einhängen. |
| `dnsmasq.conf` | Template für DHCP-Range, DNS-Domäne und Gateway-Optionen im Mesh. |
| `radvd.conf` | Router-Advertisement-Konfiguration für die beiden IPv6-Mesh-Präfixe. |
| `sysctl.conf` | Kernel-Netzwerkparameter (IP-Forwarding, rp_filter, Connection-Tracking-Limits), die beim Start angewendet werden. |

## Quellen

- [batman-adv — The Linux Kernel documentation](https://docs.kernel.org/networking/batman-adv.html)
- [B.A.T.M.A.N. — Wikipedia](https://en.wikipedia.org/wiki/B.A.T.M.A.N.)
- [Batman-adv Bridge Loop Avoidance — open-mesh.org](https://www.open-mesh.org/doc/batman-adv/Bridge-loop-avoidance.html)
- [A.L.F.R.E.D. — open-mesh.org](https://www.open-mesh.org/doc/alfred/)
- [fastd Documentation](https://fastd.readthedocs.io/)
- [An introduction to Linux virtual interfaces: Tunnels — Red Hat Developer](https://developers.redhat.com/blog/2019/05/17/an-introduction-to-linux-virtual-interfaces-tunnels)
- [Merging bird and bird6 — bird-users Mailingliste](https://bird.network.cz/pipermail/bird-users/2011-August/002341.html)
- [BIRD2 BGP Configuration on a Linux VPS](https://www.virtua.cloud/learn/en/tutorials/bird2-bgp-configuration-linux-vps)
