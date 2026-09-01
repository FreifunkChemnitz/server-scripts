# Sicherheitsmodell

Dieses Dokument beschreibt, welche Verbindungen im Backbone verschlüsselt/authentifiziert
sind und welche nicht, sowie das Vertrauensmodell, das sich daraus ergibt. Es fasst
Beobachtungen aus den Konfigurationsdateien zusammen — die dahinterliegenden
Design-Entscheidungen (z. B. warum genau so und nicht anders) sind nicht aus dem Code
ableitbar und sollten im Zweifel beim Freifunk-Chemnitz-Team erfragt werden.

## fastd (Freifunk-Router ↔ Server): verschlüsselt, aber offen zugänglich

`conf/fastd.conf` konfiguriert zwei unabhängige Eigenschaften:

- **Verschlüsselung:** `method "salsa2012+umac"` verschlüsselt die Verbindung (Salsa2012
  als Stream-Cipher) und sichert sie gegen Verfälschung ab (UMAC als Message
  Authentication Code). Der Datenverkehr zwischen einem Freifunk-Router und dem Server ist
  also vertraulich und manipulationsgeschützt.
- **Zugangskontrolle:** `on verify "true"` lässt **jeden** Client mit einem gültigen
  fastd-Schlüsselpaar zu — der Server prüft nicht, ob der öffentliche Schlüssel eines
  Knotens vorher irgendwo hinterlegt wurde. Das passt zum Grundprinzip eines offenen
  Freifunk-Netzes: Ein neuer Knoten kann ohne Anmeldung beim Server-Betreiber beitreten,
  sobald er den öffentlichen Schlüssel *des Servers* kennt (verteilt über die
  Firmware-Konfiguration der jeweiligen Domäne).

Das bedeutet: Es findet keine Autorisierungsprüfung statt, welche Person oder welches
Gerät sich verbindet — jeder mit passender Firmware kann Teilnehmer werden. Die
Verschlüsselung schützt die Vertraulichkeit der Verbindung, nicht die Frage, *wer* sie
aufbaut.

## GRE-Tunnel (Backbone-Server ↔ Backbone-Server): unverschlüsselt

Die GRE/`gretap`-Tunnel aus `lib/gre.sh` bieten **keine** eingebaute Verschlüsselung oder
Authentifizierung — GRE kapselt Frames lediglich, ohne sie kryptografisch zu schützen.
Ebenso enthält `conf/bird-peers.conf` keine BGP-Session-Authentifizierung (z. B. ein
MD5-Passwort). Wer Zugriff auf den Netzwerkpfad zwischen zwei Backbone-Servern im
Internet bekommt, kann den GRE- und BGP-Verkehr zwischen ihnen technisch mitlesen oder
manipulieren.

Das ist ein bewusster Unterschied zur fastd-Strecke: Backbone-Server werden — anders als
die anonymen Freifunk-Router — vom Team selbst betrieben und administriert. Das
Sicherheitsmodell verlässt sich hier offenbar auf die Absicherung der Server selbst
(SSH-Zugriff, Firewalling, Auswahl vertrauenswürdiger Hoster) statt auf
Transportverschlüsselung zwischen ihnen. Diese Einschätzung ist eine Ableitung aus der
Konfiguration, keine im Repository dokumentierte Policy-Aussage.

## BIRD-Ausnahmerouten: statisch statt Laufzeit-Fetch

Die Ausnahme-/Länderrouten für BIRD (`conf/routes/`, gerendert nach
`conf/bird-routes.country.conf`) werden im Repo gepflegt und beim Setup gerendert.
Früher lud `bird_cron` sie alle 5 Minuten per **unverschlüsseltem `http://`** von
`api.chemnitz.freifunk.net` nach und ließ BIRD per `SIGHUP` neu laden — ein On-Path-Angreifer
hätte darüber statische Routen in die Routingtabelle der Gateways injizieren können
(Blackhole oder Umleitung übers lokale WAN). Dieser Pfad ist mit Issue #7 entfallen.

## Zusammenfassung

| Strecke | Verschlüsselt? | Zugangskontrolle? |
|---|---|---|
| Freifunk-Router ↔ Server (fastd) | Ja (`salsa2012+umac`) | Nein (`on verify "true"`, jeder mit Schlüsselpaar) |
| Backbone-Server ↔ Backbone-Server (GRE) | Nein | Nein (statische `GRE_PEERS`-Liste, keine Authentifizierung auf dem Tunnel selbst) |
| Backbone-Server ↔ Backbone-Server (BGP) | Nein | Nein (keine Session-Authentifizierung in `bird-peers.conf`) |

Praktische Konsequenz für den Betrieb: Die Sicherheit des Backbones hängt maßgeblich
davon ab, dass ausschließlich vertrauenswürdige, vom Team kontrollierte Server als
GRE-/BGP-Peers in `GRE_PEERS` eingetragen werden — anders als beim fastd-Zugang für
Endgeräte gibt es hier keine kryptografische Absicherung, die einen kompromittierten oder
böswilligen Peer nachträglich ausschließen würde.
