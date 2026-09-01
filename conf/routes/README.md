# conf/routes/ – statische Ausnahme-/Länderrouten für BIRD (IPv4)

Diese Dateien ersetzen den früheren Laufzeit-Abruf von
`http://api.chemnitz.freifunk.net/request.php?region=$COUNTRY` (siehe
[Issue #7](https://github.com/FreifunkChemnitz/server-scripts/issues/7)).
Sie werden im Repo gepflegt und beim Setup (`ffc_start` → `bird_init`) zu
`conf/bird-routes.country.conf` gerendert. Diese generierte Datei ist in
`conf/.gitignore` und wird von `conf/bird.conf` per
`include "bird-routes.country.conf"` in `protocol static` eingebunden.

## Dateien

| Datei              | Gilt für                              | Herkunft (alte DB `ffc_network.routing`) |
|--------------------|---------------------------------------|------------------------------------------|
| `_global.conf`     | jeden Gateway, unabhängig von `COUNTRY` | `region IS NULL` bzw. `region='XX'`       |
| `<CC>.conf`        | Gateways mit `COUNTRY="<CC>"`          | `region='<CC>'` (z. B. `DE.conf`)         |

## Rendering

`bird_init` baut `conf/bird-routes.country.conf` als
`_global.conf` + `<COUNTRY>.conf` (falls vorhanden) und ersetzt anschließend
den Platzhalter `NEXTHOP` durch das lokale WAN-Gateway `$WANGW`
(`sed "s/NEXTHOP/$WANGW/g"`). Ohne gesetztes `$WANGW` bleibt die Datei leer.

## Format

BIRD-`protocol static`-Syntax, ein Prefix pro Zeile:

```
# Beschreibung
route 203.0.113.0/24 via NEXTHOP;   # über lokales WAN-Gateway routen
route 198.51.100.0/24 prohibit;     # überall blackholen (gehört in _global.conf)
```

## Ändern

1. Datei bearbeiten, committen, deployen.
2. Auf einem Gateway `ffc_start` (bzw. Neustart) löst das Re-Rendern aus.
   BIRD lädt die neue Konfiguration; ein manueller Reload geht per
   `birdc configure` oder `killall bird -s SIGHUP`.
