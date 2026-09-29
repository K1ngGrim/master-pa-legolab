= Evaluation <sec:evaluation>

Dieses Kapitel bewertet die Referenzimplementierung anhand der drei in @sec:einleitung genannten Kriterien. Zunächst wird geprüft, ob sich eine interaktive Oberfläche über die entwickelte Abstraktion umsetzen lässt, bevor der Übertragungsaufwand je Aufruf und die Reaktionszeit auf eine Berührung gemessen werden. Daran schließen sich der Speicherbedarf, eine kurze Bewertung des Hardwareaufbaus sowie die Diskussion der Ergebnisse an.

Gemessen wird mit zwei eigenen Programmen. Das erste läuft auf dem Client und ruft `set_text` mit Texten wachsender Länge auf. Je Aufruf gibt es eine Zeile mit der Länge der Nutzlast, der Anzahl der Frames, der Anzahl der Round Trips, den Wiederholungen sowie den Zeiten für Senden, Warten und Abholen aus. Je Textlänge werden 20 Aufrufe gemessen, denen drei Aufrufe zum Aufwärmen vorausgehen. Das zweite Programm misst die Reaktion auf eine Berührung und wird dabei durch Zeitstempel auf dem Server ergänzt.

Angegeben ist jeweils der Median, da die Verteilungen durch feste Takte nicht symmetrisch sind. Beide Seiten laufen auf dem Logging-Level INFO, da die Ausgabe synchron über die serielle Verbindung erfolgt und andernfalls die Messung bestimmen würde. Vor jedem Lauf wird zudem der Server neu gestartet. Da Client und Server keine gemeinsame Zeitbasis besitzen, wird auf jedem Gerät für sich gemessen und erst in der Auswertung zusammengerechnet.

== Funktionaler Nachweis

Der funktionale Nachweis ergibt sich aus dem Beispielprogramm in @lst:beispielprogramm und aus den Messläufen. Das Beispielprogramm baut zwei Screens mit Labels und Buttons auf, verknüpft Buttons über Bindings mit einem Screenwechsel, schreibt fortlaufend einen Zähler und fragt die Zustände der Buttons ab. Damit sind alle Bestandteile des Objektmodells im Einsatz, also das Erzeugen von Objekten, das Ansprechen über Referenzen, das Ändern von Zuständen, lokale Reaktionen und der Rückfluss von Ereignissen.

Die Messläufe ergänzen das um die Dauer, denn über 640 aufeinanderfolgende Aufrufe hinweg trat keine einzige Wiederholung auf und kein Aufruf schlug fehl. Die Zusicherung aus @sec:zuverlaessigkeit, dass jeder Aufruf ein Ergebnis oder eine Fehlermeldung hinterlässt, wurde in diesen Läufen somit nie in Anspruch genommen.

@tab:anforderungen ordnet die Kommunikationsanforderungen aus @sec:kommunikationsanforderungen dem erreichten Stand zu.

#figure(
  caption: [Erfüllung der Kommunikationsanforderungen],
  text(size: 9pt)[
    #table(
      columns: (auto, 1.2fr, 0.6fr, 1.6fr),
      align: left + top,
      table.header([*Nr.*], [*Anforderung*], [*Stand*], [*Begründung*]),
      [K1], [Strukturierte Nachrichten unbestimmter Länge], [erfüllt], [Nachrichten bis 3315 Byte, gemessen bis 164 Byte über 13 Frames],
      [K2], [Aufrufe mit zuordenbarem Ergebnis], [erfüllt], [das Ergebnis wird unter der Kennung des Aufrufs angefordert, kein falsch zugeordnetes Ergebnis in 640 Aufrufen],
      [K3], [Rückfluss von Ereignissen], [erfüllt], [der Puffer wird beim Abfragen geleert, siehe @sec:reaktionszeit, der Überlauf wird gemeldet, siehe @sec:testumgebung],
      [K4], [Antwortzeit unter 100 ms], [teilweise], [über ein Binding höchstens 57 ms, über den Client rund 1490 ms],
      [K5], [Begrenzter Speicherbedarf], [teilweise], [feste Obergrenzen für Nachrichtenlänge, Ergebnisse und Ereignisse, siehe @tab:rückkanal, auf dem Server nicht gemessen],
      [K6], [Unabhängigkeit vom Übertragungsweg], [erfüllt], [zweiter Übertragungsweg in der Testumgebung, siehe @sec:testumgebung],
    )
  ],
) <tab:anforderungen>

