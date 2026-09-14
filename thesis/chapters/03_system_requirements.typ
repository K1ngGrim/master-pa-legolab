= Systemanalyse und Anforderungen

== Zielsystem und Hardwareumgebung <sec:zielsystem>

Ausgangspunkt der vorliegenden Arbeit ist eine bestehende Hardwareplattform aus dem LEGO-Education-Ökosystem. Die Plattform definiert die technischen Rahmenbedingungen, innerhalb derer die in @sec:einleitung motivierte Display-Integration realisiert werden muss. Im Folgenden wird zunächst die zentrale Hardwarekomponente vorgestellt, anschließend werden ihre Eigenschaften im Hinblick auf die Anbindung eines Touchscreen-Displays analysiert. Aus dieser Analyse heraus ergibt sich die Notwendigkeit einer externen Erweiterung, deren mögliche Ausprägungen im letzten Abschnitt skizziert werden.

=== Der LEGO Education SPIKE Prime Hub als Ausgangsplattform

Den Kern des Zielsystems bildet der LEGO Education SPIKE Prime Hub @HandlungsorientiertesLernen. Hierbei handelt es sich um einen programmierbaren Steuerbaustein, der primär für den Einsatz im Bildungsbereich konzipiert ist und über sechs Ein- und Ausgabeports zum Anschluss von LEGO-kompatiblen Sensoren und Aktoren verfügt. Zur Interaktion mit dem Nutzer stellt der Hub eine Matrix aus 5 × 5 @led:pl, drei Tasten sowie einen einfachen Lautsprecher bereit.

Intern basiert der Hub auf einem STM32F413-Mikrocontroller @STM32F413423STMicroelectronics mit einem ARM-Cortex-M4-Kern, einer Taktfrequenz von etwa 100 MHz, rund 1 bis 1,5 MB Flash-Speicher sowie 320 KB @sram @LegoLabKarlsruhe. Die Programmierung kann grafisch über die offizielle LEGO-Software oder textbasiert mittels MicroPython erfolgen. Welche Firmware konkret zum Einsatz kommt und welche Auswirkungen diese Wahl auf die spätere Lösung hat, wird in @sec:einschraenkungen vertieft.

Für die vorliegende Arbeit sind drei Eigenschaften des Hubs von besonderer Bedeutung:

- Der Hub stellt ausschließlich passive, an die Sensor- und Motorports gebundene Erweiterungsmöglichkeiten bereit. Eine direkte Anbindung beliebiger Peripheriegeräte über offene Schnittstellen wie @spi @MctdeSPISerial2019 oder @i2c @I2CBus ist nicht vorgesehen.
- Die verfügbaren Anzeige- und Eingabemöglichkeiten beschränken sich auf die genannte @led\-Matrix sowie die Hub-Tasten.
- Die Rechenleistung und der Arbeitsspeicher sind für einen Mikrocontroller zwar typisch, im Hinblick auf grafische Benutzeroberflächen jedoch stark limitiert.

Diese Eigenschaften legen den Rahmen fest, innerhalb dessen die Display-Integration konzipiert werden muss.

=== Notwendigkeit einer externen Erweiterung

Aus den in @sec:problemstellung motivierten Anforderungen an eine grafische Benutzeroberfläche mit Touch-Funktionalität ergibt sich unmittelbar ein Konflikt mit der beschriebenen Plattform. Die im Hub integrierten Ausgabe- und Eingabemöglichkeiten beschränken sich auf eine niedrig auflösende @led\-Matrix und einfache Tasten und sind damit für die Darstellung komplexer Inhalte sowie für eine differenzierte Benutzerinteraktion ungeeignet. Auch eine Erweiterung des Hubs selbst ist nicht vorgesehen, da der Hub als geschlossene Komponente konzipiert ist und keine Schnittstellen zum direkten Anschluss grafischer Peripheriegeräte bereitstellt.

Daraus folgt, dass die geforderte Display-Funktionalität nicht innerhalb des Hubs, sondern ausschließlich außerhalb davon realisiert werden kann. Die Aufgabe der Display-Ansteuerung muss demnach an eine externe Hardwarekomponente delegiert werden, die ihrerseits an einen der vorhandenen Sensorports des Hubs angebunden wird. Hieraus ergeben sich zwei eigenständige Teilprobleme, die in den folgenden Abschnitten weiter ausgearbeitet werden:

- die Wahl einer geeigneten externen Hardware zur Ansteuerung eines Displays sowie
- die Etablierung einer geeigneten Kommunikationsbeziehung zwischen Hub und dieser externen Komponente.

