= Fazit und Ausblick <sec:fazit>

Dieses Kapitel ordnet die Ergebnisse ein, indem zunächst die Grenzen des Entwurfs benannt werden, die sich aus den Messungen in @sec:evaluation ergeben. Anschließend wird geprüft, wie weit sich die Lösung von der betrachteten Plattform gelöst hat, woran sich die möglichen Erweiterungen anschließen. Den Abschluss bildet die Zusammenfassung der Ergebnisse.

== Limitierungen <sec:limitierungen>

Die folgenden drei Abschnitte behandeln die Grenzen des Kommunikationsmodells, die erreichbare Latenz und die Stellen, an denen die Abstraktion nicht vollständig trägt.

=== Kommunikationsmodell

Die Anwendung auf dem Client blockiert, solange ein Aufruf läuft, was unmittelbar aus der fehlenden Nebenläufigkeit in @sec:einschraenkungen folgt. Nach @sec:uebertragungsaufwand dauert ein kurzer Aufruf wie `set_text` mit 21 Byte 457 ms, die Abfrage eines Buttons nach @sec:reaktionszeit 572 ms, im ungünstigsten Fall jedoch ein Vielfaches davon. Die Obergrenzen aus @tab:rückkanal begrenzen nämlich jede Phase für sich und nicht den Aufruf als Ganzes. Je Frame sind acht Versuche zulässig, und die fünf Sekunden der Wartephase zählen allein die Pausen zwischen zwei Abfragen, nicht die Abfragen selbst. Für einen Aufruf aus $N$ gesendeten und $M$ abzuholenden Frames ergibt sich daraus mit der Anzahl der Versuche $A$, der Dauer eines Round Trips $t$, dem Abfrageintervall $t_p$ und der Wartegrenze $T_w$

$ T_"max" = (N + M) dot A dot t + (T_w / t_p + 1) dot t + T_w $

als Schranke. Mit den Werten der Referenzimplementierung sind das für einen kurzen Aufruf mit zwei gesendeten und einem abzuholenden Frame rund 19 Sekunden und für einen Aufruf über elf Frames rund 27 Sekunden. Der Wert ist eine Schranke und kein erwarteter Fall, denn in den Messungen mit 100 ms Wartezeit trat eine einzige Wiederholung auf. Für ein Programm, das nebenher einen Roboter steuert, ist allerdings schon die Schranke entscheidend, weil sie angibt, wie lange die Steuerung im Fehlerfall stillsteht. In dieser Zeit steht alles still, was sonst im selben Programm läuft, insbesondere die Regelung von Motoren und das Auslesen von Sensoren. Für ein Programm, das eine Anzeige bedient und gleichzeitig einen Roboter steuert, stellt dies die größte Einschränkung des Entwurfs dar.

Pybricks bietet inzwischen kooperatives Multitasking über `async` und `await` @ToolsGeneralPurpose, womit sich das Warten auf ein Ergebnis unterbrechen ließe, ohne die übrige Anwendung anzuhalten. Der anfragegetriebene Rückkanal bliebe dabei unverändert, da weiterhin der Client jeden Austausch beginnt. Betroffen wären lediglich die Schnittstelle der Stellvertreter, die dann Koroutinen anbieten müssten, sowie die Schleife, die auf das Ergebnis wartet. Ob sich dieser Aufwand lohnt, hängt jedoch davon ab, wie viel die Anwendung neben der Anzeige zu tun hat.

Eine zweite Einschränkung betrifft den Rückfluss von Ereignissen, dessen Abstand zwischen zwei Abfragen durch die Dauer eines Aufrufs nach unten begrenzt ist und somit im Bereich einer halben Sekunde liegt. Seit der in @sec:ansteuerung beschriebenen Änderung geht dabei zwar kein Ereignis mehr unbemerkt verloren, die Anwendung erfährt jedoch erst mit dieser Verzögerung davon. Hinzu kommt, dass jeder Button einzeln abgefragt wird, sodass die Anzahl der Aufrufe mit der Anzahl der Bedienelemente wächst.

