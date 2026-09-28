= Systemanalyse und Anforderungen

Dieses Kapitel analysiert das Zielsystem und leitet daraus die Anforderungen ab. Zunächst wird die vorhandene Plattform betrachtet und begründet, warum eine externe Erweiterung nötig ist, bevor die Anforderungen an Display, Mikrocontroller und Kommunikation formuliert und den Einschränkungen der Plattform gegenübergestellt werden. Das Kapitel schließt mit einer Verallgemeinerung des Problemraums.

== Zielsystem und Hardwareumgebung <sec:zielsystem>

Ausgangspunkt der vorliegenden Arbeit ist eine bestehende Hardwareplattform aus dem LEGO-Education-Umfeld, die die technischen Rahmenbedingungen festlegt, in denen die in @sec:einleitung motivierte Display-Integration umgesetzt werden muss. Im Folgenden wird zunächst die zentrale Hardwarekomponente vorgestellt und anschließend im Hinblick auf die Anbindung eines Touchscreen-Displays analysiert, woraus sich die Notwendigkeit einer externen Erweiterung ergibt.

=== Der LEGO Education SPIKE Prime Hub als Ausgangsplattform

Den Kern des Zielsystems bildet der LEGO Education SPIKE Prime Hub @HandlungsorientiertesLernen. Hierbei handelt es sich um einen programmierbaren Steuerbaustein, der primär für den Einsatz im Bildungsbereich konzipiert ist und über sechs Ein- und Ausgabeports zum Anschluss von LEGO-kompatiblen Sensoren und Aktoren verfügt. Für die Interaktion mit dem Nutzer stellt der Hub eine Matrix aus 5 × 5 @led:pl, drei Tasten und einen einfachen Lautsprecher bereit.

Intern basiert der Hub auf einem STM32F413-Mikrocontroller @stmicroelectronicsSTM32F413xGxH2018 mit einem ARM-Cortex-M4-Kern, einer Taktfrequenz von etwa 100 MHz, rund 1 bis 1,5 MB Flash-Speicher sowie 320 kB @sram @LegoLabKarlsruhe. Die Programmierung kann grafisch über die offizielle LEGO-Software oder textbasiert mittels MicroPython erfolgen. Welche Firmware konkret eingesetzt wird und wie sich diese Wahl auf die spätere Lösung auswirkt, wird in @sec:einschraenkungen vertieft.

Für die vorliegende Arbeit sind drei Eigenschaften des Hubs von besonderer Bedeutung:

- Der Hub stellt ausschließlich passive, an die Sensor- und Motorports gebundene Erweiterungsmöglichkeiten bereit. Eine direkte Anbindung beliebiger Peripheriegeräte über offene Schnittstellen wie @spi @MctdeSPISerial2019 oder @i2c @nxpI2CBusSpecification2021 ist nicht vorgesehen.
- Die verfügbaren Anzeige- und Eingabemöglichkeiten beschränken sich auf die genannte @led\-Matrix sowie die Hub-Tasten.
- Rechenleistung und Arbeitsspeicher sind für einen Mikrocontroller zwar typisch, für grafische Benutzeroberflächen jedoch stark begrenzt.

Diese Eigenschaften bilden den Rahmen, in dem die Display-Integration entworfen werden muss.

=== Notwendigkeit einer externen Erweiterung

Aus den in @sec:problemstellung motivierten Anforderungen an eine grafische Benutzeroberfläche mit Touch-Funktionalität ergibt sich ein direkter Konflikt mit der beschriebenen Plattform. Die im Hub integrierten Ausgabe- und Eingabemöglichkeiten beschränken sich auf eine niedrig auflösende @led\-Matrix und einfache Tasten und sind damit für die Darstellung komplexer Inhalte sowie für eine differenzierte Benutzerinteraktion ungeeignet. Eine Erweiterung des Hubs selbst ist ebenfalls nicht vorgesehen, da er als geschlossene Komponente konzipiert ist und keine Schnittstellen zum direkten Anschluss grafischer Peripherie bereitstellt.

