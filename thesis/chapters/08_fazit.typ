= Fazit und Ausblick <sec:fazit>

Dieses Kapitel ordnet die Ergebnisse ein, indem zunächst die Grenzen des Entwurfs benannt werden, die sich aus den Messungen in @sec:evaluation ergeben. Anschließend wird geprüft, wie weit sich die Lösung von der betrachteten Plattform gelöst hat, woran sich die möglichen Erweiterungen anschließen. Den Abschluss bildet die Zusammenfassung der Ergebnisse.

== Limitierungen

Die folgenden drei Abschnitte behandeln die Grenzen des Kommunikationsmodells, die erreichbare Latenz und die Stellen, an denen die Abstraktion nicht vollständig trägt.

=== Kommunikationsmodell

Die Anwendung auf dem Client blockiert, solange ein Aufruf läuft, was unmittelbar aus der fehlenden Nebenläufigkeit in @sec:einschraenkungen folgt. Nach @sec:reaktionszeit dauert ein einzelner Aufruf rund 570 ms, im ungünstigsten Fall wartet die Anwendung sogar bis zur Obergrenze von fünf Sekunden. In dieser Zeit steht alles still, was sonst im selben Programm läuft, insbesondere die Regelung von Motoren und das Auslesen von Sensoren. Für ein Programm, das eine Anzeige bedient und gleichzeitig einen Roboter steuert, stellt dies die größte Einschränkung des Entwurfs dar.

Pybricks bietet inzwischen kooperatives Multitasking über `async` und `await` @ToolsGeneralPurpose, womit sich das Warten auf ein Ergebnis unterbrechen ließe, ohne die übrige Anwendung anzuhalten. Der anfragegetriebene Rückkanal bliebe dabei unverändert, da weiterhin der Client jede Übertragung anstößt. Betroffen wären lediglich die Schnittstelle der Stellvertreter, die dann Koroutinen anbieten müssten, sowie die Schleife, die auf das Ergebnis wartet. Ob sich dieser Aufwand lohnt, hängt jedoch davon ab, wie viel die Anwendung neben der Anzeige zu tun hat.

Eine zweite Einschränkung betrifft den Rückfluss von Ereignissen, dessen Abstand zwischen zwei Abfragen durch die Dauer eines Aufrufs nach unten begrenzt ist und somit im Bereich einer halben Sekunde liegt. Seit der in @sec:ansteuerung beschriebenen Änderung geht dabei zwar kein Ereignis mehr verloren, die Anwendung erfährt jedoch erst mit dieser Verzögerung davon. Hinzu kommt, dass jeder Button einzeln abgefragt wird, sodass die Anzahl der Aufrufe mit der Anzahl der Bedienelemente wächst.

=== Latenz und Durchsatz

Die Dauer eines Aufrufs ergibt sich aus der Anzahl der Round Trips multipliziert mit 114 ms, wovon zwei unabhängig von der Nachrichtenlänge auf das Abholen des Ergebnisses entfallen. Bei kurzen Aufrufen macht dieser feste Anteil bereits die Hälfte der Gesamtzeit aus.

Eine Reaktion, die über den Client läuft, benötigt zwei Aufrufe und liegt damit im Mittel bei rund 1490 ms. Die Anforderung K4 von 100 ms wird auf diesem Weg um fast das Fünfzehnfache verfehlt. Erreichbar ist sie nur über ein Binding, das der Server selbst ausführt und das nach @tab:reaktion unter 51 ms bleibt. Damit ist die Zahl der Reaktionen, die in der geforderten Zeit möglich sind, durch den kleinen Satz an Aktionen aus @tab:aktionen begrenzt.

Der Durchsatz war kein Entwurfsziel und fällt entsprechend gering aus, da eine Nachricht von 142 Byte den Bus bereits für 1,5 Sekunden belegt. Für Text und einzelne Bedienelemente reicht das aus, für Bilddaten oder fortlaufende Messwerte jedoch nicht.

=== Abstraktionsgrenzen

Die Aufrufstransparenz aus @sec:architektur trägt syntaktisch, nicht zeitlich, denn ein Aufruf sieht zwar wie ein lokaler Aufruf aus, dauert jedoch um Größenordnungen länger. Das entspricht der Einordnung aus @sec:grundlagen-rpc und ist eine grundsätzliche Eigenschaft entfernter Aufrufe, keine Schwäche der Umsetzung.