=== Latenz und Durchsatz

Die Dauer eines Aufrufs ergibt sich aus der Anzahl der Round Trips multipliziert mit 114 ms, wovon zwei unabhängig von der Nachrichtenlänge auf das Abholen des Ergebnisses entfallen. Bei kurzen Aufrufen macht dieser feste Anteil bereits die Hälfte der Gesamtzeit aus. Die 114 ms sind dabei keine Eigenschaft des Busses, sondern bestehen nach @sec:diskussion zu 100 ms aus einer Wartezeit, die während der Entwicklung in der Busanbindung festgelegt wurde. Die folgende Einschränkung gilt also für den gemessenen Stand und nicht für die Verbindungsklasse.

Eine Reaktion, die über den Client läuft, benötigt zwei Aufrufe und liegt damit im Mittel bei rund 1490 ms. Die Reaktion dauert damit im gemessenen Stand rund fünfzehnmal so lange, wie K4 zulässt, mit den Erweiterungen aus @sec:wartezeit gerechnet noch etwa dreieinhalbmal so lange. Erreichbar ist sie nur über ein Binding, das der Server selbst ausführt und das nach @tab:reaktion höchstens 59 ms benötigt. Damit ist die Zahl der Reaktionen, die in der geforderten Zeit möglich sind, durch den kleinen Satz an Aktionen aus @tab:aktionen begrenzt.

Der Durchsatz war kein Entwurfsziel und fällt entsprechend gering aus, da eine Nachricht von 142 Byte den Bus im gemessenen Stand bereits für 1,5 Sekunden belegt. Für Text und einzelne Bedienelemente reicht das aus, für Bilddaten oder fortlaufende Messwerte jedoch nicht.

=== Abstraktionsgrenzen

Die Aufrufstransparenz aus @sec:architektur trägt syntaktisch, nicht zeitlich, denn ein Aufruf sieht zwar wie ein lokaler Aufruf aus, dauert jedoch um Größenordnungen länger. Das entspricht der Einordnung aus @sec:grundlagen-rpc und ist eine grundsätzliche Eigenschaft entfernter Aufrufe, keine Schwäche der Umsetzung.

Beim Erweitern des Objektmodells bleiben Transport- und Kommunikationsschicht unberührt, das Objektmodell selbst aber nicht. Wie @sec:erweiterung an einem Fortschrittsbalken zeigt, braucht ein neuer Objekttyp eine Basisklasse, einen Stellvertreter, einen Adapter und zusätzlich eine Fabrikmethode in dem Objekt, das ihn erzeugt. Auch das Ereignismodell ist bisher auf Buttons zugeschnitten, da nur dort Rückrufe bei der Anzeigebibliothek angemeldet werden. Erweiterbar ist das Modell also, aber nicht ohne Eingriff an mehreren Stellen.

Die Prüfung von Referenzen stößt an eine Grenze, die sich aus ihrer Breite ergibt, da sich die Generation eines Slots nach 64 Freigaben wiederholt. Ein Stellvertreter, der die ganze Zeit besteht, passt danach wieder auf ein fremdes Objekt. Hinzu kommt, dass der Client lediglich die Stellvertreter kennt, die er selbst hält. Löscht er einen Screen, bleiben die Stellvertreter der Elemente darauf lokal gültig und werden erst vom Server abgewiesen.

Schließlich führt das schemafreie Format keine Typinformationen mit, sodass sich erst zur Laufzeit herausstellt, ob eine Methode existiert und ob die Argumente passen. Verwenden beide Seiten unterschiedliche Codecs, lässt sich die Nutzlast zwar dekodieren, ergibt aber keinen gültigen Aufruf mehr. Beide Seiten weisen diesen Fall inzwischen mit einer eindeutigen Meldung ab, verhindern lässt er sich im Entwurf jedoch nicht.