K3 und K4 werden in @sec:reaktionszeit belegt und in @sec:diskussion eingeordnet.

== Nachweis durch die Testumgebung <sec:testumgebung>

Drei Eigenschaften lassen sich am laufenden Aufbau nur schwer zeigen, weil sie
eine zweite Verbindung, einen gezielt herbeigeführten Fehler oder einen
Überlauf voraussetzen. Für sie existiert eine Testumgebung, die unter CPython
läuft und dieselben Adapter, Stellvertreter und Interceptoren verwendet wie die
Anzeigeeinheit. Ersetzt sind nur die Hardware, die Anzeigebibliothek und die
beiden Laufzeitumgebungen.

*Unabhängigkeit vom Übertragungsweg (K6).* Die Testumgebung enthält eine
zweite Busanbindung, also eine zweite Umsetzung genau der einen Operation, die
die Interceptor-Schnittstelle aus @sec:interceptor nach unten verlangt. Sie
befördert einen Block nicht über den Bus, sondern übergibt ihn im selben
Prozess an die Gegenseite und liefert deren Antwort zurück. Oberhalb davon ist
nichts angepasst: derselbe Interceptor, dieselben Stellvertreter, dieselbe
Rahmung, derselbe Codec, dasselbe Objektmodell. Damit läuft der Entwurf
nachweislich über zwei verschiedene Übertragungswege, und die Anforderung ist
nicht nur begründet, sondern gezeigt. Was der Nachweis nicht leistet, ist eine
Aussage über einen zweiten realen Bus, denn die Testverbindung verliert keine
Blöcke und kennt keine Laufzeit.

*Zuverlässigkeit.* Fehler, die im Betrieb selten auftreten, werden dort gezielt
erzeugt. Eine Betriebsart der Testverbindung liefert jede $n$-te Antwort als
die vorangegangene und stellt damit genau die veralteten Antworten nach, die
@sec:zuverlaessigkeit behandelt. Geprüft wird, dass der Aufruf trotzdem
gelingt, dass Wiederholungen auftreten und dass ein wiederholter letzter Frame
die Ausführung kein zweites Mal auslöst. Eine zweite Betriebsart lässt jede
Übertragung scheitern und bildet den Verbindungsabbruch nach. Geprüft wird
dort, dass der Aufruf mit einem Fehler endet und die Session endet, sodass
jeder bestehende Stellvertreter ungültig wird.

*Ereignisverlust (K3).* Der Überlauf des Ereignispuffers tritt in den Messungen
nicht auf, weil er mehr Berührungen zwischen zwei Abfragen verlangt, als von
Hand auszulösen sind. In der Testumgebung wird der Puffer über seine Grenze
hinaus gefüllt. Geprüft wird, dass der Verlust gemeldet und der Zähler mit der
Abfrage zurückgesetzt wird, dass also die in @sec:kommunikationsschicht
geforderte Erkennbarkeit auch im Grenzfall gilt.

Die Testumgebung deckt damit die Stellen ab, an denen die Messungen nichts
aussagen können, und die Messungen decken ab, was sich nur am echten Bus zeigt.
@tab:quelltext im Anhang nennt den Ordner, in dem beide liegen.

== Übertragungsaufwand

Gemessen wird in vier Konfigurationen, die jeweils eine Größe verändern. Die Nutzlast je Frame beträgt 13 Byte im aktuellsten Stand und 7 Byte in der früheren Fassung mit dem größeren Header, während als Serialisierung MessagePack @MessagePackItsJSON und die @json zum Einsatz kommen. Der Vergleich trennt somit die Wirkung der Rahmung von der Wirkung des Formats.