Beim Erweitern des Objektmodells bleiben Transport- und Kommunikationsschicht unberührt, das Objektmodell selbst aber nicht. Wie @sec:erweiterung an einem Fortschrittsbalken zeigt, braucht ein neuer Objekttyp eine Basisklasse, einen Stellvertreter, einen Adapter und zusätzlich eine Fabrikmethode in dem Objekt, das ihn erzeugt. Auch das Ereignismodell ist bisher auf Buttons zugeschnitten, da nur dort Rückrufe bei der Anzeigebibliothek angemeldet werden. Erweiterbar ist das Modell also, aber nicht ohne Eingriff an mehreren Stellen.

Die Prüfung von Referenzen stößt an eine Grenze, die sich aus ihrer Breite ergibt, da sich die Generation eines Slots nach 64 Freigaben wiederholt. Ein Stellvertreter, der die ganze Zeit besteht, passt danach wieder auf ein fremdes Objekt. Hinzu kommt, dass der Client lediglich die Stellvertreter kennt, die er selbst hält. Löscht er einen Screen, bleiben die Stellvertreter der Elemente darauf lokal gültig und werden erst vom Server abgewiesen.

Schließlich führt das schemafreie Format keine Typinformationen mit, sodass sich erst zur Laufzeit herausstellt, ob eine Methode existiert und ob die Argumente passen. Verwenden beide Seiten unterschiedliche Codecs, lässt sich die Nutzlast zwar dekodieren, ergibt aber keinen gültigen Aufruf mehr. Beide Seiten weisen diesen Fall inzwischen mit einer eindeutigen Meldung ab, verhindern lässt er sich im Entwurf jedoch nicht.

== Übertragbarkeit auf andere Verbindungsklassen

Der Entwurf nimmt in @sec:architektur und @sec:entwurf durchgehend auf die Merkmale der Verbindungsklasse aus @sec:verallgemeinerung Bezug und nicht auf den LEGO-Bus. Alles Wegabhängige liegt unterhalb der Interceptor-Schnittstelle, die lediglich aus einer einzigen Operation besteht, sodass eine andere Verbindung angebunden wird, indem genau diese Operation neu umgesetzt wird.

Prüfen lässt sich das an den Größen, die von der Verbindung abhängen, also an der Blockgröße und den daraus abgeleiteten Werten für die Nutzlast je Frame, die Breite des Längenfelds und die maximale Nachrichtenlänge. Alle vier stehen als Konstanten an einer Stelle, und @sec:evaluation zeigt mit dem Wechsel von 13 auf 7 Byte, dass eine Änderung tatsächlich nur dort stattfindet. Für @i2c oder Modbus im @rtu\-Modus wäre derselbe Weg gangbar, sofern die Gegenseite Blöcke fester Größe auf Anfrage austauschen kann.

Nicht übertragbar ist hingegen die Annahme, dass immer nur eine Nachricht unterwegs ist, da sie aus dem anfragegetriebenen Kanal und der fehlenden Nebenläufigkeit folgt. Auf einer Verbindung, die mehrere gleichzeitige Übertragungen erlaubt, müssten die Rekonstruktion und die Verwaltung der Ergebnisse je Kennung getrennt werden, wie @sec:fragmentierung beschreibt.

== Mögliche Erweiterungen

Die folgenden Erweiterungen setzen an den Grenzen aus @sec:evaluation an, wobei die ersten beiden das Protokoll und die Anzahl der Übertragungen betreffen und die übrigen die Serialisierung, den Hardwareaufbau sowie den Umfang des Objektmodells.

=== Ergebnis mit der Bestätigung

Nach @sec:evaluation kostet das Abholen des Ergebnisses unabhängig von der Nachrichtenlänge zwei Round Trips und somit 228 ms je Aufruf. Die meisten Aufrufe sind auf dem Server jedoch in Mikrosekunden ausgeführt, und ihr Ergebnis ist mit vier Byte kürzer als ein einzelner Frame. Statt die Ausführung aufzuschieben und das Ergebnis abfragen zu lassen, könnte der Server den Aufruf deshalb beim letzten Datenframe direkt ausführen und das Ergebnis zusammen mit der Bestätigung zurückgeben.

Der Kanal bliebe dabei anfragegetrieben, da es sich weiterhin um eine Antwort handelt. Passt das Ergebnis nicht in einen Frame, meldet der Server lediglich, dass es bereitliegt, und das Abholen läuft wie bisher ab. Für einen kurzen Aufruf sinkt die Anzahl der Round Trips somit von fünf auf drei und die Dauer entsprechend von rund 570 ms auf rund 340 ms.

Zwei Punkte sind dabei zu beachten. Zum einen ist der Bus während der Ausführung belegt, was für Aufrufe an die Anzeigebibliothek unkritisch ist, für längere Operationen jedoch ein zusätzliches Kennzeichen erfordern würde. Zum anderen prüft die Sendeschleife des Clients bisher nur Position und Art der Antwort, wie @sec:nebenlaeufigkeit beschreibt, und müsste zusätzlich die Kennung der Nachricht auswerten. Trägt die Bestätigung das Ergebnis, ist eine veraltete Antwort kein verworfener Frame mehr, sondern ein falscher Rückgabewert.