Für die Anwendung sichtbar ist auch der Wertebereich der Ganzzahlen. Die Kodierung trägt nach @sec:umsetzung-codec nur Werte von $-32768$ bis $65535$, sodass etwa ein Zeitstempel aus `ticks_ms` oder ein Zähler oberhalb von 65535 nicht übertragen werden kann. Als Argument scheitert ein solcher Wert noch auf dem Client mit einem `OverflowError`. Diese Ausnahme gehört nicht zu den Fehlerklassen der Middleware und wird von einer Behandlung für `RemoteError` deshalb nicht erfasst. Steckt der Wert im Ergebnis, fällt er erst auf, wenn die Methode bereits ausgeführt ist, und der Client erhält eine Fehlermeldung für einen Aufruf, der stattgefunden hat.

== Übertragbarkeit auf andere Verbindungsklassen <sec:uebertragbarkeit>

Der Entwurf nimmt in @sec:architektur und @sec:entwurf durchgehend auf die Merkmale der Verbindungsklasse aus @sec:verallgemeinerung Bezug und nicht auf den LEGO-Bus. Alles Wegabhängige liegt unterhalb der Interceptor-Schnittstelle, die lediglich aus einer einzigen Operation besteht, sodass eine andere Verbindung angebunden wird, indem genau diese Operation neu umgesetzt wird. Im Stand dieser Arbeit gilt das allerdings nur für den Entwurf und nicht für die Ablage des Codes, wie @tab:zuordnung zeigt. @sec:trennung beschreibt den Umbau, der das nachholt.

Prüfen lässt sich das an den Größen, die von der Verbindung abhängen, also an der Blockgröße und den daraus abgeleiteten Werten für die Nutzlast je Frame, die Breite des Längenfelds und die maximale Nachrichtenlänge. Alle vier stehen als Konstanten an einer Stelle, und @sec:evaluation zeigt mit dem Wechsel von 13 auf 7 Byte, dass eine Änderung tatsächlich nur dort stattfindet. Für @i2c oder Modbus im @rtu\-Modus wäre derselbe Weg gangbar, sofern die Gegenseite Blöcke fester Größe auf Anfrage austauschen kann. Für @ble, das @sec:alternativen als Verbindung zwischen beiden Einheiten verwirft, gilt das für Zerlegung und Rahmung ebenfalls. Den Rückkanal könnte @ble über Benachrichtigungen kürzer gestalten, als der Entwurf ihn vorsieht. Nutzen ließe sich das nur mit einer Erweiterung der Interceptor-Schnittstelle, da sie ausschließlich den Austausch kennt, den der Client beginnt.

Wie weit die Übertragbarkeit belegt ist, unterscheidet sich dabei je Stufe. Architektonisch ist sie vorgesehen, da alles Wegabhängige unterhalb einer einzigen Operation liegt. Nachgewiesen ist sie für eine zweite Umsetzung dieser Operation in Software, wie @sec:testumgebung zeigt, und nach dem Umbau aus @sec:trennung für eine zweite Busanbindung, über die alle Testläufe bestehen, ohne dass PUPRemote geladen wird. Auf einer zweiten realen Verbindung ist sie nicht erprobt, und erst dort träten die Eigenschaften zutage, die die Testverbindung nicht hat, nämlich Laufzeit, Verlust und eine eigene Fehlersemantik. Die Aussagen dieses Abschnitts sind deshalb als begründete Erwartung zu lesen und nicht als Messergebnis.

Nicht übertragbar ist hingegen die Annahme, dass immer nur eine Nachricht unterwegs ist, da sie aus dem anfragegetriebenen Kanal und der fehlenden Nebenläufigkeit folgt. Auf einer Verbindung, die mehrere gleichzeitige Übertragungen erlaubt, müssten die Rekonstruktion und die Verwaltung der Ergebnisse je Kennung getrennt werden, wie @sec:fragmentierung beschreibt.