Die geforderte Display-Funktionalität lässt sich daher nur außerhalb des Hubs umsetzen. Die Ansteuerung des Displays muss an eine externe Hardwarekomponente abgegeben werden, die an einen der vorhandenen Sensorports des Hubs angeschlossen wird. Hieraus ergeben sich zwei eigenständige Teilprobleme, die in den folgenden Abschnitten weiter ausgearbeitet werden:

- die Wahl einer geeigneten externen Hardware zur Ansteuerung eines Displays sowie
- eine geeignete Kommunikation zwischen dem Hub und dieser externen Komponente.

== Anforderungen an die Display-Integration

Die Anforderungen werden in drei Gruppen gegliedert. Die Anforderungen D1 bis D3 betreffen das Display selbst, S1 bis S3 den Mikrocontroller, der es ansteuert, und K1 bis K6 im folgenden Abschnitt die Kommunikation zwischen beiden Einheiten.

=== Anforderungen an ein externes Display

Bevor konkrete Hardwarekomponenten betrachtet werden, lassen sich aus der Zielsetzung der Arbeit allgemeine Anforderungen an ein externes Display ableiten:

- *D1 -- Grafische Darstellung.* Das Display soll die Darstellung einfacher grafischer Elemente wie Schaltflächen, Beschriftungen und Anzeigen ermöglichen.
- *D2 -- Berührungseingabe.* Es soll zugleich Benutzereingaben über einen Touchscreen entgegennehmen.
- *D3 -- Embedded-typische Auslegung.* Auflösung, Größe und Energieaufnahme orientieren sich an typischen Embedded-Anwendungen. Damit kommen kleine @tft\-Displays mit einer Auflösung von etwa 240 × 320 Pixeln in Frage.

Solche Displays sind in unterschiedlichen Ausführungen verfügbar, wobei im Embedded-Bereich Module mit ILI9341-Display-Controller @ilitekILI9341Datasheet2011 weit verbreitet sind. Sie unterstützen eine Auflösung von 240 × 320 Pixeln bei einer Farbtiefe von 18 Bit und werden über @spi angesteuert. Für die Erkennung von Berührungen kommen typischerweise kapazitive Touchcontroller wie der FT6x06 @focaltechFT6x06Datasheet2014 zum Einsatz, die über @i2c angebunden werden und neben Einzelberührungen auch Mehrfingergesten erfassen können. Solche Module sind kostengünstig verfügbar und werden in der Maker- und Embedded-Community häufig in Verbindung mit Mikrocontrollern der ESP32-Familie eingesetzt.

=== Anforderungen an einen externen Mikrocontroller

Da der SPIKE Prime Hub selbst kein @tft\-Display über @spi anbinden kann, muss zwischen Hub und Display ein zusätzlicher Mikrocontroller vermitteln. Er übernimmt die Ansteuerung des Displays und die Verarbeitung der Touch-Eingaben und kommuniziert gleichzeitig mit dem Hub. Aus dieser Doppelrolle ergeben sich folgende Anforderungen an die Hardware:

- *S1 -- Displayschnittstellen.* Sie muss über geeignete Schnittstellen zur Ansteuerung typischer @tft\-Displays verfügen, insbesondere @spi für die Bildschirmdaten und @i2c für den Touch-Controller.
- *S2 -- Rechenleistung und Speicher.* Sie muss ausreichend Rechenleistung und Speicher bieten, um eine grafische Bibliothek wie etwa @LVGL @LVGLLightVersatile ausführen zu können.
- *S3 -- Busanbindung.* Sie muss über eine Schnittstelle verfügen, die kompatibel zu den Sensorports des SPIKE Prime Hubs ist, oder eine entsprechende Anbindung über @lpf2 unterstützen.

