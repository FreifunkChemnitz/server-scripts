# Betrieb: Häufige Aufgaben

Ein kurzes Runbook für wiederkehrende Betriebsaufgaben, die über die reine
Erstinstallation (siehe [Haupt-README](../README.md)) hinausgehen. Hintergrund zu den
verwendeten Befehlen/Dateien steht in [Architektur](architektur.md) und
[Komponenten](komponenten.md).

## Neuen Backbone-Server hinzufügen

Die Peer-Liste `GRE_PEERS` ist eine **statische, pro Server gepflegte** Liste in
`general.local.conf` — sie wird nirgends automatisch zwischen den Servern synchronisiert.
Das ist die häufigste Fehlerquelle beim Hinzufügen eines neuen Servers:

1. Öffentliche IPv4 (`WANIP`) des neuen Servers festlegen und dessen
   `general.local.conf`, `bird.local.conf` etc. wie in der README beschrieben einrichten.
2. Den neuen Server **auf jedem bereits bestehenden Backbone-Server** in dessen
   `GRE_PEERS` (und ggf. `BATMAN_IFS`, siehe [IP-Adressplan](ip-adressplan.md#regionen-chemnitz-und-umland))
   eintragen — nicht nur in der Konfiguration des neuen Servers selbst.
3. Den neuen Server ebenfalls mit der vollständigen, aktuellen `GRE_PEERS`-Liste aller
   anderen Server konfigurieren.
4. `ffc-server.sh` (bzw. den `ffc`-Dienst) auf **allen** betroffenen Servern neu starten,
   damit die neuen GRE-Tunnel und BGP-Sessions aufgebaut werden.
5. Prüfen, ob der neue Server angekommen ist:
   - `grep gre- /proc/net/dev` — läuft das neue `gre-<name>`-Interface?
   - `birdc show protocols` / `birdc6 show protocols` — ist die neue BGP-Session `Established`?
   - `batctl o` (Originators) — taucht der neue Server/seine Clients im Mesh auf?

Ein geändertes `WANIP` eines *bestehenden* Servers erfordert dieselbe Sorgfalt: Es muss
in `GRE_PEERS` auf **allen** anderen Servern nachgezogen werden (siehe z. B. die Commits
„switched noether and kohn“ und „updated IP Adresses of new servers“ in der Historie
dieses Repositories).

## Toten GRE-Tunnel debuggen

Der Watchdog (`ffc-server.sh watchdog`, alle 5 Minuten über `gre_cron`) meldet einen
Tunnelausfall per Mail an `LOG_TO` mit der Meldung `GRE tunnel seems down: gre-<name>`.
Das Verfahren dahinter (`gre_check_tunnel` in `lib/gre.sh`): ein ICMPv6-Ping auf
`ff02::2%gre-<name>` (All-Routers-Multicast) muss mindestens eine `DUP`-Antwort liefern.

Vorgehen bei einer solchen Meldung:

1. `ip link show gre-<name>` — existiert das Interface überhaupt (lokales Problem, z. B.
   Server frisch neu gestartet, Tunnel noch nicht aufgebaut)?
2. `ping6 -c5 -i1 ff02::2%gre-<name>` manuell wiederholen — Bestätigung des Watchdog-Befunds.
3. Erreichbarkeit der `WANIP` des Peers direkt prüfen (`ping`/`traceroute`) — liegt es am
   darunterliegenden Internet-Pfad zwischen den beiden Rechenzentren?
4. Beim Betreiber des Peer-Servers nachfragen, ob dort `GRE_PEERS` noch die aktuelle
   eigene `WANIP` enthält (siehe „Neuen Backbone-Server hinzufügen“ oben) — eine veraltete
   IP auf der Gegenseite ist eine häufige Ursache.

## fastd-Schlüssel rotieren

1. Neues Schlüsselpaar erzeugen: `fastd --generate-key`.
2. Den neuen öffentlichen Schlüssel an das Freifunk-Chemnitz-Team melden, damit er in die
   `site.conf` der betroffenen Domäne übernommen wird (siehe Haupt-README).
3. Den privaten Schlüssel in `conf/fastd-secret.local.conf` ersetzen
   (Format: `secret "000...fff";`).
4. fastd neu starten (z. B. über einen Neustart des `ffc`-Dienstes). Bestehende
   Client-Verbindungen werden dabei getrennt und bauen sich mit dem neuen Schlüssel neu
   auf — kurzzeitiger Verbindungsabbruch für alle an diesem Server angemeldeten
   Freifunk-Router ist zu erwarten.

## Watchdog-Mails einordnen

`ffc-server.sh watchdog` läuft minütlich per Cron. Nur ein Teil der dabei aufgerufenen
`*_cron`-Funktionen kann tatsächlich eine Mail auslösen:

- `gre_cron` (alle 5 Minuten): meldet per `log_error` (→ Mail im Cron-Kontext) einen
  scheinbar toten GRE-Tunnel — siehe „Toten GRE-Tunnel debuggen“ oben. **Das ist aktuell
  die einzige Quelle für Watchdog-Mails.**
- `dnsmasq_cron`, `radvd_cron` (jede Minute): starten den jeweiligen Dienst still neu,
  falls er nicht läuft — ohne Logging oder Mail, auch bei Erfolg oder Misserfolg.

BIRD hat keine `*_cron`-Funktion mehr: die Ausnahme-/Regionalrouten werden beim Setup aus
`conf/routes/` gerendert, nicht mehr zur Laufzeit nachgeladen (Issue #7).

Eine Watchdog-Mail bedeutet also praktisch immer: ein GRE-Tunnel ist (vermeintlich)
ausgefallen.