== Mögliche Erweiterungen

Die folgenden Erweiterungen setzen an den Grenzen aus @sec:evaluation an, wobei die ersten drei den Austausch über den Bus betreffen, also Anzahl und Dauer der Übertragungen, die vierte die Trennung der Busanbindung und die übrigen die Serialisierung, den Hardwareaufbau sowie den Umfang des Objektmodells.

=== Ergebnis mit der Bestätigung <sec:bestaetigung>

Nach @sec:evaluation kostet das Abholen des Ergebnisses unabhängig von der Nachrichtenlänge zwei Round Trips und somit 228 ms je Aufruf. Die Ausführungszeit auf dem Server wurde nicht gemessen, sie liegt nach @sec:uebertragungsaufwand aber unter der Dauer eines Round Trips, denn das Ergebnis liegt bereits bei der ersten Anfrage des Clients vor. Das Ergebnis selbst ist mit vier Byte kürzer als ein einzelner Frame. Statt die Ausführung aufzuschieben und das Ergebnis abfragen zu lassen, führt der Server den Aufruf deshalb besser beim letzten Datenframe direkt aus und gibt das Ergebnis zusammen mit der Bestätigung zurück.

Der Kanal bleibt dabei anfragegetrieben, da es sich weiterhin um eine Antwort handelt. Passt das Ergebnis nicht in einen Frame, meldet der Server lediglich, dass es bereitliegt, und das Abholen läuft wie bisher ab.

Diese Erweiterung ist nach dem Stand `stand-projektarbeit` umgesetzt und gemessen worden. Der Messlauf verwendet dieselbe Konfiguration wie der ursprüngliche, also MessagePack, 13 Byte Nutzlast je Frame und dieselbe Wartezeit von 100 ms, und unterscheidet sich allein im Rückweg des Ergebnisses. @tab:bestaetigung stellt beide gegenüber.

#figure(
  caption: [Aufrufe mit abgeholtem und mit mitgeliefertem Ergebnis, Mediane aus je 20 Aufrufen],
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (right, right, right, right, right),
    table.header(
      [*Nutzlast*],
      table.cell(colspan: 2, align: center)[*abholen*],
      table.cell(colspan: 2, align: center)[*mitgeliefert*],
    ),
    [], [Round Trips], [Dauer], [Round Trips], [Dauer],
    [21 Byte], [4], [457 ms], [2], [229 ms],
    [41 Byte], [6], [685 ms], [4], [457 ms],
    [82 Byte], [9], [1027 ms], [7], [799 ms],
    [142 Byte], [13], [1483 ms], [11], [1255 ms],
  ),
) <tab:bestaetigung>

Über alle acht gemessenen Textlängen hinweg entfallen genau zwei Round Trips, und die Ersparnis beträgt jeweils 228 ms. Das entspricht der Erwartung, denn beide eingesparten Übertragungen sind unabhängig von der Nachrichtenlänge.

Zwei Punkte waren dabei zu beachten, und beide sind in der Umsetzung berücksichtigt. Zum einen ist der Bus während der Ausführung belegt, was für Aufrufe an die Anzeigebibliothek unkritisch ist, für längere Operationen jedoch ein zusätzliches Kennzeichen erfordern würde. Zum anderen prüfte die Sendeschleife des Clients im gemessenen Stand nur Position und Art der Antwort, wie @sec:nebenlaeufigkeit beschreibt. Trägt die Bestätigung das Ergebnis, ist eine veraltete Antwort kein verworfener Frame mehr, sondern ein falscher Rückgabewert, weshalb die Sendeschleife nun zusätzlich die Kennung der Nachricht auswertet. Dass diese Prüfung greift, zeigt @sec:wartezeit.

=== Kürzere Wartezeit der Busanbindung <sec:wartezeit>

