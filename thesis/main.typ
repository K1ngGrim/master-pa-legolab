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
   examiner: "Uwe Haneke",
   zusammenfassung: [#AbstractGerman],
   statutory_declaration: [Hiermit erkläre ich, dass ich die vorliegende Arbeit eigenständig und ohne fremde Hilfe angefertigt habe. Textpassagen, die wörtlich oder dem Sinn nach auf Publikationen oder Vorträgen anderer Autoren beruhen, sind als solche kenntlich gemacht. Die Arbeit wurde bisher keiner anderen Prüfungsbehörde vorgelegt und auch noch nicht veröffentlicht.],
)



= Einleitung

Die Vermittlung von Informatik- und Technikkenntnissen an Kinder und Jugendliche gewinnt zunehmend an Bedeutung. Plattformen wie die von LEGO entwickelten Education-Systeme bieten hierfür einen niedrigschwelligen Einstieg in Programmierung und Robotik. Durch vereinfachte Hardware und abstrahierte Softwareumgebungen ermöglichen sie erste praktische Erfahrungen ohne umfangreiche Vorkenntnisse.

Mit zunehmender Nutzung entsteht jedoch häufig der Wunsch, solche Systeme über ihren ursprünglichen Funktionsumfang hinaus zu erweitern. Insbesondere die Integration zusätzlicher Hardwarekomponenten eröffnet neue Möglichkeiten, etwa im Bereich der Visualisierung und Interaktion. Displays mit Touch-Funktionalität stellen in diesem Zusammenhang eine naheliegende Erweiterung dar, da sie eine direkte und intuitive Benutzerinteraktion ermöglichen.

Die Erweiterung bestehender Embedded-Systeme um externe Komponenten ist jedoch nicht trivial. Neben der reinen Hardwareanbindung spielen insbesondere Aspekte der Kommunikation und der Softwareintegration eine entscheidende Rolle. Unterschiedliche Systemkomponenten müssen koordiniert zusammenarbeiten, wobei vorhandene Schnittstellen und Laufzeitumgebungen bestimmte Einschränkungen mit sich bringen können.

Vor diesem Hintergrund beschäftigt sich die vorliegende Arbeit mit der Integration eines externen TFT-Touchscreen-Displays in ein bestehendes Embedded-System. Dabei liegt der Fokus insbesondere auf der Frage, wie eine effiziente und praktikable Nutzung des Displays unter gegebenen Systembedingungen ermöglicht werden kann.

== Problemstellung

Die Integration eines externen TFT-Touchscreen-Displays in die betrachtete Plattform wird durch mehrere technische Einschränkungen erschwert. Insbesondere die Kommunikationsschnittstelle zwischen den Systemkomponenten erlaubt ausschließlich eine unidirektionale Datenübertragung. Zudem ist die übertragbare Datenmenge pro Nachricht stark begrenzt.

Diese Rahmenbedingungen stehen im Gegensatz zu den Anforderungen interaktiver Benutzeroberflächen, die typischerweise eine flexible Datenübertragung sowie eine bidirektionale Kommunikation erfordern. Insbesondere die Verarbeitung von Benutzereingaben und die Übertragung komplexer Zustände stellen unter diesen Bedingungen eine Herausforderung dar.

Daraus ergibt sich die zentrale Problemstellung dieser Arbeit:
Wie kann ein externes TFT-Touchscreen-Display unter den gegebenen Einschränkungen effizient angebunden und für interaktive Anwendungen nutzbar gemacht werden?

== Zielsetzung der Arbeit

Ziel dieser Arbeit ist die Entwicklung einer Lösung zur Integration eines externen TFT-Touchscreen-Displays in ein bestehendes Embedded-System unter den gegebenen technischen Einschränkungen.

Hierzu soll ein Ansatz entwickelt werden, der eine strukturierte Kommunikation zwischen den beteiligten Systemkomponenten ermöglicht und gleichzeitig eine effiziente Nutzung des Displays erlaubt. Ein Schwerpunkt liegt dabei auf der Abstraktion der zugrunde liegenden Kommunikationsmechanismen, um die Nutzung des Displays aus Anwendungssicht zu vereinfachen.

Die entwickelte Lösung soll exemplarisch implementiert und hinsichtlich ihrer Funktionalität sowie ihrer praktischen Einsetzbarkeit bewertet werden.

== Aufbau der Arbeit

Die vorliegende Arbeit ist wie folgt aufgebaut:

Kapitel 2 vermittelt die notwendigen Grundlagen zu Embedded-Systemen, Kommunikationsmodellen sowie Remote-Procedure-Call-Ansätzen. Darüber hinaus werden grundlegende Konzepte zu Displays und Benutzeroberflächen eingeführt.

In Kapitel 3 erfolgt eine Analyse des Zielsystems sowie der bestehenden Rahmenbedingungen und Einschränkungen. Darauf aufbauend werden die Anforderungen an die Integration des Displays abgeleitet.

Kapitel 4 beschreibt die entwickelte Architektur des Systems und stellt die zentralen Komponenten sowie deren Zusammenspiel dar.

Kapitel 5 behandelt die Kommunikations- und Transportschicht, einschließlich des entwickelten Nachrichtenprotokolls.

Kapitel 6 widmet sich der Abstraktion des Displays sowie dem zugrunde liegenden Objektmodell.

Kapitel 7 beschreibt die Implementierung der entwickelten Lösung und die konkrete Anbindung des TFT-Touchscreens.

Kapitel 8 dient der Evaluation der Lösung hinsichtlich Funktionalität, Performance und Ressourcenverbrauch.

Abschließend werden in Kapitel 9 die Ergebnisse diskutiert sowie mögliche Erweiterungen aufgezeigt.


= Grundlagen

== Embedded Systeme und Micropython

== Kommunikationsmodelle in Embedded-Systemen

== Remote Procedure Calls (RPC)

== Objektorientierte Abstraktion verteilter Systeme




= Systemanalyse und Anforderungen

3.1 Zielsystem und Hardwareumgebung
3.2 Anforderungen an die Display-Integration
3.3 Kommunikationsanforderungen
3.4 Einschränkungen der Plattform
    3.4.1 Unidirektionale Kommunikation
    3.4.2 Begrenzte Paketgröße
    3.4.3 Einschränkungen von MicroPython / Pybricks



= Architektur des Systems

4.1 Zielsetzung der Architektur
4.2 Abstraktionsebenen
4.3 Komponentenmodell
    4.3.1 Interceptor
    4.3.2 Dispatcher
    4.3.3 Remote Object Proxies
4.4 Kommunikationsmodell
4.5 Datenfluss im System



= Kommunikations- und Transportschicht

5.1 Motivation und Randbedingungen
5.2 Interceptor-Abstraktion
5.3 Kommunikationsmodell
    5.3.1 Unidirektionale Verbindung
    5.3.2 Client-gesteuerter Rückkanal
5.4 Frame-basiertes Nachrichtenprotokoll
    5.4.1 Frame-Struktur
    5.4.2 Flags und Steuerinformationen
5.5 Fragmentierung und Rekonstruktion
5.6 Serialisierung der Nutzdaten
5.7 Zuverlässigkeitsmechanismen
5.8 Implementierung der Interceptor-Klassen
5.9 Bewertung der Transportschicht


= Abstraktion des Displays und Objektmodell

6.1 Anforderungen an die Display-Abstraktion
6.2 Konzept der Remote-Objekte
6.3 Abbildung grafischer Elemente (Label, Button, etc.)
6.4 Objekterzeugung und Lebenszyklus
6.5 Methodenaufrufe als RPC
6.6 Dispatcher-basierte Verarbeitung
6.7 Designentscheidungen
6.8 Bewertung des Objektmodells


= Implementierung

7.1 Überblick über die Implementierung
7.2 Anbindung des TFT-Touchscreens
7.3 Integration in das Zielsystem
7.4 Datenstrukturen und Hilfsklassen
    7.4.1 Frame
    7.4.2 Message
    7.4.3 Payload-Klassen
7.5 Ablauf eines vollständigen RPC-Aufrufs
7.6 Nebenläufigkeit und Verarbeitung
7.7 Fehlerbehandlung



= Evaluation

8.1 Funktionale Tests
8.2 Darstellung und Interaktion auf dem Display
8.3 Performance-Betrachtung
    8.3.1 Latenz
    8.3.2 Overhead durch Framing
8.4 Ressourcenverbrauch
8.5 Diskussion der Ergebnisse


= Diskussion und Ausblick

9.1 Limitierungen
    9.1.1 Kommunikationsmodell
    9.1.2 Performance
    9.1.3 Abstraktionsgrenzen
9.2 Übertragbarkeit auf andere Systeme
9.3 Mögliche Erweiterungen
    9.3.1 Bidirektionale Kommunikation
    9.3.2 Alternative Serialisierung
    9.3.3 Erweiterte UI-Konzepte




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
//#bibliography("biblio.bib")