Diese Anforderungen erfüllen Erweiterungsboards aus dem Bildungs- und Maker-Bereich, die speziell für die Anbindung an LEGO-Hubs entworfen wurden. Ein Beispiel sind die ESP32-basierten Boards der LMS-ESP32-Reihe @LMSESP32V20Clever2023. Sie geben sich gegenüber dem Hub als LEGO-Sensor aus und können dadurch über das @lpf2\-Protokoll kommunizieren. Welche Hardware in dieser Arbeit konkret eingesetzt wird und wie die Software dafür eingerichtet ist, beschreibt @sec:referenzimplementierung.

=== Resultierende Systemstruktur

Aus diesen Überlegungen ergibt sich eine Systemstruktur aus drei Teilen. Der SPIKE Prime Hub führt die Anwendung aus, ein externer Mikrocontroller steuert das Display an, und ein @tft\-Touchscreen-Display dient zur Anzeige und Eingabe, wobei Hub und Mikrocontroller über einen Sensorport des Hubs und das @lpf2\-Protokoll verbunden sind. Im Folgenden wird der Hub als Steuereinheit bezeichnet, während Mikrocontroller und Display zusammen die Anzeigeeinheit bilden. Wie die Kommunikation zwischen beiden aussehen muss und welchen Einschränkungen sie unterliegt, betrachten die folgenden Abschnitte.

== Kommunikationsanforderungen <sec:kommunikationsanforderungen>

Der vorige Abschnitt legt fest, aus welchen Komponenten das System besteht. Offen ist noch, was die Verbindung zwischen Steuer- und Anzeigeeinheit leisten muss. Die folgenden Anforderungen leiten sich aus dem Anwendungsfall einer interaktiven Oberfläche ab und beziehen sich nicht auf einen bestimmten Übertragungsweg. Sie sind mit K1 bis K6 nummeriert, damit @sec:evaluation später auf sie verweisen kann.

- *K1 -- Strukturierte Nachrichten unbestimmter Länge.* Ein Bedienelement lässt sich nicht durch einen einzelnen Wert beschreiben. Zum Erzeugen einer Schaltfläche gehören Position, Abmessungen und Beschriftung. Ein Beschriftungstext hat keine feste Länge, und eine Auswahlliste enthält unterschiedlich viele Einträge. Die Verbindung muss deshalb zusammengesetzte Werte übertragen können, deren Länge erst zur Laufzeit feststeht. Feste Formatangaben je Aufruf, wie sie die in @sec:relatedwork betrachtete Transportbibliothek verwendet, reichen dafür nicht aus.

- *K2 -- Aufrufe mit zuordenbarem Ergebnis.* Viele Aufrufe liefern einen Rückgabewert. Das Erzeugen eines Objekts liefert eine Referenz, über die es später angesprochen wird. Das Auslesen eines Zustands liefert den entsprechenden Wert. Zu jeder Anfrage muss also eine Antwort zurückkommen. Werden mehrere Anfragen nacheinander abgesetzt, muss erkennbar bleiben, welche Antwort zu welcher Anfrage gehört.

- *K3 -- Rückfluss von Ereignissen.* Berührungen entstehen auf der Anzeigeeinheit, ausgewertet werden sie aber von der Anwendung auf der Steuereinheit. Informationen müssen daher auch dann von der Anzeige- zur Steuereinheit gelangen, wenn sie keine Antwort auf einen Aufruf sind. Ereignisse sollen dabei nicht verloren gehen. Lässt sich ein Verlust nicht vermeiden, muss er zumindest erkennbar sein.

- *K4 -- Antwortzeit.* Berührung und Reaktion auf dem Bildschirm sollen für den Benutzer zusammengehören. Als Richtwert dient die bei direkter Manipulation übliche Grenze von etwa 100 Millisekunden @millerResponseTimeMancomputer1968 @cardPsychologyHumancomputerInteraction1983.
  Gemeint ist dabei der gesamte Vorgang aus Erkennung, Übertragung, Verarbeitung und Rückmeldung, nicht die Übertragung eines einzelnen Pakets.

- *K5 -- Begrenzter Speicherbedarf.* Auf beiden Seiten der Verbindung arbeitet ein Mikrocontroller. Puffer brauchen deshalb eine feste Obergrenze, die schon beim Entwurf bekannt ist. Verfahren, die im ungünstigen Fall beliebig viel Speicher belegen, etwa das Sammeln aller bisher aufgetretenen Ereignisse, kommen nicht in Frage.