Nach @sec:diskussion entfallen 100 der 114 ms je Round Trip auf eine feste Wartezeit, mit der die Busanbindung zwischen Schreiben und Lesen pausiert. Der Wert lässt sich je Aufruf übergeben, ohne Angabe verwendete die eingesetzte Kopie der Bibliothek 100 ms. Der Entwurf ist auf die Folge einer zu kurzen Wartezeit in Grenzen vorbereitet, denn eine zu früh gelesene Antwort ist eine veraltete Antwort, und die erkennt die Transportschicht nach @sec:zuverlaessigkeit und wiederholt den Frame.

Damit wird die Wartezeit zu einer Stellgröße. Jede eingesparte Millisekunde wirkt auf jeden Round Trip und damit auf jeden Aufruf, während jede zusätzliche Wiederholung einen vollen Round Trip kostet. @tab:wartezeit stellt beides gegenüber.

#figure(
  caption: [Wirkung der Wartezeit, je Einstellung 160 Aufrufe über acht Textlängen, Dauer je Round Trip als Mittelwert],
  table(
    columns: (auto, auto, auto, auto),
    align: (right, right, right, left),
    table.header([*Wartezeit*], [*je Round Trip*], [*Wiederholungen*], [*Lauf*]),
    [100 ms], [114,3 ms], [0 von 1000], [vollständig],
    [50 ms], [64,3 ms], [1 von 1001], [vollständig],
    [20 ms], [34,4 ms], [54 von 1054], [vollständig],
    [5 ms], [20,4 ms], [195 von 327], [nach 48 Aufrufen abgebrochen],
    [0 ms], [entfällt], [entfällt], [bricht beim ersten Aufruf ab],
  ),
) <tab:wartezeit>

Die Zeit folgt der Einstellung genau, wie @eq:wartezeit zeigt. Der Preis steigt dagegen nicht gleichmäßig, sondern springt. Bei 50 ms tritt in tausend Übertragungen eine einzige Wiederholung auf, bei 20 ms sind es fünf Prozent, und bei 5 ms in beiden Läufen zusammen zwischen 42 und 78 Prozent, je nach Textlänge. Der Lauf mit 5 ms bricht ab, auch dann noch, wenn die Obergrenze der Versuche von acht auf zwanzig angehoben wird.

Brauchbar ist damit eine Wartezeit von 20 ms. Ein Round Trip kostet dort 34 statt 114 ms, ein Aufruf über zwei Round Trips 69 statt 229 ms. Bei so kurzen Aufrufen trat keine Wiederholung auf, über alle Textlängen kommen fünf Prozent Übertragungen hinzu.

Aufschlussreich ist, woran der Lauf mit 5 ms scheitert. Im Lauf mit zwanzig Versuchen nennt die Fehlermeldung als letzte Antwort einen Frame der Art `DATA_LAST` mit dem Ergebnis des vorangegangenen Aufrufs. Trägt die Bestätigung das Ergebnis, ist eine veraltete Antwort eben kein verworfener Frame mehr, sondern sieht wie ein gültiges Ergebnis aus. Die Prüfung der Nachrichtenkennung, die @sec:bestaetigung als Voraussetzung nennt, greift und weist sie ab. Der Client kommt dann allerdings nicht mehr voran und gibt nach der Obergrenze auf. Die Zusicherung bleibt gewahrt, der Aufruf scheitert mit einer Ausnahme statt ein falsches Ergebnis zu liefern.