=== Ereignisgetriebener Rückkanal

Die zweite Erweiterung betrifft die Anzahl der Abfragen. Heute wird jeder Button einzeln abgefragt, und jede Abfrage ist ein vollständiger Aufruf. Bei fünf Buttons sind das fünf Aufrufe je Durchlauf, also nach @sec:evaluation etwa drei Sekunden. Stattdessen könnte das Display eine Methode anbieten, die alle seit der letzten Abfrage aufgelaufenen Ereignisse aller Objekte auf einmal liefert. Der Puffer läge dann nicht je Objekt, sondern gemeinsam vor, wodurch die Anzahl der Abfragen unabhängig von der Anzahl der Bedienelemente wäre. Zugleich fiele der zusätzliche Round Trip wieder weg, den die Antwort je Button nach @sec:reaktionszeit heute kostet, da eine gemeinsame Antwort nur einmal übertragen werden muss.

Darauf aufbauend könnte die Anwendung Rückrufe je Button registrieren, statt die Zustände selbst abzufragen, sodass die Schleife nur noch aus einem einzigen Aufruf bestünde, der die Ereignisse verteilt. Eine weitere Verbesserung wäre ein Hinweis in jeder Bestätigung, ob überhaupt Ereignisse anliegen. Der Client müsste dann lediglich nachfragen, wenn es etwas abzuholen gibt, wodurch die Abfrage im Leerlauf vollständig entfiele.

=== Alternative Serialisierung

Die @json benötigt nach @sec:evaluation das 1,21-fache an Round Trips gegenüber MessagePack. Der Wechsel auf das binäre Format spart also etwa 17 % der Übertragungen. Ein schemagebundenes Format wie Protocol Buffers könnte die Nutzlast weiter verkürzen, da Schlüssel dann gar nicht mehr übertragen werden. Der Preis dafür wären ein Übersetzungsschritt und eine Beschreibung der Schnittstelle, die beide Seiten teilen, was nach @sec:serialisierung gerade der Grund für ein schemafreies Format war. Ob sich der Aufwand lohnt, ließe sich mit dem vorhandenen Messaufbau beantworten, da der Codec an einer einzigen Stelle austauschbar ist.

=== Integrierter Hardwareaufbau <sec:standalone>

Der Aufbau aus @sec:hardwareaufbau besteht aus drei Baugruppen und zwei Steckverbindungen. Eine eigenständige Platine, die den Mikrocontroller, das Display und die Versorgung vereint, war als zweite Ausbaustufe geplant, wurde aus Zeitgründen jedoch nicht gebaut. Sie würde den Aufbau mechanisch robuster machen und die Spannungsversorgung sauber lösen, während sich am Protokoll, an der Latenz und an der Software nichts ändern würde. Der folgende Abschnitt umreißt, welche Funktionsgruppen eine solche Platine enthalten müsste, da die bisher verwendeten Baugruppen diese Aufgaben mitbringen und sie bei deren Wegfall neu zu lösen sind.

Ausgangspunkt ist der Sensorport des Hubs. Er führt neben Masse und den beiden Datenleitungen eine Logikversorgung von 3,3 V sowie die höhere Versorgung auf der Leitung M+, die das Gerät nach @sec:busanbindung ausdrücklich anfordert. Die Logikversorgung des Ports ist für die Elektronik eines Sensors ausgelegt und reicht für ein Display mit Hintergrundbeleuchtung nicht aus, weshalb die Platine ihre eigene Spannung aus M+ erzeugen muss.

*Spannungsversorgung.* Ein Abwärtswandler erzeugt aus den etwa 8 V der Leitung M+ die 3,3 V für Mikrocontroller, Display und Touchcontroller. Ein linearer Regler ist dafür ungeeignet, da er die Differenz in Wärme umsetzt und bei einem Strom von einigen hundert Milliampere über ein Watt abführen müsste. Der Wandler braucht außerdem einen Pufferkondensator, der den Einschaltstrom der Hintergrundbeleuchtung abfängt.

*Versorgung über USB.* Für die Entwicklung wird die Platine über USB versorgt, im Betrieb am Hub dagegen über M+. Beide Quellen dürfen sich nicht gegenseitig speisen, weshalb eine Umschaltung über zwei Dioden oder über einen Lastschalter nötig ist. Diese Schaltung entscheidet zugleich, welche Quelle Vorrang hat, wenn beide anliegen.

