#import "template/template.typ": *
#import "@preview/wrap-it:0.1.1"
#import "@preview/glossarium:0.5.6": make-glossary, register-glossary, print-glossary, gls, glspl
#import "chapters/00_0_abkürzungen.typ": *
#import "chapters/00_01_abstract.typ": *

#show: make-glossary
#register-glossary(entry-list)

#show: project.with(
   title: "Projektarbeit",
   subtitle: "LEGO::Lab: Schnittstellen zu externen Displays",
   authors: (
         (
         name: "Florian Kaiser", 
         matriculation_number: "79728", 
         email: "kafl1018@h-ka.de"
         ),
      ),
   date: datetime.today().display("[day].[month].[year]"),
   company_logo: {},
   logo_left: "logo_left.png",
   logo_right: "logo_right.png",
   abstract: [],
   institution: "Hochschule Karlsruhe",
   study_program: "Informatik Master",
   custom_front_page: [],
   examiner: "Uwe Haneke, Matthias Mruzek-Vering",
   zusammenfassung: [#AbstractGerman],
   ai_usage_disclosure: true,
   statutory_declaration: [Hiermit erkläre ich, dass ich die vorliegende Arbeit eigenständig und ohne fremde Hilfe angefertigt habe. Textpassagen, die wörtlich oder dem Sinn nach auf Publikationen oder Vorträgen anderer Autoren beruhen, sind als solche kenntlich gemacht. Die Arbeit wurde bisher keiner anderen Prüfungsbehörde vorgelegt und auch noch nicht veröffentlicht.],
)

#include "chapters/01_introduction.typ"
#include "chapters/02_fundamentals.typ"
#include "chapters/03_related_work.typ"
#include "chapters/04_system_requirements.typ"
#include "chapters/05_architektur.typ"

= Kommunikations- und Transportschicht

== Motivation und Randbedingungen
== Interceptor-Abstraktion
== Anfragegetriebener Rückkanal
== Frame-basiertes Nachrichtenprotokoll

// ABGRENZUNG: hier NUR welche Information ein Frame tragen muss und warum.
// Konkrete Feldbreiten, Byte-Layout und Opcode-Werte gehoeren in Kap. 9.4.
// Entwurfsregeln in Abhaengigkeit der MTU formulieren, nicht in Zahlen -
// dann ist der Entwurf auf andere Verbindungen uebertragbar.

=== Frame-Struktur

// Je Feld die Notwendigkeit begruenden:
// - Nachrichtenzugehoerigkeit: mehrere Nachrichten unterscheiden, veraltete
//   Ergebnisse verwerfen
// - Position: Wiederzusammensetzung und Erkennung von Wiederholungen
// - Ende-Markierung: Empfaenger kennt die Gesamtlaenge nicht vorab
// - Art des Frames: derselbe Kanal traegt Daten und Steuerung
// - Abwaegung: weniger Headerbits <-> weniger gleichzeitige Nachrichten,
//   kleinere Maximalnachricht

=== Nutzlastlänge und Formatunabhängigkeit

// Wichtigster Abschnitt, weil hier eine Architektureigenschaft entschieden wird:
// - Transport liefert Bloecke fester Groesse -> Empfaenger kennt die genutzte
//   Laenge nicht
// - Ohne ausdrueckliche Laengenangabe muss sie aus dem Inhalt abgeleitet werden
//   (z.B. Fuellbytes entfernen) -> bindet die Schicht an textbasierte Formate
// - Regel statt Zahl: Laengenfeld braucht ceil(log2(MTU - Header + 1)) Bit

=== Kostenmodell der Rahmung

// Traegt spaeter die Evaluationsaussage in Kap. 10.2:
// - Nutzlasteffizienz = Nutzlast / uebertragene Bytes
// - Bei kleiner MTU wiegt die Aufrundung auf ganze Pakete schwerer als die
//   Kodierung der Nutzlast
// - Diese These hier aufstellen, in Kap. 10.2 messen
== Fragmentierung und Rekonstruktion
== Serialisierung der Nutzdaten
== Zuverlässigkeitsmechanismen


= Abstraktion des Displays und Objektmodell

== Anforderungen an die Display-Abstraktion
== Konzept der Remote-Objekte
== Abbildung grafischer Elemente
== Objekterzeugung, Referenzen und Lebenszyklus
== Methodenaufrufe und Ereignisbehandlung
== Designentscheidungen


= Hardwareaufbau

// SCOPE: bewusst knapp gehalten. Die Arbeit ist eine Informatikarbeit; der
// Hardwareaufbau dokumentiert einen funktionsfaehigen Traeger fuer die
// Software, er ist kein eigener Beitrag. Diese Abgrenzung gleich in 8.1
// aussprechen - ein Kapitel, das seinen Umfang selbst benennt, wird auch
// nicht an einem groesseren Massstab gemessen.
//
// Leitlinie fuer alle Entscheidungen: jeweils die einfachere Variante.
// Fertige Baugruppen statt eigener Schaltungsentwicklung, ESP32 als Modul
// statt bestuecktem Chip, handelsuebliches Displaymodul statt Panel.
// Bewertung steht gebuendelt in Kap. 10.5, nicht hier.