Für K4 ändert das nichts am Ergebnis, wohl aber am Abstand. Mit dem Ergebnis in der Bestätigung nach @sec:bestaetigung kostet das Ändern des Textes aus @tab:reaktion drei statt fünf Round Trips, die Abfrage dagegen vier, da ihr Ergebnis zwei Frames belegt und weiterhin abgeholt wird. Bei 20 ms Wartezeit und fünf Prozent Wiederholungen sind das zusammen etwa 253 ms. Das Warten auf die nächste Abfrage sinkt mit einer Abfrage von etwa 138 ms und der Pause von 20 ms im Mittel auf etwa 79 ms. Mit Erkennung, Verarbeitung und Neuzeichnen ergibt das im Mittel rund 360 ms statt rund 1490 ms und damit immer noch etwa das Dreieinhalbfache der geforderten 100 ms. Die Zahl ist berechnet und nicht gemessen, da die Messreihe nur `set_text` betrachtet. Die Folgerung aus @sec:diskussion, dass K4 nur über Bindings erreichbar ist, bleibt damit bestehen.

Statt die Wartezeit fest einzustellen, ließe sie sich auch ganz vermeiden. Der Client könnte nach dem Schreiben wiederholt lesen, bis die passende Antwort vorliegt, und würde damit je Frame genau so lange warten, wie die Gegenseite tatsächlich braucht. Dafür spricht, dass der Anteil der Wiederholungen bei 20 ms tendenziell mit der Länge der Nachricht steigt. Das deutet auf einen langsameren letzten Frame hin, bei dem der Server den Aufruf ausführt, während er die übrigen Frames nur puffert. Voraussetzung ist, dass ein Lesevorgang auf dem Hub ohne eigene Übertragung den zuletzt empfangenen Wert liefert, was noch zu prüfen ist.

Ähnlich ließe sich die Blockgröße angehen. Oberhalb von 16 Byte treten nach @sec:einschraenkungen Prüfsummenfehler auf, deren Ursache in dieser Arbeit nicht geklärt ist. Ließen sie sich beheben, stiege die Nutzlast je Frame von 13 auf 29 Byte, und eine Nachricht bräuchte etwa halb so viele Frames, während ein Round Trip nur um die Übertragungszeit von 16 Byte länger würde. Das Längenfeld des Headers müsste dafür um ein Bit wachsen, was ohne größeren Header möglich ist, da für die acht Opcodes drei Bit genügen. Beide Änderungen betreffen allein die Busanbindung und die Transportschicht.

=== Ereignisgetriebener Rückkanal <sec:rueckkanal-ereignisse>


Eine weitere Erweiterung betrifft die Anzahl der Abfragen. Heute wird jeder Button einzeln abgefragt, und jede Abfrage ist ein vollständiger Aufruf. Bei fünf Buttons sind das fünf Aufrufe je Durchlauf, also nach @sec:evaluation etwa drei Sekunden. Stattdessen könnte das Display eine Methode anbieten, die alle seit der letzten Abfrage aufgelaufenen Ereignisse aller Objekte auf einmal liefert. Der Puffer läge dann nicht je Objekt, sondern gemeinsam vor, wodurch die Anzahl der Abfragen unabhängig von der Anzahl der Bedienelemente wäre. Zugleich fiele der zusätzliche Round Trip wieder weg, den die Antwort je Button nach @sec:reaktionszeit heute kostet, da eine gemeinsame Antwort nur einmal übertragen werden muss.

Darauf aufbauend könnte die Anwendung Rückrufe je Button registrieren, statt die Zustände selbst abzufragen, sodass die Schleife nur noch aus einem einzigen Aufruf bestünde, der die Ereignisse verteilt. Beides ist nach dem Stand `stand-projektarbeit` umgesetzt und in der Testumgebung geprüft, auf der Hardware aber nicht gemessen. Eine weitere Verbesserung wäre ein Hinweis in jeder Bestätigung, ob überhaupt Ereignisse anliegen. Der Client müsste dann lediglich nachfragen, wenn es etwas abzuholen gibt, wodurch die Abfrage im Leerlauf vollständig entfiele.

=== Trennung der Busanbindung <sec:trennung>

