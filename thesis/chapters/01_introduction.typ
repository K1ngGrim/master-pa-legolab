= Einleitung <sec:einleitung>

Die Vermittlung von Informatik- und Technikkenntnissen an Kinder und Jugendliche gewinnt zunehmend an Bedeutung. Plattformen wie die von LEGO entwickelten Education-Systeme bieten hierfür einen niedrigschwelligen Einstieg in Programmierung und Robotik. Durch vereinfachte Hardware und abstrahierte Softwareumgebungen ermöglichen sie erste praktische Erfahrungen ohne umfangreiche Vorkenntnisse.

Mit zunehmender Nutzung entsteht jedoch häufig der Wunsch, solche Systeme über ihren ursprünglichen Funktionsumfang hinaus zu erweitern. Insbesondere die Integration zusätzlicher Hardwarekomponenten eröffnet neue Möglichkeiten, etwa im Bereich der Visualisierung und Interaktion. Displays mit Touch-Funktionalität stellen in diesem Zusammenhang eine naheliegende Erweiterung dar, da sie eine direkte und intuitive Benutzerinteraktion ermöglichen.

Die Erweiterung bestehender Embedded-Systeme um externe Komponenten ist jedoch nicht trivial. Neben der reinen Hardwareanbindung spielen insbesondere Aspekte der Kommunikation und der Softwareintegration eine entscheidende Rolle. Unterschiedliche Systemkomponenten müssen koordiniert zusammenarbeiten, wobei vorhandene Schnittstellen und Laufzeitumgebungen bestimmte Einschränkungen mit sich bringen können.

Vor diesem Hintergrund beschäftigt sich die vorliegende Arbeit mit der Frage, wie sich externe Peripherie an ein solches System anbinden lässt, wenn die verfügbare Verbindung dafür nur eingeschränkt geeignet ist. Der Schwerpunkt liegt dabei nicht auf der Ansteuerung eines einzelnen Geräts, sondern auf einer Softwareschicht, die zwischen Anwendung und Verbindung vermittelt und die Eigenheiten der Übertragung vor der Anwendung verbirgt. Die Anbindung eines TFT-Touchscreen-Displays dient als Anwendungsfall, an dem dieser Entwurf entwickelt, umgesetzt und bewertet wird.

== Problemstellung <sec:problemstellung>

Die Anbindung zusätzlicher Peripherie an eine solche Plattform wird durch drei technische Einschränkungen erschwert, die gemeinsam auftreten und sich gegenseitig verstärken.

Erstens ist die Verbindung zwischen den Systemkomponenten anfragegetrieben. Sie ist zwar in beide Richtungen nutzbar, doch nur die übergeordnete Seite kann eine Übertragung anstoßen, allerdings kann die untergeordnete Seite antwortet ausschließlich. Zweitens ist die je Paket übertragbare Datenmenge sehr klein und fest vorgegeben, sodass Nachrichten üblicher Größe grundsätzlich nicht in ein einzelnes Paket passen. Drittens stehen auf beiden Seiten stark beschränkte Laufzeitumgebungen zur Verfügung, die weder einen vollständigen Netzwerkstack noch die üblichen Mittel nebenläufiger Programmierung bereitstellen.

Diese Rahmenbedingungen stehen im Gegensatz zu den Anforderungen interaktiver Benutzeroberflächen, die eine flexible Übertragung strukturierter Daten sowie die zeitnahe Rückmeldung von Benutzereingaben voraussetzen. Insbesondere die Verarbeitung von Eingaben und die Übertragung zusammengesetzter Zustände stellen unter diesen Bedingungen eine Herausforderung dar.

Daraus ergibt sich die zentrale Problemstellung dieser Arbeit:
Wie lässt sich eine Middleware entwerfen, die entfernte Objekte über eine anfragegetriebene Verbindung mit sehr kleiner Paketgröße auf beschränkten Laufzeitumgebungen transparent nutzbar macht?

Diese Frage ist nicht an eine bestimmte Plattform gebunden. Die genannte Kombination aus anfragegetriebener Übertragung, kleiner Paketgröße und beschränkter Laufzeitumgebung tritt in verschiedenen Ausprägungen auf, wie in @sec:verallgemeinerung ausgeführt wird.

== Zielsetzung der Arbeit

Ziel dieser Arbeit ist der Entwurf einer Middleware, die entfernte Objekte über eine Verbindung der beschriebenen Art transparent nutzbar macht.

Der Entwurf soll die drei genannten Einschränkungen auf wenige Schichten eingrenzen, sodass sie oberhalb davon nicht mehr sichtbar sind. Dazu gehören:

- die Zerlegung von Nachrichten in Pakete und deren Rahmung, 
- ein anfragegetriebener Rückkanal für Ergebnisse und Ereignisse 
- sowie eine Abstraktion, die entfernte Objekte wie lokale erscheinen lässt. 

Ein weiterer Schwerpunkt liegt darauf, den Entwurf vom konkreten Übertragungsweg zu lösen, sodass er auf andere Verbindungen derselben Klasse übertragbar bleibt.

Die Bewertung stützt sich auf drei Kriterien: den funktionalen Nachweis, dass sich eine interaktive Oberfläche über die entwickelte Abstraktion umsetzen lässt, den Übertragungsaufwand je Aufruf, gemessen in benötigten Paketen und in der resultierenden Verzögerung, sowie den Ressourcenverbrauch auf beiden Seiten der Verbindung.

== Aufbau der Arbeit

Die vorliegende Arbeit ist wie folgt aufgebaut:

/*
Kapitel 2 vermittelt die notwendigen Grundlagen zu eingebetteten Systemen, Kommunikation und Serialisierung, zum entfernten Prozeduraufruf sowie zu Middleware als Architekturkonzept. Kapitel 3 ordnet die Arbeit in bestehende Ansätze für entfernte Aufrufe und für die Kommunikation in eingebetteten Systemen ein und benennt die Lücke, die sie schließt.

In Kapitel 4 wird das Zielsystem analysiert, die Anforderungen werden abgeleitet und die drei Einschränkungen der Plattform ausgearbeitet. Das Kapitel schließt mit der Verallgemeinerung des so umrissenen Problemraums.

Kapitel 5 entwickelt die Architektur und beschreibt den geschichteten Aufbau, die Aufgaben der einzelnen Schichten sowie das Kommunikationsmodell. Kapitel 6 vertieft den Entwurf der Kommunikations- und Transportschichten einschließlich des Nachrichtenprotokolls, Kapitel 7 den Entwurf des Objektmodells. Beide Kapitel bleiben auf der konzeptionellen Ebene.

Kapitel 8 beschreibt den Hardwareaufbau, über den die Anzeigeeinheit an den Hub angebunden wird, in zwei aufeinander aufbauenden Ausbaustufen. Kapitel 9 stellt die Referenzimplementierung vor und bildet den Entwurf auf diese Hardware, eine konkrete Laufzeitumgebung und einen konkreten Bus ab. Kapitel 10 bewertet die Lösung hinsichtlich Funktionalität, Übertragungsaufwand, Ressourcenverbrauch und Hardwareaufbau.

Kapitel 11 diskutiert die Grenzen des Ansatzes und seine Übertragbarkeit auf andere Verbindungsklassen. Kapitel 12 fasst die Ergebnisse zusammen.
*/