#import "@preview/lilaq:0.4.0" as lq

#let laengen = (0, 10, 20, 40, 60, 80, 100, 120)

#figure(
  caption: [Round Trips je Aufruf über der Textlänge, Median aus je 20 Aufrufen],
  lq.diagram(
    width: 11cm, height: 6.5cm,
    xlabel: [Textlänge in Zeichen],
    ylabel: [Round Trips je Aufruf],
    legend: (position: left + top),
    lq.plot(laengen, (4, 5, 6, 7, 9, 10, 12, 13), label: [13 B, MessagePack]),
    lq.plot(laengen, (6, 7, 7, 9, 10, 12, 14, 15), label: [13 B, @json]),
    lq.plot(laengen, (5, 7, 8, 11, 14, 17, 20, 23), label: [7 B, MessagePack]),
    lq.plot(laengen, (10, 11, 12, 15, 18, 21, 24, 27), label: [7 B, @json]),
  ),
) <abb:roundtrips>

@tab:streuung fasst die vier Konfigurationen zusammen. Innerhalb einer Konfiguration und einer Textlänge ist die Anzahl der Round Trips über alle 20 Wiederholungen identisch, was aus @eq:blöcke folgt und durch die ausgebliebenen Wiederholungen bestätigt wird. Die Streuung liegt also allein in den Zeiten, nicht im Ablauf.

#figure(
  caption: [Streuung der vier Konfigurationen, je 160 Aufrufe],
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, right, right, right, right),
    table.header([*Konfiguration*], [*Round Trips*], [*Median*], [*Minimum*], [*Maximum*]),
    [MessagePack, 13 Byte], [4 bis 13], [920 ms], [457 ms], [1499 ms],
    [MessagePack, 7 Byte], [5 bis 23], [1434 ms], [571 ms], [2642 ms],
    [JSON, 13 Byte], [6 bis 15], [1085 ms], [685 ms], [1716 ms],
    [JSON, 7 Byte], [10 bis 27], [1891 ms], [1142 ms], [3098 ms],
  ),
) <tab:streuung>

Der wichtigste Befund ergibt sich aus dem Vergleich mit den gemessenen Zeiten. Ein Round Trip kostet in jeder Konfiguration und bei jeder Nachrichtenlänge 114,2 ms. Über alle 640 Aufrufe liegen das untere und das obere Quartil bei 114,1 ms und 114,2 ms, das Minimum bei 114,0 ms und die Standardabweichung bei 0,3 ms. Nur 20 der 640 Aufrufe liegen über 115 ms, der höchste bei 117,0 ms. Die Dauer eines Aufrufs ist somit das Produkt aus der Anzahl der Round Trips und einer festen Zeit je Round Trip, da sich weder die Länge der Nutzlast noch die Wahl des Formats darüber hinaus auswirken. Jeder Wert aus @abb:roundtrips lässt sich deshalb unmittelbar in eine Dauer umrechnen, sodass der kürzeste gemessene Aufruf mit 4 Round Trips 457 ms benötigt und der längste mit 27 Round Trips 3082 ms.

Die Anzahl der Round Trips folgt unmittelbar aus @eq:blöcke. Sie setzt sich zusammen aus einem Round Trip je Frame der Nachricht, einer Anfrage `READY` und einem Round Trip je Frame des Ergebnisses. Für die gemessenen Aufrufe mit einem Ergebnis von vier Byte sind das $N + 2$ Round Trips.

Die beiden Einflussgrößen lassen sich daran trennen. Gegenüber dem heutigen Stand mit 13 Byte und MessagePack braucht die Fassung mit 7 Byte das 1,59-fache an Round Trips, die Fassung mit der @json das 1,21-fache und beides zusammen das 2,09-fache. Die Rahmung wiegt also deutlich schwerer als das Format. Der Grund ist in den Daten sichtbar. Die @json erzeugt bei denselben Aufrufen eine um 22 bis 23 Byte längere Nutzlast, was nach @eq:blöcke nicht bei jeder Textlänge eine Blockgrenze überschreitet. Ein kleinerer Header verschiebt dagegen alle Blockgrenzen zugleich. Die Erwartung aus @sec:kosten wird damit bestätigt.