Nach @tab:zuordnung liegt der Aufrufteil der Kommunikationsschicht im Stand dieser Arbeit in denselben beiden Klassen wie die Busanbindung, weshalb @tab:anforderungen K6 nur als teilweise erfüllt führt. Nach dem Stand `stand-projektarbeit` ist diese Trennung nachgeholt. Rufende und ausführende Seite liegen nun je in einer Klasse ohne Bezug zum Bus, und die Busanbindung an PUPRemote beschränkt sich auf das, was nur auf diesem Bus existiert. Auf der rufenden Seite sind das die eine Operation der Interceptor-Schnittstelle, also ein Austausch über `remote.call`, und die Registrierung des Kommandos. Auf der ausführenden Seite sind es der Rückruf, den PUPRemote für jeden Frame aufruft, die Umwandlung seiner Nutzlast in Bytes und ebenfalls die Registrierung. Das Objektmodell kennt nur noch die Klasse ohne Bezug zum Bus.

Eine weitere Busanbindung kostet damit auf der rufenden Seite eine Klasse, die genau diese eine Operation umsetzt, und auf der ausführenden Seite die Weitergabe jedes empfangenen Blocks. Die Testumgebung enthält eine solche Busanbindung von rund zehn Zeilen, die beide Seiten im selben Prozess verbindet. Alle Testläufe bestehen auch über sie, und PUPRemote wird dabei nicht geladen. Für den Code ist K6 damit erfüllt. Offen bleibt wie in @sec:uebertragbarkeit die Erprobung auf einer zweiten realen Verbindung.

=== Alternative Serialisierung

@json benötigt nach @sec:evaluation das 1,21-fache an Round Trips gegenüber MessagePack. Der Wechsel auf das binäre Format spart also etwa 17 % der Übertragungen. Ein schemagebundenes Format wie Protocol Buffers könnte die Nutzlast weiter verkürzen, da Schlüssel dann gar nicht mehr übertragen werden. Der Preis dafür wären ein Übersetzungsschritt und eine Beschreibung der Schnittstelle, die beide Seiten teilen, was nach @sec:serialisierung gerade der Grund für ein schemafreies Format war. Ob sich der Aufwand lohnt, ließe sich mit dem vorhandenen Messaufbau beantworten, da der Codec an einer einzigen Stelle austauschbar ist.

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

Die vorliegende Arbeit entwirft eine Middleware, die entfernte Objekte über eine anfragegetriebene Verbindung mit sehr kleiner Paketgröße nutzbar macht, und setzt diese für die Anbindung eines Touchscreen-Displays an einen LEGO-Hub um. Der Entwurf gliedert sich in fünf Schichten von der Busanbindung bis zur Anwendung und bündelt im Entwurf alles Wegabhängige in der untersten Schicht.

Die Messungen zeigen, dass die Anzahl der Übertragungen die Dauer eines Aufrufs bestimmt. Ein Round Trip kostet 114 ms, unabhängig von Format und Nachrichtenlänge. Der schlankere Header und das binäre Format zusammen halbieren die Anzahl der nötigen Übertragungen gegenüber der ersten Fassung. Drei der sechs Kommunikationsanforderungen sind vollständig erfüllt, drei nur teilweise. Teilweise erfüllt sind die Antwortzeit, die nur über lokal ausgeführte Bindings eingehalten wird, der Speicherbedarf, der nur auf der Steuereinheit gemessen ist, und die Unabhängigkeit vom Übertragungsweg.

Damit steht ein System zur Verfügung, das eine interaktive Oberfläche über eine Verbindung bedient, die dafür ursprünglich nicht vorgesehen war. Die verbleibenden Schwächen sind benannt und, soweit der Messaufbau es zulässt, beziffert. Für die wichtigsten liegt ein Weg vor, der ohne Änderung des Kommunikationsmodells auskommt. Das gilt auch für die bestimmende Größe des Systems, denn 100 der 114 ms je Round Trip sind nach @sec:diskussion eine Wartezeit der Busanbindung, die sich verkürzen lässt.
