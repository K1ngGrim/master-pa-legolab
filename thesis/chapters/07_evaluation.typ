= Evaluation <sec:evaluation>

Dieses Kapitel bewertet die Referenzimplementierung anhand der drei in @sec:einleitung genannten Kriterien. Zunächst wird geprüft, ob sich eine interaktive Oberfläche über die entwickelte Abstraktion umsetzen lässt, bevor der Übertragungsaufwand je Aufruf und die Reaktionszeit auf eine Berührung gemessen werden. Daran schließen sich der Speicherbedarf, eine kurze Bewertung des Hardwareaufbaus sowie die Diskussion der Ergebnisse an.

Gemessen wird mit zwei eigenen Programmen. Das erste läuft auf dem Client und ruft `set_text` mit Texten wachsender Länge auf. Je Aufruf gibt es eine Zeile mit der Länge der Nutzlast, der Anzahl der Frames, der Anzahl der Round Trips, den Wiederholungen sowie den Zeiten für Senden, Warten und Abholen aus. Je Textlänge werden 20 Aufrufe gemessen. Der gesamten Reihe gehen drei Aufrufe zum Aufwärmen voraus. Das zweite Programm misst die Reaktion auf eine Berührung und wird dabei durch Zeitstempel auf dem Server ergänzt.

Angegeben ist jeweils der Median, da die Verteilungen durch feste Takte nicht symmetrisch sind. Beide Seiten laufen auf dem Logging-Level INFO, da die Ausgabe synchron über die serielle Verbindung erfolgt und andernfalls die Messung bestimmen würde. Vor jedem Lauf wird zudem der Server neu gestartet. Da Client und Server keine gemeinsame Zeitbasis besitzen, wird auf jedem Gerät für sich gemessen und erst in der Auswertung zusammengerechnet.

== Funktionaler Nachweis

Der funktionale Nachweis ergibt sich aus dem Beispielprogramm in @lst:beispielprogramm und aus den Messläufen. Das Beispielprogramm baut zwei Screens mit Labels und Buttons auf, verknüpft Buttons über Bindings mit einem Screenwechsel, schreibt fortlaufend einen Zähler und fragt die Zustände der Buttons ab. Damit sind alle Bestandteile des Objektmodells im Einsatz, also das Erzeugen von Objekten, das Ansprechen über Referenzen, das Ändern von Zuständen, lokale Reaktionen und der Rückfluss von Ereignissen.

Die Messläufe ergänzen das um die Dauer, denn in vier Läufen mit zusammen 640 Aufrufen trat keine einzige Wiederholung auf und kein Aufruf schlug fehl. Die Läufe sind voneinander getrennt, vor jedem wurde der Server neu gestartet. Die Zusicherung aus @sec:zuverlaessigkeit, dass jeder Aufruf ein Ergebnis oder eine Fehlermeldung hinterlässt, wurde in diesen Läufen somit nie in Anspruch genommen.

@tab:anforderungen ordnet die Kommunikationsanforderungen aus @sec:kommunikationsanforderungen dem erreichten Stand zu.

#figure(
  caption: [Erfüllung der Kommunikationsanforderungen],
  text(size: 9pt)[
    #table(
      columns: (auto, 1.2fr, 0.6fr, 1.6fr),
      align: left + top,
      table.header([*Nr.*], [*Anforderung*], [*Stand*], [*Begründung*]),
      [K1], [Strukturierte Nachrichten unbestimmter Länge], [erfüllt], [Nachrichten bis 3315 Byte, gemessen bis 164 Byte über 13 Frames],
      [K2], [Aufrufe mit zuordenbarem Ergebnis], [erfüllt], [das Ergebnis wird unter der Kennung des Aufrufs angefordert und unter dieser Kennung herausgegeben, siehe @lst:rückkanal],
      [K3], [Rückfluss von Ereignissen], [erfüllt], [der Puffer wird beim Abfragen geleert, siehe @sec:reaktionszeit, der Überlauf wird gemeldet, siehe @sec:testumgebung],
      [K4], [Antwortzeit unter 100 ms], [teilweise], [über ein Binding höchstens 59 ms, über den Client rund 1490 ms],
      [K5], [Begrenzter Speicherbedarf], [teilweise], [feste Obergrenzen für Nachrichtenlänge, Ergebnisse und Ereignisse, siehe @tab:rückkanal, auf dem Server nicht gemessen],
      [K6], [Unabhängigkeit vom Übertragungsweg], [teilweise], [zweiter Übertragungsweg in der Testumgebung, siehe @sec:testumgebung, für einen anderen Bus zwei Klassen aufzutrennen, siehe @tab:zuordnung, nachgeholt in @sec:trennung],
    )
  ],
) <tab:anforderungen>