== Aufbau und Komponenten

// - Verweis auf 4.1.2: warum externe Hardware ueberhaupt noetig ist
// - Drei Baugruppen und ihre Rollen: ESP32-Board, Displaymodul, Verbindung
// - Abgrenzung des Kapitels: funktionsfaehiger Aufbau mit handelsueblichen
//   Baugruppen, ausdruecklich keine eigene Schaltungsentwicklung,
//   keine Serienreife (EMV, Zulassung, Fertigungstoleranzen)
// - Busanbindung signalseitig nur UART auf zwei GPIOs, 3,3-V-Logik
// - Versorgung: 8 V auf M+ werden per power=True angefordert; Nebeneffekt
//   ist die Verkuerzung zulaessiger Modusnamen von 11 auf 5 Zeichen, was
//   die Kommandonamen des Protokolls begrenzt

== Adapterplatine

// Erste Stufe: verbindet nur, entwirft nichts neu. Beide Baugruppen
// aufsteckbar, moeglichst ohne aktive Bauteile.

=== Signalzuordnung und Pinbelegung

// Der eigentlich dokumentationswuerdige Teil des Kapitels.
// - Tabelle: Funktion -> ESP32-Pin -> Displaymodul-Pin
// - SPI (MOSI, SCK, CS, DC, RST, Backlight), I2C fuer Touch (SDA, SCL, INT),
//   SD-Karte (CS, ggf. geteilter SPI-Bus), Bus (TX, RX)
// - Konflikte im Pin-Budget und wie sie aufgeloest wurden

=== Aufbau und Inbetriebnahme

// - Schaltplan, Steckerwahl, Bauhoehe
// - Fertigungsweg, Erstinbetriebnahme, aufgetretene Fehler

== Integrierte Traegerplatine

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
//   Aufwand) statt eigenem Abschnitt


= Referenzimplementierung <sec:referenzimplementierung>

== Laufzeitumgebung
== Anbindung des Displays
== Bindung an den Bus
== Datenstrukturen

// ABGRENZUNG: hier die konkrete Auspraegung. Die Begruendung, warum ein Feld
// ueberhaupt existiert, steht in Kap. 6.4 und wird hier nicht wiederholt.

=== Frame

// - Byte-Layout und struct-Format
// - Feldbreiten als Instanziierung der Regeln aus Kap. 6.4
// - Opcode-Tabelle mit Zahlenwerten
// - Doppelbelegung des unteren Nibbles (Laenge bei Daten-, Opcode bei
//   Steuerframes) und warum das eindeutig bleibt
// - Warum 16 Byte: Grenze der Pybricks-Anbindung -> 13 nutzbare Byte

=== Message
=== Payload
== Ablauf eines vollständigen Aufrufs
== Nebenläufigkeit und Fehlerbehandlung


= Evaluation

== Funktionaler Nachweis
== Overhead durch Rahmung
== Latenz und Anzahl der Übertragungen
== Ressourcenverbrauch
== Bewertung des Hardwareaufbaus

// Bewusst hier statt im Hardwarekapitel, damit alle Bewertungen an einer
// Stelle stehen (wie bei Kapitel 6 und 7 entschieden).
// Kurz halten, ein bis zwei Absaetze - passend zum Umfang von Kapitel 8:
// - Funktioniert der Aufbau unter realen Bedingungen (Stecken, Handhabung)?
// - Was die zweite Ausbaustufe praktisch gebracht hat
// - Was man anders machen wuerde

== Diskussion der Ergebnisse


= Diskussion und Übertragbarkeit

== Limitierungen
=== Kommunikationsmodell
=== Latenz und Durchsatz
=== Abstraktionsgrenzen
== Übertragbarkeit auf andere Verbindungsklassen
== Mögliche Erweiterungen
=== Ereignisgetriebener Rückkanal
=== Alternative Serialisierung
=== Weitere Peripherieklassen




= Fazit





#page(
  grid(
    [= Abbildungs- und Tabellenverzeichnis],
    inset: (x: 0pt, y: 20pt),
    outline(
      title: [Abbildungsverzeichnis],
      target: figure.where(kind: image),
    ),
    outline(
      title: [Tabellenverzeichnis],
      target: figure.where(kind: table),
    ),
    outline(
      title: [Code-Listings],

      target: figure.where(kind: raw),
    ),
    outline(
      title: [Prompt-Listings],

      target: figure.where(kind: "prompt"),
    ),
  ),
)

#pagebreak()
= Abkürzungsverzeichnis

#print-glossary(entry-list, disable-back-references: true)

#pagebreak()
#bibliography("biblio.bib")