Die Nutzlasteffizienz nach @eq:effizienz fällt dabei niedrig aus. Ein Aufruf mit 21 Byte Nutzlast belegt zwei Frames und somit 32 übertragene Byte, was einem Wert von 0,66 entspricht. Bei 142 Byte über elf Frames ergeben sich 0,81 und damit der höchste bei einem Header von drei Byte erreichbare Wert. Für die Dauer eines Aufrufs bleibt gleichwohl die Anzahl der Frames maßgeblich und nicht ihre Füllung.

Unabhängig von der Nachrichtenlänge kostet jeder Aufruf zwei zusätzliche Round Trips für das Abholen des Ergebnisses und somit 228 ms, was beim kürzesten Aufruf bereits die Hälfte der gesamten Dauer ausmacht. Auffällig ist zudem, dass das Abfrageintervall von 50 ms nie zum Tragen kommt, da die gemessene Wartezeit in 595 der 640 Aufrufe genau 114 ms und im Höchstfall 129 ms beträgt, also stets einen einzigen Round Trip. Der Server ist folglich mit der Ausführung fertig, bevor der Client zum ersten Mal nachfragt.

== Reaktionszeit einer Berührung <sec:reaktionszeit>

Die zweite Messung betrachtet den Weg von einer Berührung bis zur sichtbaren Reaktion und vergleicht dabei die beiden Wege aus @sec:ansteuerung. Über ein Binding führt der Server die Reaktion selbst aus, während über den Client das Ereignis abgefragt und mit einem zweiten Aufruf beantwortet wird. Auf dem Server werden dafür drei Zeitpunkte je Berührung festgehalten, nämlich die erste erkannte Berührung, das verarbeitete Ereignis und das abgeschlossene Neuzeichnen, auf dem Client hingegen die Zeit vom Beginn eines Abfragedurchlaufs bis zum Ende der Reaktion.

Der Touchcontroller wird von der Anzeigebibliothek alle 40 ms abgefragt, gemessen über 39 Berührungen mit Werten zwischen 38 und 42 ms. Eine Berührung wird deshalb im Mittel nach 20 ms und spätestens nach 40 ms bemerkt. Von dort bis zum verarbeiteten Ereignis vergehen 4 ms. Das Neuzeichnen dauert anschließend 6 ms, wenn ein Binding die Anzeige verändert hat, und 7 ms, wenn die Änderung von einem Aufruf des Clients stammt. Über ein Binding ist die Reaktion damit 13 ms nach der erkannten Berührung sichtbar, im Bereich von 10 bis 17 ms. Zusammen mit der Erkennung ergibt das im Mittel 33 ms und im ungünstigsten Fall 57 ms.

Auf dem Weg über den Client dauert allein die Reaktion 1161 ms, da sie aus zwei Aufrufen mit je 5 Round Trips besteht, nämlich dem Abfragen des Ereignisses und dem Ändern des Textes. Hinzu kommt die Zeit, bis überhaupt abgefragt wird, die nicht allein von der Pause in der Schleife der Anwendung abhängt, denn während eines laufenden Aufrufs kann nicht abgefragt werden. Der wirksame Abstand zwischen zwei Abfragen beträgt daher 572 ms zuzüglich der eingestellten Pause.

#figure(
  caption: [Zeit von der Berührung bis zur sichtbaren Reaktion],
  table(
    columns: (1.5fr, auto, auto, auto),
    align: (left, right, right, left),
    table.header([*Teilstrecke*], [*über ein Binding*], [*über den Client*], [*Herkunft*]),
    [Erkennung durch die Anzeigebibliothek], [im Mittel 20 ms], [im Mittel 20 ms], [abgeleitet],
    [Verarbeitung des Ereignisses], [4 ms], [4 ms], [gemessen],
    [Warten auf die nächste Abfrage], [entfällt], [im Mittel 296 ms], [abgeleitet],
    [Abfrage und Reaktion], [entfällt], [1161 ms], [gemessen],
    [Neuzeichnen], [6 ms], [7 ms], [gemessen],
    [Summe im Mittel], [33 ms], [rund 1490 ms], [berechnet],
    [Summe im ungünstigsten Fall], [57 ms], [rund 1800 ms], [berechnet],
  ),
) <tab:reaktion>