K3 und K4 werden in @sec:reaktionszeit belegt und in @sec:diskussion eingeordnet.

== Nachweis durch die Testumgebung <sec:testumgebung>

Drei Eigenschaften lassen sich am laufenden Aufbau nur schwer zeigen, weil sie
eine zweite Verbindung, einen gezielt herbeigeführten Fehler oder einen
Überlauf voraussetzen. Für sie existiert eine Testumgebung, die unter CPython
läuft und dieselben Adapter, Stellvertreter und Interceptoren verwendet wie Steuer- und Anzeigeeinheit. Ersetzt sind nur die Hardware, die Anzeigebibliothek und die
beiden Laufzeitumgebungen.

*Unabhängigkeit vom Übertragungsweg (K6).* Die Testumgebung enthält eine
zweite Busanbindung, also eine zweite Umsetzung genau der einen Operation, die
die Interceptor-Schnittstelle aus @sec:interceptor nach unten verlangt. Sie
befördert einen Block nicht über den Bus, sondern übergibt ihn im selben
Prozess an die Gegenseite und liefert deren Antwort zurück. Oberhalb davon ist
nichts angepasst: derselbe Interceptor, dieselben Stellvertreter, dieselbe
Rahmung, derselbe Codec, dasselbe Objektmodell. Damit läuft der Entwurf
nachweislich über zwei verschiedene Übertragungswege. Was der Nachweis nicht
leistet, ist eine Aussage über einen zweiten realen Bus, denn die Testverbindung
verliert keine Blöcke und kennt keine Laufzeit. Hinzu kommt, dass die
Testverbindung die busspezifischen Klassen unverändert weiterverwendet. Für
einen anderen Bus wären sie nach @tab:zuordnung aufzutrennen, da sie neben der
Busanbindung auch den Aufrufteil der Kommunikationsschicht enthalten. K6 ist
deshalb nur teilweise erfüllt. Den Umbau, der das nachholt, beschreibt
@sec:trennung.

*Zuverlässigkeit.* Fehler, die im Betrieb selten auftreten, werden dort gezielt
erzeugt. Eine Betriebsart der Testverbindung liefert jede $n$-te Antwort als die vorangegangene und stellt damit genau die veralteten Antworten nach, die @sec:frame-struktur beschreibt. Im Stand `stand-projektarbeit` nutzt sie allerdings noch kein Test. Der Nachweis, dass der Aufruf trotz veralteter Antworten gelingt, dass Wiederholungen auftreten und dass ein wiederholter letzter Frame die Ausführung kein zweites Mal auslöst, liegt erst in einem späteren Stand vor, in dem das Ergebnis nach @sec:bestaetigung mit der Bestätigung zurückkommt. Eine zweite Betriebsart lässt jede
Übertragung scheitern und bildet den Verbindungsabbruch nach. Geprüft wird dort, dass der Aufruf mit einem Fehler endet und die Session endet, sodass jeder bestehende Stellvertreter ungültig wird. Auf dem realen Bus wurden Fehler dagegen nicht gezielt herbeigeführt. Belegt ist dort nur die eine veraltete Antwort aus @sec:reaktionszeit.

*Ereignisverlust (K3).* Der Überlauf des Ereignispuffers tritt in den Messungen
nicht auf, weil er mehr Berührungen zwischen zwei Abfragen verlangt, als von
Hand auszulösen sind. In der Testumgebung wird der Puffer über seine Grenze
hinaus gefüllt. Geprüft wird, dass der Verlust gemeldet und der Zähler mit der
Abfrage zurückgesetzt wird, dass also die von K3 in @sec:kommunikationsanforderungen
geforderte Erkennbarkeit auch im Grenzfall gilt.

Die Testumgebung deckt damit die Stellen ab, an denen die Messungen nichts
aussagen können, und die Messungen decken ab, was sich nur am echten Bus zeigt.
@tab:quelltext im Anhang nennt die Ordner, in denen beide liegen.

== Übertragungsaufwand <sec:uebertragungsaufwand>