- *K6 -- Unabhängigkeit vom Übertragungsweg.* Der Übertragungsweg ist durch die Plattform vorgegeben und gehört nicht zum eigentlichen Problem. Seine Eigenschaften sollen sich deshalb nur in einem klar abgegrenzten Teil des Entwurfs auswirken. Prüfen lässt sich das daran, wie viel geändert werden müsste, um denselben Dienst über einen anderen Weg anzubieten.

K1 bis K3 betreffen den Inhalt der Übertragung, K4 und K5 die Bedingungen, unter denen sie stattfindet, und K6 den Aufbau des Entwurfs. Der folgende Abschnitt stellt diesen Anforderungen die Eigenschaften der Plattform gegenüber.

== Einschränkungen der Plattform <sec:einschraenkungen>

Steuer- und Anzeigeeinheit sind über einen Sensorport des Hubs und das @lpf2\-Protokoll gekoppelt, woraus sich drei Einschränkungen ergeben, die den Anforderungen aus dem vorigen Abschnitt entgegenstehen. Sie werden im Folgenden einzeln beschrieben und den betroffenen Anforderungen zugeordnet, wobei es sich um Eigenschaften der Kopplung selbst handelt und nicht um Schwächen einer bestimmten Umsetzung. Wie der Entwurf darauf reagiert, zeigen @sec:architektur und @sec:entwurf, die konkrete Umsetzung beschreibt @sec:referenzimplementierung.

=== Eingeschränkte Kommunikationsrichtung

Das @lpf2\-Protokoll arbeitet nach dem Master-Slave-Prinzip @LeJOSEV3Wiki.
Der Hub ist dabei der Master. Er wählt den aktiven Modus des angeschlossenen Geräts aus und stößt jede Übertragung an. Das Gerät meldet sich als Sensor an und stellt Werte bereit, die der Hub abruft, während es von sich aus nicht senden kann.

Die in @sec:relatedwork beschriebene Bibliothek PUPRemote bildet das direkt ab und bietet ein einziges Zugriffsmuster an. Die Steuereinheit schreibt Daten in einen Modus und liest im selben Vorgang die Antwort zurück. Jede Übertragung besteht damit aus Anfrage und Antwort, und die Anzeigeeinheit antwortet ausschließlich.

Für die Anforderungen bedeutet das, dass sich weder Ergebnisse (K2) noch Ereignisse (K3) zustellen lassen, sondern beides nur bereitgehalten und abgefragt werden kann. Entsteht ein Ergebnis erst nach der letzten Anfrage, ist eine weitere Anfrage nötig, und eine Berührung zwischen zwei Anfragen muss bis zur nächsten Anfrage zwischengespeichert werden. Wann eine Rückmeldung eintrifft, bestimmt damit die Seite, die sie abholt. Die zeitliche Auflösung von Ereignissen ist dadurch durch den Abfragetakt der Steuereinheit begrenzt, was sich direkt auf K4 auswirkt.

=== Begrenzte Paketgröße

Ein Modus des Busses überträgt eine feste, vorab vereinbarte Anzahl von Bytes. Zusammen mit der auf dem Hub eingesetzten Firmware @valkPybricks liegt die nutzbare Obergrenze bei 16 Byte je Übertragung, oberhalb dieses Werts treten Prüfsummenfehler auf. Dieser Wert ist nicht dokumentiert, sondern wurde im Rahmen dieser Arbeit durch Ausprobieren bestimmt.
Da jedes Paket zusätzlich Steuerinformationen für das Zusammensetzen tragen muss, bleibt für die Nachricht selbst noch weniger übrig. In der Referenzimplementierung sind es 13 nutzbare Byte je Paket, wie @sec:referenzimplementierung zeigt.