== Anforderungen an die Display-Integration

=== Anforderungen an ein externes Display

Bevor konkrete Hardwarekomponenten betrachtet werden, lassen sich aus der Zielsetzung der Arbeit allgemeine Anforderungen an ein externes Display ableiten:

- *D1 -- Grafische Darstellung.* Das Display soll die Darstellung einfacher grafischer Elemente wie Schaltflächen, Beschriftungen und Anzeigen ermöglichen.
- *D2 -- Berührungseingabe.* Es soll zugleich Benutzereingaben über einen Touchscreen entgegennehmen.
- *D3 -- Embedded-typische Auslegung.* Hinsichtlich Auflösung, Größe und Energieaufnahme orientieren sich die Anforderungen an typischen Embedded-Anwendungen und liegen damit im Bereich kleiner @tft\-Displays mit Auflösungen im Bereich von etwa 240 × 320 Pixeln.

Solche Displays sind in unterschiedlichen Ausführungen verfügbar. Eine im Embedded-Bereich weit verbreitete Variante stellen Module mit ILI9341-Display-Controller dar, die eine Auflösung von 240 × 320 Pixeln bei einer Farbtiefe von 18 Bit unterstützen und über die @spi\-Schnittstelle angesteuert werden können. Für die Erkennung von Berührungen kommen typischerweise kapazitive Touch-Controller wie der FT6X36 zum Einsatz, die über @i2c angebunden werden und neben Einzelberührungen auch Mehrfingergesten erfassen können. Solche Module sind kostengünstig verfügbar und werden in der Maker- und Embedded-Community häufig in Verbindung mit Mikrocontrollern der ESP32-Familie eingesetzt.

=== Anforderungen an eine externe Steuerungseinheit

Da der SPIKE Prime Hub selbst keine direkte Anbindung eines @tft\-Displays über @spi ermöglicht, muss zwischen Hub und Display eine zusätzliche Steuerungseinheit vermitteln. Diese übernimmt die unmittelbare Ansteuerung des Displays sowie die Verarbeitung der Touch-Eingaben und stellt gleichzeitig die Kommunikation mit dem Hub sicher. Aus dieser Doppelrolle ergeben sich mehrere Anforderungen an die einzusetzende Hardware:

- *S1 -- Displayschnittstellen.* Sie muss über geeignete Schnittstellen zur Ansteuerung typischer @tft\-Displays verfügen, insbesondere @spi für die Bildschirmdaten und @i2c für den Touch-Controller.
- *S2 -- Rechenleistung und Speicher.* Sie muss ausreichend Rechenleistung und Speicher bieten, um eine grafische Bibliothek wie etwa @LVGL @LVGLLightVersatile ausführen zu können.
- *S3 -- Busanbindung.* Sie muss über eine Schnittstelle verfügen, die kompatibel zu den Sensorports des SPIKE Prime Hubs ist, oder eine entsprechende Anbindung über @lpf2 unterstützen.

Diese Anforderungen werden von im Bildungs- und Maker-Bereich verfügbaren Erweiterungsboards erfüllt, die speziell für die Anbindung an LEGO-Hubs entworfen wurden. Ein Beispiel hierfür sind ESP32-basierte Boards der LMS-ESP32-Reihe @LMSESP32V20Clever2023, die sich gegenüber dem Hub als LEGO-Sensor ausgeben und damit eine Kommunikation über das @lpf2\-Protokoll ermöglichen. Welche konkrete Hardware im Rahmen dieser Arbeit eingesetzt wird, sowie die zugehörige Softwarekonfiguration werden im Kapitel zur Referenzimplementierung dargestellt.

=== Resultierende Systemstruktur

Aus den genannten Überlegungen ergibt sich eine grundsätzliche Systemstruktur, die sich aus drei Teilen zusammensetzt: dem SPIKE Prime Hub als zentrale Steuereinheit, einer externen Steuerungseinheit zur unmittelbaren Ansteuerung des Displays sowie einem @tft\-Touchscreen-Display als Anzeige- und Eingabeelement. Die Kopplung zwischen Hub und externer Steuerungseinheit erfolgt dabei über die vom Hub bereitgestellten Sensorports und das zugehörige @lpf2\-Protokoll. Die konkrete Ausgestaltung dieser Kommunikation und der damit verbundenen Einschränkungen wird in den folgenden Abschnitten dieses Kapitels detailliert betrachtet.

== Kommunikationsanforderungen <sec:kommunikationsanforderungen>