Gemessen wird in vier Konfigurationen, die jeweils eine Größe verändern. Die Nutzlast je Frame beträgt 13 Byte im heutigen Stand und 7 Byte in der Vergleichsfassung, während als Serialisierung MessagePack @MessagePackItsJSON und die @json zum Einsatz kommen.

Die Vergleichsfassung ist nicht der alte Quelltext, sondern der heutige mit einer geänderten Konstante. Der frühere Header belegte neun Byte und ließ sieben für die Nutzlast, und genau diese sieben werden hier eingestellt. Gemessen wird damit nicht das alte Format, sondern dessen Kosten, denn nach @eq:blöcke hängt die Anzahl der Frames allein von der nutzbaren Nutzlast je Frame ab und nicht davon, wie der Header aufgebaut ist. Der Vergleich trennt somit die Wirkung der Rahmungsbreite von der Wirkung des Formats.

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

@tab:streuung fasst die vier Konfigurationen zusammen. Innerhalb einer Konfiguration und einer Textlänge ist die Anzahl der Round Trips über alle 20 Wiederholungen identisch, was aus @eq:blöcke folgt und durch die ausgebliebenen Wiederholungen bestätigt wird. Die Streuung liegt also allein in den Zeiten, nicht im Ablauf. Minimum und Maximum in @tab:streuung zeigen diese Streuung allerdings nicht, da sie über alle acht Textlängen gebildet sind und damit die Wirkung der Länge wiedergeben. Die Streuung je Round Trip beziffert der folgende Absatz.

#figure(
  caption: [Spanne der vier Konfigurationen über alle acht Textlängen, je 160 Aufrufe],
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

Der wichtigste Befund ergibt sich aus dem Vergleich mit den gemessenen Zeiten. Ein Round Trip kostet in jeder der vier Konfigurationen und bei jeder der acht gemessenen Nachrichtenlängen 114,2 ms. Über alle 640 Aufrufe liegen das untere und das obere Quartil bei 114,1 ms und 114,2 ms, das Minimum bei 114,0 ms und die Standardabweichung bei 0,3 ms. Nur 20 der 640 Aufrufe liegen über 115 ms, der höchste bei 117,0 ms. Die Dauer eines Aufrufs ist somit das Produkt aus der Anzahl der Round Trips und einer festen Zeit je Round Trip, da sich weder die Länge der Nutzlast noch die Wahl des Formats darüber hinaus auswirken. Jeder Wert aus @abb:roundtrips lässt sich deshalb unmittelbar in eine Dauer umrechnen, sodass der kürzeste gemessene Aufruf mit 4 Round Trips 457 ms benötigt und der längste mit 27 Round Trips im Median 3082 ms.

Die Anzahl der Round Trips folgt unmittelbar aus @eq:blöcke. Sie setzt sich zusammen aus einem Round Trip je Frame der Nachricht, einer Anfrage `READY` und einem Round Trip je Frame des Ergebnisses. Für die gemessenen Aufrufe sind das $N + 2$ Round Trips, solange das Ergebnis in einen Frame passt. Das trifft auf drei der vier Konfigurationen zu, denn das Ergebnis belegt mit MessagePack vier und mit @json als `{"d": null}` elf Byte. Nur bei @json mit sieben Byte Nutzlast benötigt es zwei Frames, sodass dort $N + 3$ Round Trips anfallen.

Die beiden Einflussgrößen lassen sich daran trennen. Gegenüber dem heutigen Stand mit 13 Byte und MessagePack braucht die Fassung mit 7 Byte das 1,59-fache an Round Trips, die Fassung mit @json das 1,21-fache und beides zusammen das 2,09-fache. Die Rahmung wiegt also deutlich schwerer als das Format. Der Grund ist in den Daten sichtbar. @json erzeugt bei denselben Aufrufen eine um 22 bis 23 Byte längere Nutzlast, was nach @eq:blöcke nicht bei jeder Textlänge eine Blockgrenze überschreitet. Ein kleinerer Header verschiebt dagegen alle Blockgrenzen zugleich. Die Erwartung aus @sec:kosten wird damit für diesen Aufruf bestätigt. Allgemein gilt das nicht, denn der Mehraufwand von @json besteht hier fast nur aus Schlüsseln und Klammern und ist deshalb nahezu fest. Bei Aufrufen mit vielen Argumenten oder Listen wächst er mit der Nachricht, und das Format gewönne an Gewicht.