Die Spalte Herkunft unterscheidet, ob ein Wert unmittelbar gemessen, aus einer Messung abgeleitet oder aus den übrigen Zeilen berechnet wurde. Die gemessenen Werte sind Mediane. Die Verarbeitung des Ereignisses streut über 39 Berührungen von 4 bis 7 ms, das Neuzeichnen von 5 bis 11 ms über ein Binding und von 7 bis 8 ms über den Client. Die beiden Zeilen addieren sich nicht zu den Summen darunter, denn Mediane sind nicht additiv. Maßgeblich ist die je Berührung gemessene Zeit von der Erkennung bis zum fertigen Bild, deren Median bei 13 ms liegt und die zwischen 10 und 17 ms streut. Die Summen beruhen auf diesem Wert und nicht auf der Addition der Einzelmediane. Die Reaktion über den Client liegt in allen drei Läufen bei 1160 bis 1177 ms, mit einem einzelnen Ausreißer von 1277 ms, der weiter unten erklärt wird. Abgeleitet sind die beiden Wartezeiten: die Erkennung ist der halbe Abtasttakt, das Warten auf die nächste Abfrage die halbe Summe aus Aufrufdauer und eingestellter Pause. Berechnet sind die Summen, die sich aus den Zeilen darüber ergeben.

Die Werte in @tab:reaktion gelten für eine Pause von 20 ms in der Schleife der Anwendung. Gemessen wurde zusätzlich mit 0 ms und 1000 ms, wobei die Reaktion selbst in allen drei Fällen gleich lang ausfällt, da die Pause vor der Abfrage liegt. Bei einer Pause von 1000 ms steigt die Summe im Mittel auf rund 1980 ms, weil sich der Abstand zwischen zwei Abfragen entsprechend verlängert.

Dieser Abstand bestimmt zugleich, welche Berührungen überhaupt ankommen. In einer früheren Fassung lieferte eine Abfrage nur das jüngste Ereignis eines Objekts. Wurde ein Button gedrückt und wieder losgelassen, bevor die nächste Abfrage stattfand, stand im Puffer zuletzt das Loslassen, und die Berührung war vollständig verloren. Erkannt wurde sie nur, wenn sie zum Zeitpunkt der Abfrage noch andauerte, was bei einer Pause von 1000 ms ein Halten von etwa 1,6 Sekunden erforderte.

Diese Beobachtung war der Anlass für die in @sec:ansteuerung beschriebene Trennung von Zustand und aufgelaufenen Ereignissen. Um sie zu prüfen, wurde die Messung wiederholt und dabei je Variante zwanzigmal kurz getippt. @tab:ereignisse stellt die Ergebnisse zusammen.

#figure(
  caption: [Erkannte Berührungen bei zwanzig kurzen Tippern je Variante],
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, right, right, right, right),
    table.header([*Pause*], [*erkannt*], [*gezählte Drucke*], [*verloren*], [*Wiederholungen*]),
    [0 ms],    [20], [20], [0], [0],
    [20 ms],   [20], [22], [0], [1],
    [1000 ms], [20], [20], [0], [0],
  ),
) <tab:ereignisse>

Kein Tipper ging verloren, und zwar unabhängig von der Pause in der Schleife. Bei einer Pause von 20 ms weist der Lauf 22 gezählte Drucke bei 20 erkannten Berührungen aus. Zweimal fielen also zwei Tipper in dasselbe Abfrageintervall, und beide wurden gemeldet. Anforderung K3 ist damit erfüllt, und das Halten eines Buttons ist nicht mehr nötig.