Der vorige Abschnitt legt fest, aus welchen Komponenten das System besteht. Offen ist noch, was die Verbindung zwischen Steuer- und Anzeigeeinheit leisten muss. Die folgenden Anforderungen leiten sich aus dem Anwendungsfall einer interaktiven Oberfläche ab und nehmen keinen Bezug auf einen bestimmten Übertragungsweg. Sie sind mit K1 bis K6 nummeriert, damit @sec:evaluation später auf sie verweisen kann.

- *K1 -- Strukturierte Nachrichten unbestimmter Länge.* Ein Bedienelement lässt sich nicht durch einen einzelnen Wert beschreiben. Zum Erzeugen einer Schaltfläche gehören Position, Abmessungen und Beschriftung, ein Beschriftungstext hat keine feste Länge, und eine Auswahlliste enthält unterschiedlich viele Einträge. Die Verbindung muss deshalb zusammengesetzte Werte übertragen können, deren Länge erst zur Laufzeit feststeht. Feste Formatangaben je Aufruf, wie sie die in @sec:relatedwork betrachtete Transportbibliothek verwendet, reichen dafür nicht aus.

- *K2 -- Aufrufe mit zuordenbarem Ergebnis.* Viele Aufrufe liefern einen Rückgabewert. Das Erzeugen eines Objekts liefert eine Referenz, über die es später angesprochen wird, das Auslesen eines Zustands den entsprechenden Wert. Zu jeder Anfrage muss also eine Antwort zurückkommen. Werden mehrere Anfragen nacheinander abgesetzt, muss erkennbar bleiben, welche Antwort zu welcher Anfrage gehört.

- *K3 -- Rückfluss von Ereignissen.* Berührungen entstehen auf der Anzeigeeinheit, ausgewertet werden sie von der Anwendung auf der Steuereinheit. Informationen müssen daher auch dann von der Anzeige- zur Steuereinheit gelangen, wenn sie keine Antwort auf einen Aufruf sind. Ereignisse sollen dabei nicht verloren gehen. Lässt sich ein Verlust nicht vermeiden, muss er zumindest erkennbar sein.

- *K4 -- Antwortzeit.* Berührung und Reaktion auf dem Bildschirm sollen für den Benutzer zusammengehören. Als Richtwert dient die bei direkter Manipulation übliche Grenze von etwa 100 Millisekunden. // QUELLE: Beleg für die 100-ms-Grenze ergänzen (z. B. Nielsen 1993, Response Times, oder Card/Moran/Newell 1983).
  Gemeint ist dabei der gesamte Vorgang aus Erkennung, Übertragung, Verarbeitung und Rückmeldung und nicht die Übertragung eines einzelnen Pakets.

- *K5 -- Begrenzter Speicherbedarf.* Auf beiden Seiten der Verbindung arbeitet ein Mikrocontroller. Puffer brauchen deshalb eine feste Obergrenze, die schon beim Entwurf bekannt ist. Verfahren, die im ungünstigen Fall beliebig viel Speicher belegen, etwa das Sammeln aller bisher aufgetretenen Ereignisse, kommen nicht in Frage.

- *K6 -- Unabhängigkeit vom Übertragungsweg.* Der Übertragungsweg ist durch die Plattform vorgegeben und gehört nicht zum eigentlichen Problem. Seine Eigenschaften sollen sich deshalb nur in einem klar abgegrenzten Teil des Entwurfs auswirken. Prüfen lässt sich das an der Frage, wie viel geändert werden müsste, um denselben Dienst über einen anderen Weg anzubieten.

K1 bis K3 betreffen den Inhalt der Übertragung, K4 und K5 die Bedingungen, unter denen sie stattfindet, und K6 den Aufbau des Entwurfs. Der folgende Abschnitt stellt diesen Anforderungen die Eigenschaften der Plattform gegenüber.

== Einschränkungen der Plattform <sec:einschraenkungen>

Steuer- und Anzeigeeinheit sind über einen Sensorport des Hubs und das @lpf2\-Protokoll gekoppelt. Aus dieser Kopplung ergeben sich drei Einschränkungen, die den Anforderungen aus dem vorigen Abschnitt entgegenstehen. Sie werden im Folgenden einzeln beschrieben und den betroffenen Anforderungen zugeordnet. Dabei handelt es sich um Eigenschaften der Kopplung selbst und nicht um Schwächen einer bestimmten Umsetzung. Wie der Entwurf darauf reagiert, zeigen @sec:architektur und @sec:entwurf, die konkrete Umsetzung zeigt @sec:referenzimplementierung.