Eine Grundlinie für diese Zahlen liefert PUPRemote selbst. Ein eigenes Kommando je Operation, etwa `set_text` mit fester Formatangabe für ein vorab festgelegtes Label, kommt mit einem einzigen Round Trip aus, also mit 114 ms statt der 457 ms des kürzesten gemessenen Aufrufs. Der Text ist dann aber auf die 16 Byte eines Modus begrenzt, jede Operation belegt einen der höchstens 16 Modi, und Objekte, die erst zur Laufzeit entstehen, lassen sich nicht ansprechen. Die drei zusätzlichen Round Trips sind damit der Preis der Allgemeinheit, die K1 und das Objektmodell verlangen. Mit dem Ergebnis in der Bestätigung nach @sec:bestaetigung schrumpft er auf einen. Gemessen wurde die Grundlinie nicht, sie folgt aus der Dauer eines Round Trips.

Die Nutzlasteffizienz nach @eq:effizienz fällt dabei niedrig aus. Ein Aufruf mit 21 Byte Nutzlast belegt zwei Frames und somit 32 übertragene Byte, was einem Wert von 0,66 entspricht. Bei 142 Byte über elf Frames ergeben sich 0,807 und damit nahezu der theoretische Höchstwert, den ein Header von drei Byte zulässt, nämlich $13 slash 16 = 0,8125$ bei vollständig gefülltem letztem Frame. Für die Dauer eines Aufrufs bleibt gleichwohl die Anzahl der Frames maßgeblich und nicht ihre Füllung.

Unabhängig von der Nachrichtenlänge kostet jeder Aufruf zwei zusätzliche Round Trips für das Abholen des Ergebnisses und somit 228 ms, was beim kürzesten Aufruf bereits die Hälfte der gesamten Dauer ausmacht. Auffällig ist zudem, dass das Abfrageintervall von 50 ms nie zum Tragen kommt, da die gemessene Wartezeit in 595 der 640 Aufrufe genau 114 ms und im Höchstfall 129 ms beträgt, also stets einen einzigen Round Trip. Der Server ist folglich mit der Ausführung fertig, bevor der Client zum ersten Mal nachfragt.

== Reaktionszeit einer Berührung <sec:reaktionszeit>

Die zweite Messung betrachtet den Weg von einer Berührung bis zur sichtbaren Reaktion und vergleicht dabei die beiden Wege aus @sec:ansteuerung. Über ein Binding führt der Server die Reaktion selbst aus, während über den Client das Ereignis abgefragt und mit einem zweiten Aufruf beantwortet wird. Auf dem Server werden dafür drei Zeitpunkte je Berührung festgehalten, nämlich die erste erkannte Berührung, das verarbeitete Ereignis und das abgeschlossene Neuzeichnen, auf dem Client hingegen die Zeit vom Beginn eines Abfragedurchlaufs bis zum Ende der Reaktion.

Der Touchcontroller wird von der Anzeigebibliothek alle 40 ms abgefragt, gemessen über 39 Berührungen mit Werten zwischen 38 und 42 ms. Eine Berührung wird deshalb im Mittel nach 20 ms und spätestens nach 42 ms bemerkt. Das gilt, solange die Ereignisschleife frei ist. Bearbeitet sie gerade einen Aufruf, verlängert sich der Abstand zwischen zwei Abfragen, in den Läufen über den Client bei 13 von 62 Berührungen auf 57 bis 89 ms. Für den Weg über den Client ist die Erkennung in @tab:reaktion deshalb eher zu knapp angesetzt, an der Größenordnung ändert das nichts. Von dort bis zum verarbeiteten Ereignis vergehen 4 ms. Das Neuzeichnen dauert anschließend 6 ms, wenn ein Binding die Anzeige verändert hat, und 7 ms, wenn die Änderung von einem Aufruf des Clients stammt. Über ein Binding ist die Reaktion gemessen 13 ms nach der erkannten Berührung sichtbar, im Bereich von 10 bis 17 ms. Zusammen mit der Erkennung ergibt das im Mittel 33 ms und im ungünstigsten Fall 59 ms.

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
    [Summe im ungünstigsten Fall], [59 ms], [rund 1800 ms], [berechnet],
  ),
) <tab:reaktion>

