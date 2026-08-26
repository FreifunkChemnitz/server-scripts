# Dokumentation

Diese Dokumentation ergänzt die Installationsanleitung in der [Haupt-README](../README.md) um
einen Überblick über die Architektur des Repositories und die dahinterliegenden Netzwerkkonzepte.

- [Architektur](architektur.md) — Kernkomponenten des Repositories, ihre Beziehungen
  zueinander und der Start-/Stop-/Watchdog-Ablauf.
- [Komponenten](komponenten.md) — jede einzelne Komponente (Software und eigene Skripte)
  im Detail: was sie ist und wozu sie dient.
- [Backbone-Netzwerk](backbone-netzwerk.md) — wie GRE, batman-adv, fastd und BGP (BIRD)
  zusammen das Freifunk-Chemnitz-Backbone bilden.
- [IP-Adressplan](ip-adressplan.md) — alle IPv4-/IPv6-Adressbereiche und -Schemata an
  einem Ort, inklusive der Aufteilung in die Regionen Chemnitz und Umland.
- [Sicherheitsmodell](sicherheitsmodell.md) — welche Verbindungen verschlüsselt und/oder
  zugangskontrolliert sind, und welches Vertrauensmodell sich daraus ergibt.
- [Betrieb](betrieb.md) — Runbook für wiederkehrende Aufgaben: neuen Server hinzufügen,
  toten GRE-Tunnel debuggen, fastd-Schlüssel rotieren, Watchdog-Mails einordnen.
