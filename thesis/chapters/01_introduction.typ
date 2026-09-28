= Einleitung <sec:einleitung>

Die Vermittlung von Informatik- und Technikkenntnissen an Kinder und Jugendliche gewinnt zunehmend an Bedeutung. Plattformen wie die Education-Systeme von LEGO bieten hierfür einen niedrigschwelligen Einstieg in Programmierung und Robotik. Durch vereinfachte Hardware und abstrahierte Softwareumgebungen sind erste praktische Erfahrungen auch ohne umfangreiche Vorkenntnisse möglich.

Mit zunehmender Nutzung entsteht häufig der Wunsch, solche Systeme über ihren ursprünglichen Funktionsumfang hinaus zu erweitern. Insbesondere zusätzliche Hardwarekomponenten eröffnen neue Möglichkeiten, etwa bei der Visualisierung und der Interaktion. Displays mit Touch-Funktionalität sind in diesem Zusammenhang eine naheliegende Erweiterung, da sie eine direkte und intuitive Bedienung ermöglichen.

Die Erweiterung bestehender Embedded-Systeme um externe Komponenten ist allerdings nicht trivial. Neben der reinen Hardwareanbindung spielen vor allem die Kommunikation und die Integration in die bestehende Software eine wichtige Rolle. Die beteiligten Komponenten müssen koordiniert zusammenarbeiten, wobei die vorhandenen Schnittstellen und Laufzeitumgebungen oft Einschränkungen mit sich bringen.

Vor diesem Hintergrund beschäftigt sich die vorliegende Arbeit mit der Frage, wie sich externe Peripherie an ein solches System anbinden lässt, wenn die verfügbare Verbindung dafür nur eingeschränkt geeignet ist. Im Mittelpunkt steht dabei weniger die Ansteuerung eines einzelnen Geräts als eine Softwareschicht, die zwischen Anwendung und Verbindung vermittelt und die Eigenheiten der Übertragung vor der Anwendung verbirgt. Als Anwendungsfall dient die Anbindung eines @tft\-Touchscreen-Displays, an dem der Entwurf entwickelt, umgesetzt und bewertet wird.

== Problemstellung <sec:problemstellung>

Die Anbindung zusätzlicher Peripherie an eine solche Plattform wird durch drei technische Einschränkungen erschwert, die gemeinsam auftreten und sich gegenseitig verstärken.

Erstens ist die Verbindung zwischen den Systemkomponenten anfragegetrieben. Sie ist zwar in beide Richtungen nutzbar, eine Übertragung kann aber nur die übergeordnete Seite anstoßen, während die untergeordnete Seite ausschließlich antwortet. Zweitens ist die je Paket übertragbare Datenmenge sehr klein und fest vorgegeben, sodass Nachrichten üblicher Größe nicht in ein einzelnes Paket passen. Drittens stehen stark beschränkte Laufzeitumgebungen zur Verfügung, die zumindest auf einer Seite weder einen vollständigen Netzwerkstack noch die üblichen Mittel nebenläufiger Programmierung bereitstellen.

Diese Rahmenbedingungen stehen im Gegensatz zu den Anforderungen interaktiver Benutzeroberflächen, die eine flexible Übertragung strukturierter Daten und eine zeitnahe Rückmeldung von Benutzereingaben voraussetzen. Gerade die Verarbeitung von Eingaben und die Übertragung zusammengesetzter Zustände sind unter diesen Bedingungen eine Herausforderung.

Daraus ergibt sich die zentrale Problemstellung dieser Arbeit:
Wie lässt sich eine Middleware entwerfen, die entfernte Objekte über eine anfragegetriebene Verbindung mit sehr kleiner Paketgröße auf beschränkten Laufzeitumgebungen transparent nutzbar macht?

Die Frage ist dabei nicht an eine bestimmte Plattform gebunden, denn die Kombination aus anfragegetriebener Übertragung, kleiner Paketgröße und beschränkter Laufzeitumgebung tritt in verschiedenen Ausprägungen auf, wie @sec:verallgemeinerung zeigt.

== Zielsetzung der Arbeit

Ziel dieser Arbeit ist der Entwurf einer Middleware, die entfernte Objekte über eine Verbindung der beschriebenen Art transparent nutzbar macht.

Der Entwurf soll die drei genannten Einschränkungen auf wenige Schichten eingrenzen, sodass sie oberhalb davon nicht mehr sichtbar sind. Dazu gehören:

- die Zerlegung von Nachrichten in Pakete und deren Rahmung,
- ein anfragegetriebener Rückkanal für Ergebnisse und Ereignisse
- sowie eine Abstraktion, die entfernte Objekte wie lokale erscheinen lässt.

Ein weiterer Schwerpunkt liegt darauf, den Entwurf vom konkreten Übertragungsweg zu lösen, damit er auf andere Verbindungen derselben Klasse übertragbar bleibt.

Die Bewertung stützt sich auf drei Kriterien. Das erste ist der funktionale Nachweis, dass sich eine interaktive Oberfläche über die entwickelte Abstraktion umsetzen lässt. Das zweite ist der Übertragungsaufwand je Aufruf, gemessen in benötigten Paketen und in der daraus folgenden Verzögerung. Das dritte ist der Ressourcenverbrauch, vor allem auf der Steuereinheit, deren Laufzeitumgebung am stärksten eingeschränkt ist.

== Aufbau der Arbeit

Die vorliegende Arbeit ist wie folgt aufgebaut.

Kapitel 2 führt die Grundlagen zum entfernten Prozeduraufruf, zur Serialisierung und zur Kommunikation eingebetteter Systeme ein. Anschließend ordnet es die Arbeit in bestehende Ansätze ein und benennt die Lücke, die sie schließt.

Kapitel 3 analysiert das Zielsystem und leitet die Anforderungen an die Display-Integration und an die Kommunikation ab. Den Anforderungen werden die Einschränkungen der Plattform gegenübergestellt, bevor das Kapitel mit einer Verallgemeinerung des Problemraums schließt.

Kapitel 4 beschreibt die Architektur mit ihrem Schichtenmodell, den wiederkehrenden Rollen im Entwurf und dem Kommunikationsmodell. Kapitel 5 vertieft den Entwurf der Transport- und der Kommunikationsschicht, wobei beide Kapitel auf der konzeptionellen Ebene bleiben.

Kapitel 6 stellt die Referenzimplementierung vor und bildet den Entwurf auf die konkrete Hardware, die Laufzeitumgebungen und den Bus ab. Kapitel 7 bewertet die Lösung hinsichtlich Funktionalität, Übertragungsaufwand und Ressourcenverbrauch. Kapitel 8 diskutiert die Grenzen des Ansatzes und seine Übertragbarkeit auf andere Verbindungen und fasst die Ergebnisse zusammen. Der Anhang enthält das Beispielprogramm der Steuereinheit und den Schaltplan der Adapterplatine.