Die Spalte Herkunft unterscheidet, ob ein Wert unmittelbar gemessen, aus einer Messung abgeleitet oder aus den übrigen Zeilen berechnet wurde. Die gemessenen Werte sind Mediane. Die Verarbeitung des Ereignisses streut über 39 Berührungen von 4 bis 7 ms, das Neuzeichnen von 5 bis 11 ms über ein Binding und von 7 bis 8 ms über den Client. Die beiden Zeilen addieren sich nicht zu den Summen darunter, denn Mediane sind nicht additiv. Maßgeblich ist die je Berührung gemessene Zeit von der Erkennung bis zum fertigen Bild, deren Median bei 13 ms liegt und die zwischen 10 und 17 ms streut. Die Summen beruhen auf diesem Wert und nicht auf der Addition der Einzelmediane. Die Reaktion über den Client liegt in allen drei Läufen bei 1160 bis 1177 ms, mit einem einzelnen Ausreißer von 1277 ms, der weiter unten erklärt wird. Abgeleitet sind die beiden Wartezeiten: die Erkennung ist der halbe Abtasttakt, das Warten auf die nächste Abfrage die halbe Summe aus Aufrufdauer und eingestellter Pause. Berechnet sind die Summen, die sich aus den Zeilen darüber ergeben.

Die Werte in @tab:reaktion gelten für eine Pause von 20 ms in der Schleife der Anwendung. Gemessen wurde zusätzlich mit 0 ms und 1000 ms, wobei die Reaktion selbst in allen drei Fällen gleich lang ausfällt, da die Pause vor der Abfrage liegt. Bei einer Pause von 1000 ms steigt die Summe im Mittel auf rund 1980 ms, weil sich der Abstand zwischen zwei Abfragen entsprechend verlängert.

Dieser Abstand bestimmt zugleich, welche Berührungen überhaupt ankommen. In einer früheren Fassung lieferte eine Abfrage nur das jüngste Ereignis eines Objekts. Wurde ein Button gedrückt und wieder losgelassen, bevor die nächste Abfrage stattfand, stand im Puffer zuletzt das Loslassen, und die Berührung war vollständig verloren. Erkannt wurde sie nur, wenn sie zum Zeitpunkt der Abfrage noch andauerte, was bei einer Pause von 1000 ms rechnerisch ein Halten von etwa 1,5 Sekunden erforderte, nämlich eine Abfrage von 457 ms zuzüglich der Pause.

Diese Beobachtung war der Anlass für die in @sec:ansteuerung beschriebene Trennung von Zustand und aufgelaufenen Ereignissen. Um sie zu prüfen, wurde die Messung wiederholt. Das Messprogramm auf dem Client zählt dabei nicht die Betätigungen, sondern läuft, bis zwanzig Abfragen eine Berührung melden. Wie oft der Button tatsächlich betätigt wurde, hält unabhängig davon die Anzeigeeinheit fest, die je erkannter Berührung eine Zeile ausgibt. Beide Zählungen lassen sich damit gegeneinander prüfen. @tab:ereignisse stellt die Ergebnisse zusammen.

#figure(
  caption: [Erkannte Berührungen je Variante, gezählt auf beiden Geräten],
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right),
    table.header([*Pause*], [*Abfragen mit Treffer*], [*Berührungen laut Server*], [*gezählte Betätigungen*], [*verloren*], [*Wiederholungen*]),
    [0 ms],    [20], [20], [20], [0], [0],
    [20 ms],   [20], [22], [22], [0], [1],
    [1000 ms], [20], [20], [20], [0], [0],
  ),
) <tab:ereignisse>

In allen drei Läufen stimmt die Anzahl der auf dem Client gezählten Betätigungen mit der Anzahl der Berührungen überein, die die Anzeigeeinheit verzeichnet hat. Kein Ereignis ging also verloren, und zwar unabhängig von der Pause in der Schleife. Im Lauf mit 20 ms Pause wurde der Button 22-mal betätigt, gemeldet wurde das in nur 20 Abfragen, weil zweimal zwei Betätigungen in dasselbe Abfrageintervall fielen und die zugehörige Antwort beide mitführte. Genau das war in der früheren Fassung nicht möglich. Anforderung K3 ist damit erfüllt, und das Halten eines Buttons ist nicht mehr nötig.

Der Nachweis gilt für die gemessene Ereignisrate von Hand ausgelöster Betätigungen. Dass der Puffer auch bei höherer Rate meldet, was er verwirft, zeigt nicht diese Messung, sondern der Überlauftest in @sec:testumgebung.