Schon eine einfache Aufrufnachricht mit Objektreferenz, Methodenname und wenigen Argumenten überschreitet diesen Rahmen deutlich. K1 lässt sich mit einem einzelnen Paket also nicht erfüllen, und Nachrichten müssen in mehrere Pakete zerlegt werden. Hinzu kommt, dass die Steuerinformationen bei einer Nutzlast von wenigen Byte einen großen Anteil der Übertragung ausmachen.

Eine weitere Beschränkung ergibt sich aus der Stromversorgung, da ein Display mehr Strom benötigt, als die Logikversorgung des Ports liefert, weshalb die Anzeigeeinheit die höhere Versorgungsspannung über den Port anfordert. In diesem Fall verkürzt sich die zulässige Länge der Modusnamen von elf auf fünf Zeichen, wodurch auch die Namen der Kanäle knapp werden. @sec:hardwareaufbau geht auf die Versorgung näher ein.

=== Beschränkte Laufzeitumgebung

Der Hub wird in einer für Mikrocontroller ausgelegten Python-Variante programmiert, wie sie @sec:grundlagen-embedded beschreibt und deren Funktionsumfang gegenüber einer vollständigen Laufzeitumgebung deutlich eingeschränkt ist. Konkret handelt es sich um MicroPython @MicroPythonPythonMicrocontrollers in der Ausprägung von Pybricks @valkPybricks, einer Firmware für LEGO-Hubs. @sec:laufzeitumgebung geht auf die Unterschiede zwischen beiden Seiten ein.

Ein Netzwerkstack und die darauf aufbauenden Abstraktionen stehen nicht zur Verfügung. Die üblichen Bausteine verteilter Kommunikation lassen sich deshalb nicht verwenden und müssen durch eigene ersetzt werden.

Schwerer wiegt, dass auf der Steuereinheit keine echte Nebenläufigkeit zur Verfügung steht, da es keinen Hintergrundprozess gibt, der Pakete entgegennimmt oder Ergebnisse einsammelt, während die Anwendung weiterläuft. Das Warten auf ein Ergebnis findet deshalb im Kontrollfluss der Anwendung selbst statt, sodass die Anwendung stillsteht, solange das Ergebnis eines Aufrufs nicht vorliegt. Mehrere Aufrufe können sich somit nicht überlappen, und ihre Übertragungszeiten addieren sich.

Dazu kommt der begrenzte Arbeitsspeicher auf beiden Seiten, wodurch K5 auf dieser Plattform zu einer harten Grenze wird. Puffer für unvollständig empfangene Nachrichten, für bereitgehaltene Ergebnisse und für zwischengespeicherte Ereignisse benötigen jeweils eine feste Obergrenze, zudem muss festgelegt sein, was beim Erreichen dieser Grenze geschieht.

=== Wechselwirkung der Einschränkungen

Einzeln betrachtet ließe sich jede der drei Einschränkungen bewältigen. Kleine Pakete lassen sich durch Zerlegung überbrücken, eine fehlende Sendemöglichkeit durch regelmäßiges Abfragen, und ein Ablauf lässt sich auch ohne Nebenläufigkeit sequenziell formulieren. Zusammen verstärken sie sich jedoch gegenseitig.

Durch die kleine Paketgröße zerfällt eine Nachricht in viele Pakete. Wegen der eingeschränkten Kommunikationsrichtung erfordert jedes dieser Pakete eine eigene Anfrage der Steuereinheit samt Antwort, und für das Abholen des Ergebnisses sind weitere Anfragen nötig. Ohne Nebenläufigkeit werden all diese Anfragen nacheinander abgearbeitet.

Für den weiteren Entwurf folgt daraus, dass die Dauer eines Aufrufs vor allem von der Anzahl der nötigen Übertragungen abhängt und weniger von der Geschwindigkeit des Busses. Ein zusätzliches Byte Steuerinformation je Paket kann bei einer Nutzlast von wenigen Byte die Anzahl der Pakete und damit die Dauer eines Aufrufs erhöhen. Ziel des Entwurfs ist deshalb vor allem, Übertragungen einzusparen. @sec:evaluation greift das auf und beziffert es.