=== Eingeschränkte Kommunikationsrichtung

Das @lpf2\-Protokoll arbeitet nach dem Master-Slave-Prinzip. // QUELLE: Beleg für das LPF2-Protokoll ergänzen.
Der Hub ist dabei der Master: Er wählt den aktiven Modus des angeschlossenen Geräts aus und stößt jede Übertragung an. Das Gerät meldet sich als Sensor an und stellt Werte bereit, die der Hub abruft. Von sich aus senden kann es nicht.

Die in @sec:relatedwork beschriebene Transportbibliothek bildet das direkt ab und bietet ein einziges Zugriffsmuster an: Die Steuereinheit schreibt Daten in einen Modus und liest im selben Vorgang die Antwort zurück. Jede Übertragung besteht damit aus Anfrage und Antwort, und die Anzeigeeinheit antwortet ausschließlich.

Für die Anforderungen bedeutet das, dass sich weder Ergebnisse (K2) noch Ereignisse (K3) zustellen lassen. Beides kann nur bereitgehalten und abgefragt werden. Entsteht ein Ergebnis erst nach der letzten Anfrage, ist eine weitere Anfrage nötig, und eine Berührung zwischen zwei Anfragen muss bis zur nächsten Anfrage zwischengespeichert werden. Wann eine Rückmeldung eintrifft, bestimmt damit nicht die Seite, auf der sie entsteht, sondern die Seite, die sie abholt. Die zeitliche Auflösung für Ereignisse ist dadurch durch den Abfragetakt der Steuereinheit begrenzt, was sich unmittelbar auf K4 auswirkt.

=== Begrenzte Paketgröße

Ein Modus des Busses überträgt eine feste, vorab vereinbarte Anzahl von Bytes. Zusammen mit der auf dem Hub eingesetzten Firmware liegt die nutzbare Obergrenze bei 16 Byte je Übertragung; oberhalb dieses Werts treten Prüfsummenfehler auf. // QUELLE: Beleg für die Pybricks-Firmware und die Paketgrenze ergänzen.
Da jedes Paket zusätzlich Steuerinformationen für die Wiederzusammensetzung tragen muss, bleibt für die Nachricht selbst noch weniger übrig. In der Referenzimplementierung sind es 13 nutzbare Byte je Paket, wie @sec:referenzimplementierung zeigt.

Schon eine einfache Aufrufnachricht mit Objektreferenz, Methodennamen und wenigen Argumenten überschreitet diesen Rahmen deutlich. K1 lässt sich in einem einzelnen Paket also nicht erfüllen. Nachrichten müssen daher in mehrere Pakete zerlegt werden, damit sich überhaupt eine vollständige Nachricht übertragen lässt. Hinzu kommt, dass die Steuerinformationen bei einer Nutzlast von wenigen Byte einen erheblichen Anteil der Übertragung ausmachen.

Eine weitere Beschränkung ergibt sich aus der Stromversorgung. Ein Display benötigt mehr Strom, als die Logikversorgung des Ports liefert, weshalb die Anzeigeeinheit die höhere Versorgungsspannung über den Port anfordert. In diesem Fall verkürzt sich die zulässige Länge der Modusnamen von elf auf fünf Zeichen. Damit ist auch der Namensraum knapp, über den das Protokoll seine Kanäle benennt. @sec:hardwareaufbau geht auf die Versorgung näher ein.

=== Beschränkte Laufzeitumgebung

Der Hub wird in einer für Mikrocontroller ausgelegten Python-Variante programmiert, deren Funktionsumfang gegenüber einer vollständigen Laufzeitumgebung deutlich eingeschränkt ist. // QUELLE: Belege für MicroPython und die eingesetzte Hub-Firmware ergänzen.
Ein Netzwerkstack und die darauf aufbauenden Abstraktionen stehen nicht zur Verfügung. Die üblichen Bausteine verteilter Kommunikation lassen sich deshalb nicht verwenden und müssen durch eigene ersetzt werden.

Schwerer wiegt, dass auf der Steuereinheit keine echte Nebenläufigkeit zur Verfügung steht. Es gibt keinen Hintergrundprozess, der Pakete entgegennimmt oder Ergebnisse einsammelt, während die Anwendung weiterläuft. Das Warten auf ein Ergebnis findet deshalb im Kontrollfluss der Anwendung selbst statt: Ein Aufruf, dessen Ergebnis noch nicht vorliegt, hält die Anwendung an. Mehrere ausstehende Aufrufe lassen sich damit nicht überlappen, ihre Übertragungszeiten addieren sich.