Bezahlt wird das mit einem zusätzlichen Round Trip je Abfrage. Die Antwort trägt nun den Zustand, die Anzahl der Betätigungen und die Anzahl der verworfenen Ereignisse, passt damit nicht mehr in einen einzigen Frame und benötigt zwei Frames für den Rückweg. Eine Abfrage kostet dadurch 5 statt 4 Round Trips, also 572 ms statt 457 ms. Um denselben Round Trip verlängert sich die Reaktion über den Client, da sie mit der Abfrage beginnt.

Die Wiederholung im Lauf mit 20 ms Pause ist der einzige Fall einer veralteten Antwort in allen Messungen mit 100 ms Wartezeit. Sie kostete einen Round Trip, die betroffene Reaktion dauerte 1277 ms statt 1161 ms. Der Mechanismus aus @sec:zuverlaessigkeit greift damit auch im Betrieb und nicht nur im Entwurf.

== Ressourcenverbrauch

Gemessen wird auf dem Hub mit `gc.mem_alloc()`, also dem vom Speicherverwalter belegten Speicher, jeweils nach einer Speicherbereinigung mit `gc.collect()`. Der erste Messpunkt liegt nach dem Aufbau der Oberfläche aus einem Screen und einem Label und nach drei Aufrufen zum Aufwärmen, der zweite nach den 160 gemessenen Aufrufen. Vor der Messreihe sind 16128 Byte belegt, danach 16272 Byte, und die Werte sind in allen vier Läufen gleich. Darin enthalten ist der geladene Programmcode, dessen gebündelter Quelltext im Messprogramm rund 72 KB umfasst. Die 160 Aufrufe hinterlassen damit 144 Byte, also weniger als ein Byte je Aufruf. Da der Speicherverwalter in Blöcken von mindestens 16 Byte zuteilt, bleibt je Aufruf kein Objekt dauerhaft zurück. Was die Messung nicht erfasst, ist die Spitze während eines Aufrufs, denn die Bereinigung vor jedem Messpunkt gibt den kurzzeitig belegten Speicher wieder frei. Ebenso fehlt ein Messpunkt vor dem Aufbau, sodass sich der Bedarf der Oberfläche selbst nicht beziffern lässt.

Der Speicherbedarf auf dem Server wurde dagegen nicht gemessen. Das ist die empfindlichste Lücke dieser Auswertung, denn der Heap des Servers war nach @sec:nebenlaeufigkeit die Ursache dafür, dass sich Aufrufe nicht in eigenen Threads ausführen lassen. Eine belastbare Aussage müsste den freien Heap an vier Stellen vergleichen, nämlich vor dem Laden der Anzeigebibliothek, nach deren Initialisierung, nach dem Aufbau der Oberfläche und nach einer längeren Folge von Aufrufen. Ohne diese Messung bleibt K5 auf der Seite, auf der der Speicher knapp ist, unbelegt.

== Bewertung des Hardwareaufbaus

Die Adapterplatine ist ein Zwischenschritt weg vom Steckbrett, auf dem der Aufbau in einer ersten Vorführung noch beruhte. Da sich Display und Mikrocontroller aufstecken lassen, beschränkt sich die Hardware auf das Nötigste, nämlich auf die Verbindung beider Baugruppen. Die Platine führt alle benötigten Leitungen auf Buchsenleisten, die sich ohne besondere Ausrüstung löten lassen. Dadurch lassen sich weitere Exemplare zügig aufbauen, und die aufgesteckten Baugruppen bleiben für andere Zwecke verwendbar. Die Anforderungen D1, D2, S1 und S3 aus @sec:d_s_anforderungen erfüllt der Aufbau damit, wie @sec:hardwareaufbau zeigt. Für D3 und S2 liegt nur die Beobachtung vor, dass die Anzeigebibliothek auf dem ESP32 läuft. Energieaufnahme und Speicherbedarf wurden nicht gemessen.

Steckverbindungen sind allerdings keine gute Wahl für die Signalintegrität und zählen im Betrieb zu den häufigsten Fehlerquellen. Für einen Aufbau, der im Labor erprobt und zwischen Versuchen umgesteckt wird, ist das vertretbar, für einen dauerhaften Einsatz dagegen nicht. @abb:platine zeigt beide Seiten der Platine als dreidimensionale Darstellung aus dem Entwurfswerkzeug. Neben den Buchsenleisten sind dort die Versionsnummer der Platine sowie die Bezeichnungen der Bauteile aufgedruckt, was die Bestückung und die spätere Zuordnung erleichtert.