@tab:konflikt fasst die Gegenüberstellung von Anforderungen und Einschränkungen zusammen.

#figure(
  caption: [Gegenüberstellung der Kommunikationsanforderungen und der Einschränkungen der Plattform],
  text(size: 8pt)[
    #table(
      columns: (0.5fr, 1.5fr, 1.3fr, 1.7fr),
      align: left + top,
      table.header(
        [*Nr.*], [*Anforderung*], [*Entgegenstehende Einschränkung*], [*Folge für den Entwurf*],
      ),
      [K1], [Strukturierte Nachrichten unbestimmter Länge], [Feste Paketgröße von 16 Byte], [Nachrichten müssen zerlegt und wieder zusammengesetzt werden],
      [K2], [Aufrufe mit zuordenbarem Ergebnis], [Keine eigenständige Übertragung durch die Anzeigeeinheit], [Ergebnisse werden bereitgehalten und abgefragt, Zuordnung über eine mitgeführte Kennung],
      [K3], [Rückfluss von Ereignissen], [Keine eigenständige Übertragung durch die Anzeigeeinheit], [Ereignisse werden zwischengespeichert und von der Steuereinheit abgeholt],
      [K4], [Antwortzeit], [Alle drei Einschränkungen gemeinsam], [Anzahl der Übertragungen je Aufruf wird zur bestimmenden Größe],
      [K5], [Begrenzter Speicherbedarf], [Beschränkter Arbeitsspeicher beider Seiten], [Feste Obergrenzen für alle Puffer, festgelegtes Verhalten beim Überlauf],
      [K6], [Unabhängigkeit vom Übertragungsweg], [Eigenheiten von Bus und PUPRemote], [Alle wegabhängigen Anteile in einer austauschbaren Schicht bündeln],
    )
  ],
) <tab:konflikt>

== Verallgemeinerung des Problemraums <sec:verallgemeinerung>

Die im vorigen Abschnitt beschriebenen Einschränkungen wurden am konkreten Zielsystem hergeleitet, sind jedoch nicht an dieses System gebunden. Das ist für die weitere Arbeit wichtig, denn davon hängt ab, ob der folgende Entwurf eine Einzellösung ist oder für eine ganze Klasse von Verbindungen gilt.

Die drei Eigenschaften lassen sich von der Plattform ablösen und als allgemeine Merkmale einer Verbindung formulieren. Erstens ist die Übertragung anfragegetrieben, das heißt, nur eine der beiden Seiten kann eine Übertragung anstoßen. Zweitens ist die Nutzlast je Übertragung klein und fest vorgegeben. Drittens steht auf mindestens einer Seite eine Laufzeitumgebung zur Verfügung, die weder einen vollständigen Netzwerkstack noch die üblichen Mittel nebenläufiger Programmierung bereitstellt.

Diese Kombination tritt über den betrachteten Bus hinaus in verschiedenen Ausprägungen auf. Bei der Kommunikation über @i2c treibt beispielsweise der Master den Bus, während ein Slave eine Übertragung nicht selbstständig beginnen kann, und Modbus @rtu folgt demselben Muster aus Anfrage und Antwort. Auch bei Bluetooth Low Energy erfolgt der übliche Zugriff über lesende Anfragen des Clients, und die standardmäßig ausgehandelte Nutzlast liegt in derselben Größenordnung wie beim hier betrachteten Bus @CoreSpecification2023. In allen genannten Fällen stellen sich dieselben Fragen. Wie werden Nachrichten zerlegt und wieder zusammengesetzt? Wie gelangen Ergebnisse und Ereignisse zur anfragenden Seite zurück? Und wie lässt sich all das vor der Anwendung verbergen?

Die vorliegende Arbeit behandelt den betrachteten Bus daher als einen Vertreter dieser Klasse. Der Entwurf in den folgenden Kapiteln bezieht sich deshalb auf die genannten Merkmale und nicht auf Eigenschaften einer bestimmten Plattform. Inwieweit das gelungen ist, wird am Ende der Arbeit diskutiert.