Dazu kommt der begrenzte Arbeitsspeicher auf beiden Seiten. K5 ist auf dieser Plattform damit eine harte Grenze: Puffer für unvollständig empfangene Nachrichten, für bereitgehaltene Ergebnisse und für zwischengespeicherte Ereignisse brauchen alle eine feste Obergrenze, und für den Fall, dass diese erreicht wird, muss ein Verhalten festgelegt sein.

=== Wechselwirkung der Einschränkungen

Einzeln betrachtet wäre jede der drei Einschränkungen zu bewältigen. Kleine Pakete lassen sich durch Zerlegung überbrücken, eine fehlende Sendemöglichkeit durch regelmäßiges Abfragen, und ein Ablauf lässt sich auch ohne Nebenläufigkeit sequenziell formulieren. Zusammen verstärken sie sich jedoch gegenseitig.

Durch die kleine Paketgröße zerfällt eine Nachricht in viele Pakete. Wegen der eingeschränkten Kommunikationsrichtung erfordert jedes dieser Pakete eine eigene Anfrage der Steuereinheit samt Antwort, und für das Abholen des Ergebnisses sind weitere Anfragen nötig. Ohne Nebenläufigkeit lassen sich diese Anfragen nicht überlappen, sondern werden nacheinander abgearbeitet.

Für den weiteren Entwurf folgt daraus, dass die Dauer eines Aufrufs vor allem von der Anzahl der nötigen Übertragungen abhängt und weniger von der Übertragungsgeschwindigkeit des Busses. Ein zusätzliches Byte Steuerinformation je Paket erhöht bei einer Nutzlast von wenigen Byte die Anzahl der Pakete und damit auch die Dauer eines Aufrufs. Der Entwurf sollte deshalb vor allem Übertragungen einsparen. @sec:evaluation greift das wieder auf und beziffert es.

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
      [K6], [Unabhängigkeit vom Übertragungsweg], [Eigenheiten von Bus und Transportbibliothek], [Alle wegabhängigen Anteile in einer austauschbaren Schicht bündeln],
    )
  ],
) <tab:konflikt>

== Verallgemeinerung des Problemraums <sec:verallgemeinerung>

Die im vorigen Abschnitt herausgearbeiteten Einschränkungen wurden am konkreten Zielsystem hergeleitet. Sie sind jedoch nicht an dieses System gebunden, und diese Feststellung ist für die weitere Arbeit von Bedeutung: Sie entscheidet darüber, ob der folgende Entwurf eine Einzellösung darstellt oder eine Klasse von Verbindungen adressiert.

Die drei Eigenschaften lassen sich von der Plattform ablösen und als allgemeine Merkmale einer Verbindung formulieren. Erstens ist die Übertragung anfragegetrieben, das heißt, nur eine der beiden Seiten kann eine Übertragung anstoßen. Zweitens ist die Nutzlast je Übertragung klein und fest vorgegeben. Drittens steht auf mindestens einer Seite eine Laufzeitumgebung zur Verfügung, die weder einen vollständigen Netzwerkstack noch die üblichen Mittel nebenläufiger Programmierung bereitstellt.

Diese Kombination tritt über den betrachteten Bus hinaus in verschiedenen Ausprägungen auf. Bei der Kommunikation über @i2c treibt der Master den Bus, und ein Slave kann eine Übertragung nicht selbstständig beginnen. Modbus @rtu folgt demselben Muster aus Anfrage und Antwort. Auch bei Bluetooth Low Energy ist der verbreitete Zugriff über lesende Anfragen des Clients organisiert, und die standardmäßig ausgehandelte Nutzlast liegt in derselben Größenordnung wie beim hier betrachteten Bus. In allen genannten Fällen stellen sich dieselben Fragen: Wie werden Nachrichten zerlegt und wieder zusammengesetzt, wie gelangen Ergebnisse und Ereignisse zur anfragenden Seite zurück, und wie lässt sich all das vor der Anwendung verbergen.

Die vorliegende Arbeit behandelt den betrachteten Bus daher als einen Vertreter dieser Klasse. Der in den folgenden Kapiteln entwickelte Entwurf wird so formuliert, dass er auf die genannten Merkmale Bezug nimmt und nicht auf Eigenschaften einer bestimmten Plattform. Inwieweit dies gelungen ist, greift die Diskussion am Ende der Arbeit erneut auf.