#figure(
   image("../figures/3d_render.png"),
   caption: [Vorderseite (rechts) und Rückseite (links) der Adapterplatine als 3D-Rendering],
 ) <abb:platine>

== Diskussion der Ergebnisse <sec:diskussion>

Die Messungen bestätigen die Annahme, auf der der gesamte Entwurf beruht, denn für die Dauer eines Aufrufs zählt die Anzahl der Übertragungen und nicht die übertragene Datenmenge. Jede eingesparte Übertragung spart 114 ms, unabhängig davon, wie viele Byte sie transportiert hätte. Der Wechsel von der früheren Rahmung und @json auf den heutigen Stand halbiert somit die Dauer eines Aufrufs.

Erklärungsbedürftig sind die 114 ms selbst, denn bei 115200 Baud dauert die Übertragung eines Blocks von 16 Byte deutlich weniger als eine Millisekunde. Die Zeit entsteht folglich nicht auf der Leitung. Wo sie entsteht, lässt sich an den beteiligten Schichten weiter eingrenzen, auch ohne eine Messung innerhalb der Busanbindung.

Auf der Anzeigeeinheit scheidet sie weitgehend aus. Die Transportbibliothek empfiehlt, ihre Verarbeitung wenigstens alle 20 ms aufzurufen @PUPRemoteDocumentationAntons, tatsächlich geschieht das etwa jede Millisekunde. Im laufenden Betrieb wartet die Bibliothek höchstens eine Millisekunde, nämlich beim zweiten Versuch, ein Byte zu lesen. Alle längeren Wartezeiten ihres Quelltextes fallen nur beim Verbindungsaufbau an, und die Überwachung der Verbindung greift erst nach einer Sekunde Untätigkeit.

Ein Moduswechsel scheidet ebenfalls aus. Ein Round Trip besteht aus einem Schreiben und einem Lesen desselben Modus, denn die Middleware registriert nach @sec:busanbindung genau ein Kommando, sodass der Bus den Modus zwischen zwei Aufrufen nicht wechseln muss.

Damit bleibt die Busanbindung auf der Steuereinheit, und dort liegt der größte Teil der Zeit. Die Bibliothek wartet nach dem Schreiben eine feste Zeit, bevor sie liest. Diese Wartezeit wurde während der Entwicklung von 0 auf 100 ms angehoben. Sie greift immer dann, wenn ein Kommando eine Nutzlast vom Hub zur Gegenseite führt. Da die Middleware nach @sec:busanbindung ein einziges Kommando mit Nutzlast in beide Richtungen registriert und keinen eigenen Wert übergibt, wird diese Wartezeit bei jedem Austausch ausgeführt, auch bei den Anfragen des Rückkanals.

Nachgewiesen wird das durch eine eigene Messreihe, in der die Wartezeit ausdrücklich übergeben und schrittweise verkleinert wird. Gemessen werden dieselben acht Textlängen wie zuvor, je Wartezeit 160 Aufrufe. Über die drei vollständigen Läufe ergibt eine Ausgleichsgerade durch alle 480 Aufrufe

$ t_"RT" = 14,39 "ms" + 0,9993 dot t_"wait" $ <eq:wartezeit>

bei einer größten Abweichung vom Modell von 2,4 ms. Eine Steigung von eins bedeutet, dass jede Millisekunde Wartezeit unverändert in der Dauer eines Round Trips landet. Von den 114,2 ms sind damit 100 ms die angehobene Wartezeit, und die verbleibenden 14,4 ms entfallen auf das Schreiben, das Lesen und die Verarbeitung auf beiden Seiten. Dieser Rest lässt sich ohne eine Messung innerhalb der Firmware nicht weiter aufteilen.

Die Messreihe entstand auf einem späteren Stand, bei dem das Ergebnis nach @sec:bestaetigung mit der Bestätigung zurückkommt. Für diese Aussage ist das ohne Belang, weil die Ausgleichsgerade die Dauer je Round Trip betrachtet und nicht deren Anzahl. Die Busanbindung selbst ist in beiden Ständen dieselbe.