Bezahlt wird das mit einem zusätzlichen Round Trip je Abfrage. Die Antwort trägt nun den Zustand, die Anzahl der Drucke und die Anzahl der verworfenen Ereignisse, passt damit nicht mehr in einen einzigen Frame und benötigt zwei Frames für den Rückweg. Eine Abfrage kostet dadurch 5 statt 4 Round Trips, also 572 ms statt 458 ms. Die Dauer einer Reaktion bleibt davon unberührt, da der zweite Aufruf unverändert ist.

Die Wiederholung im Lauf mit 20 ms Pause ist der einzige Fall einer veralteten Antwort in allen Messungen dieser Arbeit. Sie kostete einen Round Trip, die betroffene Reaktion dauerte 1277 ms statt 1161 ms. Der Mechanismus aus @sec:zuverlaessigkeit greift damit auch im Betrieb und nicht nur im Entwurf.

== Ressourcenverbrauch

Auf dem Hub belegt das Programm nach dem Aufbau der Oberfläche 16272 Byte gegenüber 16128 Byte davor, sodass eine Oberfläche aus zwei Screens, zwei Labels und zwei Buttons auf dieser Seite lediglich 144 Byte kostet. Der übrige Speicher entfällt auf die Middleware und die Laufzeitumgebung. Die Werte sind in allen vier Läufen identisch, womit der Speicherbedarf weder vom Format noch von der Frame-Größe abhängt. Der gebündelte Quelltext für den Hub umfasst 68 KB.

Der Speicherbedarf auf dem Server wurde dagegen nicht gemessen, da dort die Anzeigebibliothek den größten Teil des Heaps belegt und die Middleware selbst daneben kaum ins Gewicht fällt. Eine belastbare Aussage müsste den Verbrauch vor und nach dem Aufbau der Oberfläche vergleichen.

== Bewertung des Hardwareaufbaus

Die Adapterplatine ist ein Zwischenschritt weg vom Steckbrett, auf dem der Aufbau in einer ersten Vorführung noch beruhte. Da sich Display und Mikrocontroller aufstecken lassen, beschränkt sich die Hardware auf das Nötigste, nämlich auf die Verbindung beider Baugruppen. Die Platine führt alle benötigten Leitungen auf Buchsenleisten, die sich ohne besondere Ausrüstung löten lassen. Dadurch lassen sich weitere Exemplare zügig aufbauen, und die aufgesteckten Baugruppen bleiben für andere Zwecke verwendbar. Die Anforderungen D1 bis D3 und S1 bis S3 aus @sec:zielsystem erfüllt der Aufbau damit, wie @sec:hardwareaufbau im Einzelnen belegt.

Steckverbindungen sind allerdings keine gute Wahl für die Signalintegrität und zählen im Betrieb zu den häufigsten Fehlerquellen. Für einen Aufbau, der im Labor erprobt und zwischen Versuchen umgesteckt wird, ist das vertretbar, für einen dauerhaften Einsatz dagegen nicht. @abb:platine zeigt beide Seiten der Platine als dreidimensionale Darstellung aus dem Entwurfswerkzeug. Neben den Buchsenleisten sind dort die Versionsnummer der Platine sowie die Bezeichnungen der Bauteile aufgedruckt, was die Bestückung und die spätere Zuordnung erleichtert.

#figure(
   image("../figures/3d_render.png"),
   caption: [Vorderseite (rechts) und Rückseite (links) der Adapterplatine als 3D Rendering],
 ) <abb:platine>

== Diskussion der Ergebnisse <sec:diskussion>

Die Messungen bestätigen die Annahme, auf der der gesamte Entwurf beruht, denn für die Dauer eines Aufrufs zählt die Anzahl der Übertragungen und nicht die übertragene Datenmenge. Jede eingesparte Übertragung spart 114 ms, unabhängig davon, wie viele Byte sie transportiert hätte. Der Wechsel von der früheren Rahmung und der @json auf den heutigen Stand halbiert somit die Dauer eines Aufrufs.