*Schutz der Eingänge.* Der Port ist steckbar und damit den üblichen Gefahren ausgesetzt. Vorgesehen werden sollten ein Verpolschutz auf M+, eine rückstellende Sicherung sowie Schutzdioden gegen elektrostatische Entladung auf allen Leitungen, die nach außen führen.

*Anbindung an den Bus.* Die beiden Datenleitungen des Ports arbeiten mit 3,3 V und können direkt an den Mikrocontroller geführt werden. Sinnvoll sind Serienwiderstände und ein definierter Ruhepegel auf der Sendeleitung, da die Gegenseite beim Verbindungsaufbau nach @sec:busanbindung einen festen Zustand erwartet.

*Mikrocontroller mit seiner Grundbeschaltung.* Dazu gehören die Abblockkondensatoren, die Beschaltung des Reset-Eingangs und die Taster für Reset und Startmodus. Besonderes Augenmerk verdienen die Pins, die beim Start abgefragt werden, da sie den Startmodus und die Flash-Spannung festlegen. @sec:hardwareaufbau beschreibt den Fall, in dem die SD-Karte eine solche Leitung beim Start auf einen ungünstigen Pegel zieht.

*Programmierschnittstelle.* Ohne Steckplatine fehlt der Weg, die Firmware aufzuspielen. Nötig ist entweder ein Brückenbaustein von USB auf eine serielle Schnittstelle samt der üblichen Schaltung, die Reset und Startmodus automatisch setzt, oder ein Mikrocontroller mit eigener USB-Schnittstelle.

*Anschluss des Displays.* Das Display wird über die vorhandenen Leitungen für @spi angebunden, der Touchcontroller über @i2c mit den beiden Pull-up-Widerständen, die der Bus verlangt. Die Hintergrundbeleuchtung sollte über einen Transistor geschaltet werden, damit sie sich dimmen und im Leerlauf abschalten lässt. Im heutigen Aufbau leuchtet sie dauerhaft.

Zwei Punkte gehen über die reine Schaltung hinaus. Die Platine muss sich mechanisch in den Aufbau einfügen, also zu den Maßen des Displays und zu den Befestigungspunkten des Hubs passen. Zudem sollte sie Messpunkte für die Versorgungsspannungen und die beiden Datenleitungen vorsehen, da eine Messung an einem gesteckten Aufbau sonst kaum möglich ist. Der Nutzen bliebe dabei auf Mechanik, Versorgung und Handhabung beschränkt. An der Anzahl der Übertragungen, der Latenz aus @sec:evaluation und der Software würde sich nichts ändern.

=== Weitere Peripherieklassen

Das Objektmodell bildet bisher Screens, Labels und Buttons ab, wobei sich weitere Elemente wie Eingabefelder oder Listen nach demselben Muster ergänzen ließen. Interessanter ist jedoch der Schritt darüber hinaus, denn die Schichten unterhalb des Objektmodells kennen keine Anzeige, sondern lediglich Aufrufe an benannte Empfänger. Eine andere Geräteklasse, beispielsweise ein Sensor mit eigener Auswertung, ließe sich somit über dieselbe Middleware anbinden, indem ein weiterer Dispatcher registriert wird.

== Zusammenfassung

Die vorliegende Arbeit entwirft eine Middleware, die entfernte Objekte über eine anfragegetriebene Verbindung mit sehr kleiner Paketgröße nutzbar macht, und setzt diese für die Anbindung eines Touchscreen-Displays an einen LEGO-Hub um. Der Entwurf gliedert sich in fünf Schichten, die von der Busanbindung über die Transport- und die Kommunikationsschicht bis zum Objektmodell reichen und alles Wegabhängige in der untersten Schicht bündeln.

Die Messungen zeigen, dass die Anzahl der Übertragungen die Dauer eines Aufrufs bestimmt. Ein Round Trip kostet 114 ms, unabhängig von Format und Nachrichtenlänge. Der schlankere Header und das binäre Format zusammen halbieren die Anzahl der nötigen Übertragungen gegenüber der ersten Fassung. Fünf der sechs Kommunikationsanforderungen sind erfüllt. Einzig die geforderte Antwortzeit wird nur über lokal ausgeführte Bindings eingehalten, nicht aber über den Weg durch die Steuereinheit.

Damit steht ein System zur Verfügung, das eine interaktive Oberfläche über eine Verbindung bedient, die dafür ursprünglich nicht vorgesehen war. Die verbleibenden Schwächen sind benannt, gemessen und in ihren Ursachen verstanden, wobei für die beiden wichtigsten ein Weg vorliegt, der ohne Änderung des Kommunikationsmodells auskommt.