Erklärt ist damit auch die geringe Streuung, denn ein Block ist unabhängig von der Nutzlast stets 16 Byte lang, und ebenso, warum das Abfrageintervall von 50 ms nie zum Tragen kommt, da der Server nach 100 ms Wartezeit längst fertig ist.

Ohne Wartezeit liest der Client, bevor die Gegenseite den Frame verarbeitet hat, und erhält die vorherige Antwort. Genau diesen Fall behandelt die Transportschicht nach @sec:zuverlaessigkeit bereits, indem sie ihn erkennt und den Frame wiederholt. Die Wartezeit schützt also vor einem Fehler, den der Entwurf in Grenzen selbst abfängt, und kostet dafür 100 ms je Übertragung. Was eine kürzere Wartezeit tatsächlich einbringt und wo sie an ihre Grenze stößt, zeigt @sec:wartezeit.

Für K4 ergibt sich ein zweigeteiltes Bild, denn über ein Binding liegt die Reaktion mit höchstens 59 ms sicher innerhalb der geforderten 100 ms, über den Client dagegen im gemessenen Stand rund fünfzehnmal so lange und nach der Rechnung in @sec:wartezeit auch mit kürzerer Wartezeit noch etwa dreieinhalbmal so lange. Die lokalen Bindings sind somit nicht nur eine Abkürzung, sondern unter den in dieser Arbeit umgesetzten Mechanismen der einzige Weg, eine Reaktion in der geforderten Zeit anzuzeigen. Dass ihr Satz an Aktionen klein ist, begrenzt zugleich, welche Reaktionen in dieser Zeit überhaupt möglich sind.

Die Einleitung motiviert die Arbeit mit der Vermittlung von Technikkenntnissen an Kinder und Jugendliche. Ob die entstandene Schnittstelle dafür handhabbar ist, wurde nicht untersucht, dazu wäre eine Erprobung mit Lernenden nötig. Am Beispielprogramm in @lst:beispielprogramm lässt sich immerhin ablesen, was sie voraussetzt. Das Erzeugen und Verändern von Elementen sieht aus wie gewöhnliche Python-Programmierung, und nichts davon verlangt Kenntnis des Protokolls. Drei Stellen treten dennoch nach außen. Erstens blockiert jeder Aufruf, sodass eine Schleife mit Wartezeit nötig ist und die Anzeige nicht nebenbei bedient werden kann. Zweitens müssen Schaltflächen abgefragt werden, was eine Schleife erzwingt, statt auf ein Ereignis zu warten. Drittens werden Stellvertreter nach `clear()` ungültig, was zu einer Ausnahme führt, deren Ursache zeitlich weit von ihrem Auftreten entfernt liegen kann. Die Bindings mildern den ersten und zweiten Punkt, da die häufigste Reaktion, das Umschalten eines Bildschirms, einmal erklärt wird und danach ohne Zutun der Anwendung abläuft. Die in @sec:rueckkanal-ereignisse beschriebenen Rückrufe zielen auf denselben Punkt.

Die ursprüngliche Fassung erfüllte K3 nicht, weil sie nur das jüngste Ereignis je Objekt lieferte. Der Abstand zwischen zwei Abfragen ist durch die Dauer eines Aufrufs nach unten begrenzt, und in dieser Zeit endete eine kurze Berührung, ohne dass die Anwendung davon erfuhr. Mit dem geleerten Puffer und dem gemeldeten Überlauf ist die Anforderung erfüllt. Offen bleibt, dass jeder Button einzeln abgefragt wird, sodass die Anzahl der Aufrufe mit der Anzahl der Bedienelemente wächst. @sec:rueckkanal-ereignisse greift das auf.

Die Aussagekraft der Messung ist in drei Punkten begrenzt. Erstens wurde der Übertragungsaufwand anhand eines einzigen Aufrufs, nämlich `set_text`, auf einer festen Hardwarekombination gemessen, während Aufrufe mit größeren Ergebnissen die Round Trips anders auf Hin- und Rückweg verteilen. Zweitens stammen die Zeiten auf dem Server und auf dem Client aus getrennten Uhren und wurden rechnerisch zusammengesetzt, eine durchgehende Messung von der Berührung bis zum Bild liegt somit nicht vor. Drittens wurden die Berührungen von Hand ausgelöst, sodass die Erkennungszeit zusätzlich davon abhängt, wie der Finger aufsetzt.