Erklärungsbedürftig sind die 114 ms selbst, denn bei 115200 Baud dauert die Übertragung eines Blocks von 16 Byte deutlich weniger als eine Millisekunde. Die Zeit entsteht folglich nicht auf der Leitung, sondern in den beteiligten Bibliotheken und Ereignisschleifen, zumal auf dem Server die Verarbeitung der Transportbibliothek etwa jede Millisekunde aufgerufen wird und je Durchlauf höchstens ein Kommando bearbeitet. Wie viel Zeit dabei auf welche Seite entfällt, lässt sich mit den vorhandenen Daten nicht beantworten, dafür wäre eine Messung innerhalb der Busanbindung nötig.

Für K4 ergibt sich ein zweigeteiltes Bild, denn über ein Binding liegt die Reaktion mit höchstens 57 ms sicher innerhalb der geforderten 100 ms, über den Client dagegen um fast das Fünfzehnfache darüber. Die lokalen Bindings sind somit nicht nur eine Abkürzung, sondern unter den in dieser Arbeit umgesetzten Mechanismen der einzige Weg, eine Reaktion in der geforderten Zeit anzuzeigen. Dass ihr Satz an Aktionen klein ist, begrenzt zugleich, welche Reaktionen in dieser Zeit überhaupt möglich sind.

Die Einleitung motiviert die Arbeit mit der Vermittlung von Technikkenntnissen an Kinder und Jugendliche. Ob die entstandene Schnittstelle dafür handhabbar ist, wurde nicht untersucht, dazu wäre eine Erprobung mit Lernenden nötig. Am Beispielprogramm in @lst:beispielprogramm lässt sich immerhin ablesen, was sie voraussetzt. Das Erzeugen und Verändern von Elementen sieht aus wie gewöhnliche Python-Programmierung, und nichts davon verlangt Kenntnis des Protokolls. Drei Stellen treten dennoch nach außen. Erstens blockiert jeder Aufruf, sodass eine Schleife mit Wartezeit nötig ist und die Anzeige nicht nebenbei bedient werden kann. Zweitens müssen Schaltflächen abgefragt werden, was eine Schleife erzwingt, statt auf ein Ereignis zu warten. Drittens werden Stellvertreter nach `clear()` ungültig, was zu einer Ausnahme führt, deren Ursache zeitlich weit von ihrem Auftreten entfernt liegen kann. Die Bindings mildern den ersten und zweiten Punkt, da die häufigste Reaktion, das Umschalten eines Bildschirms, einmal erklärt wird und danach ohne Zutun der Anwendung abläuft. Die in @sec:fazit beschriebenen Rückrufe zielen auf denselben Punkt.

K3 war in der gemessenen Fassung nicht erfüllt, weil nur das jüngste Ereignis je Objekt geliefert wurde. Der Abstand zwischen zwei Abfragen ist durch die Dauer eines Aufrufs nach unten begrenzt, und in dieser Zeit endete eine kurze Berührung, ohne dass die Anwendung davon erfuhr. Mit dem geleerten Puffer und dem gemeldeten Überlauf ist die Anforderung erfüllt. Offen bleibt, dass jeder Button einzeln abgefragt wird, sodass die Anzahl der Aufrufe mit der Anzahl der Bedienelemente wächst. @sec:fazit greift das auf.

Die Aussagekraft der Messung ist in drei Punkten begrenzt. Erstens wurde der Übertragungsaufwand anhand eines einzigen Aufrufs, nämlich `set_text`, auf einer festen Hardwarekombination gemessen, während Aufrufe mit größeren Ergebnissen die Round Trips anders auf Hin- und Rückweg verteilen. Zweitens stammen die Zeiten auf dem Server und auf dem Client aus getrennten Uhren und wurden rechnerisch zusammengesetzt, eine durchgehende Messung von der Berührung bis zum Bild liegt somit nicht vor. Drittens wurden die Berührungen von Hand ausgelöst, sodass die Erkennungszeit zusätzlich davon abhängt, wie der Finger aufsetzt.
