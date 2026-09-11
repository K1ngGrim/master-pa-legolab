= Referenzimplementierung <sec:referenzimplementierung>

// Dieses Kapitel bildet den Entwurf aus Kap. 4 und 5 auf konkrete Hardware,
// eine konkrete Laufzeitumgebung und einen konkreten Bus ab. Hier stehen die
// Zahlen, die Kap. 5 bewusst offengelassen hat.

== Laufzeitumgebung

== Hardwareaufbau <sec:hardwareaufbau>

// SCOPE: bewusst knapp gehalten. Die Arbeit ist eine Informatikarbeit; der
// Hardwareaufbau dokumentiert einen funktionsfaehigen Traeger fuer die
// Software, er ist kein eigener Beitrag. Diese Abgrenzung gleich zu Beginn
// aussprechen - ein Abschnitt, der seinen Umfang selbst benennt, wird auch
// nicht an einem groesseren Massstab gemessen.
//
// Leitlinie fuer alle Entscheidungen: jeweils die einfachere Variante.
// Fertige Baugruppen statt eigener Schaltungsentwicklung, ESP32 als Modul
// statt bestuecktem Chip, handelsuebliches Displaymodul statt Panel.
// Bewertung steht in Kap. 7.4, nicht hier.

=== Aufbau und Komponenten

// - Verweis auf 3.1.2: warum externe Hardware ueberhaupt noetig ist
// - Drei Baugruppen und ihre Rollen: ESP32-Board, Displaymodul, Verbindung
// - Abgrenzung: funktionsfaehiger Aufbau mit handelsueblichen Baugruppen,
//   ausdruecklich keine eigene Schaltungsentwicklung, keine Serienreife
//   (EMV, Zulassung, Fertigungstoleranzen)
// - Busanbindung signalseitig nur UART auf zwei GPIOs, 3,3-V-Logik
// - Versorgung: 8 V auf M+ werden per power=True angefordert; Nebeneffekt
//   ist die Verkuerzung zulaessiger Modusnamen von 11 auf 5 Zeichen, was
//   die Kommandonamen des Protokolls begrenzt (siehe Kap. 3.4.2)

=== Signalzuordnung und Aufbau der Adapterplatine

// Erste Stufe: verbindet nur, entwirft nichts neu. Beide Baugruppen
// aufsteckbar, moeglichst ohne aktive Bauteile.
// - Tabelle: Funktion -> ESP32-Pin -> Displaymodul-Pin
// - SPI (MOSI, SCK, CS, DC, RST, Backlight), I2C fuer Touch (SDA, SCL, INT),
//   SD-Karte (CS, ggf. geteilter SPI-Bus), Bus (TX, RX)
// - Konflikte im Pin-Budget und wie sie aufgeloest wurden
// - Schaltplan, Steckerwahl, Bauhoehe, Fertigungsweg, Erstinbetriebnahme

=== Integrierte Trägerplatine

// Zweite Stufe: von drei Baugruppen auf zwei.
// - Motivation: weniger Steckverbinder (haeufigste Fehlerquelle im
//   Bildungseinsatz), geringere Bauhoehe
// - Was dadurch NICHT besser wird: Protokoll, Latenz und Software bleiben
//   unveraendert - das ausdruecklich sagen
// - Stromversorgung: 8 V von M+ auf 3,3 V; Dioden-ODER mit USB als
//   Startquelle, 8 V uebernehmen automatisch, sobald sie anliegen
// - Uebergabesequenz: Rueckmeldung, wann USB gezogen werden darf;
//   Brownout-Verhalten beim Wegfall der 8 V dokumentieren
// - Kurze Gegenueberstellung beider Stufen (Baugruppen, Steckverbinder,
//   Aufwand)

== Anbindung des Displays

== Bindung an den Bus

== Datenstrukturen

// ABGRENZUNG: hier die konkrete Auspraegung. Die Begruendung, warum ein Feld
// ueberhaupt existiert, steht in Kap. 5.4 und wird hier nicht wiederholt.

=== Frame

// - Byte-Layout und struct-Format
// - Feldbreiten als Instanziierung der Regeln aus Kap. 5.4
// - Opcode-Tabelle mit Zahlenwerten
// - Doppelbelegung des dritten Bytes (Opcode und Laenge je vier Bit) und
//   warum das eindeutig bleibt
// - Warum 16 Byte: Grenze der Pybricks-Anbindung -> 13 nutzbare Byte
//
// ENTWURFSREVISION dokumentieren (Belegstelle fuer die These aus 5.4.3):
// - erster Stand: 8-Byte-Header <BB5sB>, davon 5 Byte Zeichenkette fuer den
//   Frametyp; Laengenfeld fehlte, die Nutzlaenge wurde durch Abschneiden von
//   Nullbytes geraten -> an Textformate gebunden
// - Feldanalyse: welches Feld traegt wie viel Information wirklich
// - revidierter Stand: 3-Byte-Header <BBB>, 7 -> 13 nutzbare Byte
// - das Laengenfeld ist die Voraussetzung des Formatwechsels
// Bewertung nicht hier, sondern in Kap. 7.2.

=== Message

=== Payload

== Objektmodell in der Umsetzung

// Aus dem frueheren eigenstaendigen Kapitel hierher gezogen. Die konzeptionelle
// Begruendung steht in Kap. 4.2.4 und wird nicht wiederholt.
// - Abbildung grafischer Elemente auf Remote-Objekte
// - Objekterzeugung, Referenzen und Lebenszyklus, Registratur
// - Methodenaufrufe und Ereignisbehandlung
// - Designentscheidungen und ihre Folgen

== Ablauf eines vollständigen Aufrufs

== Nebenläufigkeit und Fehlerbehandlung
