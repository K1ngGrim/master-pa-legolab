#import "../template/template.typ": pg
= Entwurf von Transport- und Kommunikationsschicht <sec:entwurf>

Dieses Kapitel beschreibt den Entwurf der Transport- und der Kommunikationsschicht. Die beiden Schichten bilden die Grundlage für eine zuverlässige und effiziente Kommunikation zwischen der Anwendung und dem darunterliegenden Übertragungsweg.

Die Transportschicht, im @osi\-Modell als Transport Layer bezeichnet, ist für die Zerlegung von Nachrichten beliebiger Länge in kleinere Pakete und deren korrekte Rekonstruktion auf der Empfängerseite verantwortlich. Dort stellt sie außerdem Funktionen wie Stauvermeidung (engl. congestion avoidance) und die Sicherstellung einer fehlerfreien Übertragung bereit @tanenbaumComputernetzwerke2012.

Die Kommunikationsschicht setzt auf der Transportschicht auf und bildet die Schnittstelle zwischen der Anwendung und dem Transport. Sie kapselt die Details der Verbindung und stellt der Anwendung ein einfaches Kommunikationsmodell bereit. Im @osi\-Modell entspricht sie am ehesten dem Session Layer, der für die Verwaltung von Kommunikationssitzungen und die Zuordnung von Anfragen und Antworten zuständig ist.

== Motivation und Randbedingungen

Um die Entscheidungen in beiden Schichten nachvollziehen zu können, werden zunächst Motivation und Randbedingungen zusammengefasst. Aus den vorherigen Kapiteln geht hervor, dass die Transportschicht Nachrichten zuverlässig und effizient übertragen muss, unabhängig vom zugrunde liegenden Übertragungsweg. Dazu gehört auch die Serialisierung der Nutzlast, die in der Referenzimplementierung als Codec umgesetzt ist. Die Kommunikationsschicht muss dafür sorgen, dass Anfragen und Antworten zuverlässig zugeordnet werden, und sie stellt die Aufrufstransparenz her.

Die Zuordnung zum @osi\-Modell ist dabei bewusst nicht streng. Rahmung und Übertragungswiederholung gehören dort zur Sicherungsschicht, und der betrachtete Bus deckt diese Schicht auch ab, allerdings nur für einzelne Blöcke und ohne jeden Bezug zu einer Nachricht. Da die Blockgröße nicht veränderbar ist und der Bus keine Kennung je Nachricht kennt, müssen Rahmung und Wiederholung oberhalb davon erneut stattfinden, diesmal bezogen auf eine vollständige Nachricht. Ebenso wird die Serialisierung hier der Transportschicht zugeordnet und nicht der darüberliegenden Aufrufschicht, wie es bei klassischen @rpc\-Rahmenwerken üblich ist. Der Grund liegt in @sec:nutzlastlaenge: Erst das Längenfeld der Rahmung erlaubt ein binäres Format, und damit hängt die Wahl des Formats unmittelbar an der Rahmung. Beide Zuordnungen folgen also der Aufgabe und nicht dem Modell.

== Transportschicht

Wie bereits beschrieben, zerlegt die Transportschicht Nachrichten beliebiger Länge in Pakete fester Größe und setzt sie auf der Empfängerseite wieder zusammen. Ein solches Paket wird in diesem Kapitel als Block bezeichnet, sobald es um die Schnittstelle zum Übertragungsweg geht, und als Frame, sobald es die Steuerinformationen der Transportschicht trägt. Dazu muss jedes Paket Steuerinformationen tragen, wie es auch bei bekannten Protokollen wie @tcp oder @udp der Fall ist.

Im Folgenden wird beschrieben, welchen Übertragungsweg die Schicht nach unten voraussetzt, wobei lediglich gefordert ist, dass er Blöcke begrenzter Größe befördert. Welche @osi\-Schichten dieser Weg abdeckt, ist für den Entwurf ohne Belang und je nach System verschieden, beim hier betrachteten Bus sind es Bitübertragung und Sicherung. Anschließend werden die benötigten Steuerinformationen beschrieben, ohne feste Größen und Formate vorzugeben, damit der Entwurf auf andere Systeme übertragbar bleibt. Die konkrete Umsetzung zeigt @sec:umsetzung-transport.

In verteilten Systemen durchläuft eine Nachricht den Schichtenstapel zweimal, auf der Senderseite abwärts und auf der Empfängerseite aufwärts. Jede Schicht fügt auf dem Weg nach unten eigene Steuerinformationen hinzu, die auf dem Weg nach oben wieder ausgewertet und entfernt werden. Die folgenden Abschnitte betrachten deshalb stets beide Richtungen. Dieses Prinzip wird im Allgemeinen als Kapselung und Entkapselung bezeichnet @HowEncapsulationWorks.

=== Interceptor-Abstraktion <sec:interceptor>

Die Transportschicht setzt nach unten einen Übertragungsweg voraus. Damit die Anforderungen aus @sec:kommunikationsanforderungen erfüllt werden können, darf sie über diesen Weg möglichst wenig wissen. Jede Eigenschaft, die sie voraussetzt, schließt Übertragungswege aus, die diese Eigenschaft nicht bieten. Die Schnittstelle richtet sich deshalb danach, was die betrachtete Verbindungsklasse mindestens leisten muss, und nicht nach den Fähigkeiten eines bestimmten Busses.

Da nur der Client die Übertragung anstoßen kann, lässt sich jede Interaktion auf denselben Ablauf zurückführen:

#figure(
  image("../figures/interceptor_ablauf.png", width: 85%),
  caption: [Ablauf eines Aufrufs an der Interceptor-Schnittstelle. Jede der drei
  Phasen besteht aus Wiederholungen derselben Operation, und jede wird vom
  Client angestoßen.],
) <abb:interceptor>

Die Schnittstelle bietet daher eine einzige Operation. Ein Block begrenzter Größe wird übergeben, und im selben Vorgang kommt ein Block zurück. Ob dieser Block Nutzlast, eine Bestätigung oder eine Anfrage nach dem Ergebnis enthält, spielt für die Schnittstelle keine Rolle, da sie ihn nur befördert und nicht liest. Die drei Phasen in @abb:interceptor unterscheiden sich also nur im Inhalt der Blöcke.

Eine umfangreichere Schnittstelle wäre denkbar, würde aber Übertragungswege ausschließen. Eine Zustellung ohne vorherige Anfrage setzt voraus, dass der Server von sich aus senden kann. Ein Warten auf eine Meldung des Servers setzt zusätzlich voraus, dass er dies zu einem selbst gewählten Zeitpunkt tut. Beides leistet der hier betrachtete Bus nicht, und beides ist auch für die übrigen Vertreter der in @sec:verallgemeinerung beschriebenen Klasse nicht vorauszusetzen. Die Schnittstelle bildet daher die Schnittmenge dessen, was alle Übertragungswege dieser Klasse leisten können.

Beide Seiten erfüllen dieselbe Schnittstelle und unterscheiden sich allein in der Richtung, aus der ein Block eintrifft. Der Client übergibt Blöcke und erhält Antworten, der Server nimmt Blöcke entgegen und beantwortet sie. Die Schnittstelle ist also symmetrisch, und eine Änderung des Übertragungswegs betrifft genau eine Stelle pro Seite.

Den Inhalt der Blöcke wertet die Schnittstelle nicht aus, denn sie kennt weder die Zugehörigkeit eines Blocks zu einer Nachricht noch seine Position darin, setzt nichts zusammen, erkennt keine Wiederholungen und ordnet keine Antworten zu. Alles, was eine Struktur voraussetzt, liegt darüber und wird in den folgenden Abschnitten beschrieben. Die Interceptor-Schnittstelle erfüllt damit die Anforderung K6 aus @sec:kommunikationsanforderungen.

=== Frame-Struktur <sec:frame-struktur>

Für die Schnittstelle aus dem vorherigen Abschnitt genügt ein Block ohne weitere Struktur. Die Transportschicht gibt den Blöcken eine Struktur, um aus einer Folge unabhängiger Blöcke eine Nachricht beliebiger Länge zu machen. Dazu benötigt jeder Block neben der Nutzlast Steuerinformationen, die unter anderem die Zugehörigkeit zu einer Nachricht und die Position innerhalb der Nachricht beschreiben. Diese Steuerinformationen werden in einem Header zusammengefasst, der jedem Block vorangestellt wird. Ein Block mit dieser Struktur wird im Folgenden als Frame bezeichnet.

Die folgenden Felder sind für die Rahmung eines Frames notwendig. Größe und Format der Felder werden dabei bewusst nicht vorgegeben, damit der Entwurf auf andere Systeme übertragbar bleibt. Eine konkrete Ausprägung zeigt @sec:umsetzung-transport. @sec:evaluation vergleicht sie mit einer früheren Fassung, die dieselbe Aufgabe mit deutlich mehr Steuerinformationen löste.

*Zugehörigkeit:* Ohne Kennung der Nachricht lässt sich nicht entscheiden, ob ein eintreffender Block zu einer laufenden Übertragung gehört. Das ist auch bei einem rein synchronen Austausch nötig, bei dem immer nur eine Nachricht gleichzeitig unterwegs ist. Da direkt nach dem Absetzen einer Anfrage gelesen wird, hat die Gegenseite diese unter Umständen noch nicht verarbeitet. Gelesen wird dann die Antwort auf die vorangegangene Anfrage. Erst die Kennung macht solche veralteten Antworten erkennbar.

*Position:* Die Blöcke müssen in der richtigen Reihenfolge zusammengesetzt werden. Dazu muss die Position jedes Blocks innerhalb der Nachricht bekannt sein. Über die Position lassen sich außerdem Wiederholungen erkennen und verwerfen, die durch Übertragungsfehler oder Paketverlust entstehen.

*Art:* Über denselben Kanal werden sowohl Nutzlast als auch Steuerinformationen wie Bestätigungen, Anfragen nach dem Ergebnis und Fehlermeldungen übertragen. Da die Schnittstelle selbst nicht zwischen diesen Arten unterscheidet, muss der Header die Art des Blocks angeben.

*Länge der Nutzlast:* Der Übertragungsweg liefert Blöcke fester Größe, unabhängig davon, wie viel davon tatsächlich genutzt wird. Ohne ausdrückliche Angabe der Länge muss sie aus dem Inhalt abgeleitet werden. Warum das die Schicht an bestimmte Formate bindet, behandelt der nächste Abschnitt. 

*Ende der Nachricht:* Der Empfänger kennt die Gesamtlänge der Nachricht nicht vorab. Daher muss das Ende der Nachricht explizit markiert werden, um zu erkennen, wann die Übertragung abgeschlossen ist. Man könnte das Ende daraus ableiten, dass der letzte Block nicht vollständig gefüllt ist. Ist die Nachrichtenlänge aber ein exaktes Vielfaches der Nutzlastgröße, ist auch der letzte Block voll und wird nicht als Ende erkannt. Der Empfänger würde dann auf einen Block warten, der nie kommt.

=== Nutzlastlänge und Formatunabhängigkeit <sec:nutzlastlaenge>

Neben den Steuerinformationen trägt ein Block die Nutzlast. Der Übertragungsweg liefert Blöcke fester Größe, die Länge der Nutzlast in einem Block ist aber nicht immer gleich. Eine fehlende Längenangabe ist unproblematisch, solange sich das Ende der Nutzlast aus ihrem Format ergibt. Bei textbasierten Formaten wie @json oder @xml ist das der Fall. Sie enthalten keine Nullbytes, sodass Füllbytes am Ende eines Blocks eindeutig erkannt und entfernt werden können. Binäre Formate wie @cbor oder das in der Referenzimplementierung verwendete MessagePack besitzen diese Eigenschaft nicht.

Ohne Längenfeld ist die Transportschicht also an textbasierte Formate gebunden. Ein Wechsel des Formats oder die freie Wahl des Formats durch die Entwickler ist dann nicht möglich. Formatunabhängigkeit ist dabei keine ungewöhnliche Anforderung. Protokolle wie @http erlauben es beispielsweise, den Inhaltstyp der Nutzlast anzugeben, um verschiedene Formate zu unterstützen @RFC9110HTTP.

Um Formatunabhängigkeit zu erreichen, muss die Länge der Nutzlast
ausdrücklich angegeben werden. Dazu nimmt der Header ein Längenfeld auf, das angibt, wie viele Bytes des Blocks tatsächlich zur Nutzlast gehören.

Die Breite dieses Feldes folgt aus der Blockgröße. Bezeichnet $"MTU"$ die Größe eines Blocks und $H$ die Größe des Headers, jeweils in Byte, so verbleibt als Nutzlast

$ P = "MTU" - H $ <eq:payload>

Die @mtu ist dabei die maximale Größe eines Blocks, die der Übertragungsweg befördern kann. Das Längenfeld muss jeden Wert von $0$ bis $P$ ausdrücken können. Seine Breite $b$ in Bit beträgt damit

$ b = ceil(log_2 (P + 1)) $ <eq:laengenfeld>

Da das Längenfeld selbst Teil des Headers ist, hängen @eq:payload und
@eq:laengenfeld voneinander ab: $H$ bestimmt $P$, $P$ bestimmt $b$, und $b$ geht wieder in $H$ ein. Aufgelöst wird das, indem der kleinste Header gewählt wird, für den beide Gleichungen zugleich gelten. @sec:umsetzung-transport führt diese Rechnung für die konkrete Blockgröße aus.

Das Längenfeld ist damit die Voraussetzung für Formatunabhängigkeit.

=== Kosten der Rahmung <sec:kosten>

Jedes Byte des Headers ist Overhead und steht nicht für die Nutzlast zur Verfügung. Bei den hier betrachteten Blockgrößen bestimmt dieser Overhead den Aufwand der Übertragung maßgeblich.

Deutlich wird das, wenn Blöcke statt Bytes gezählt werden. Eine Nachricht der Länge $L$ zerfällt in

$ N = ceil(L / P) $ <eq:blöcke>

Blöcke. Übertragen werden damit $N dot "MTU"$ Bytes, unabhängig davon, wie viel davon genutzt wird. Der letzte Block ist in der Regel nur teilweise gefüllt und wird trotzdem mit der vollen Blockgröße übertragen. Als Maß dient die Nutzlasteffizienz, also das Verhältnis von tatsächlich genutzten zu übertragenen Bytes:

$ eta = L / (N dot "MTU") $ <eq:effizienz> 

Daran lässt sich ablesen, wie stark Headergröße und Blockgröße die Effizienz beeinflussen. Wird der Header bei gleicher Blockgröße um ein Byte verkleinert, wächst $P$ um eins, was nach @eq:blöcke bereits $N$ um einen ganzen Block verringern kann. Eingespart wird dann eine vollständige Übertragung und somit ein Round Trip.

Neben Blockgröße und Headerbreite beeinflusst auch die Länge der Nutzlast $L$ die Effizienz, die selbst bei gleichem Inhalt vom gewählten Serialisierungsformat abhängt. Wie sich zwei verschiedene Formate auswirken, vergleicht @sec:evaluation. Die Nutzlasteffizienz hängt also von drei Faktoren ab, nämlich von Blockgröße, Headerbreite und Länge der Nutzlast.

Headerbreite und Nutzlastlänge wirken über dieselbe Aufrundung, jedoch auf unterschiedliche Weise, denn eine kürzere Nutzlast senkt $N$ nur dann, wenn sie eine Blockgrenze unterschreitet, während ein kleinerer Header alle Blockgrenzen zugleich verschiebt. Bei kleiner @mtu ist deshalb zu erwarten, dass die Rahmung stärker auf die Anzahl der Übertragungen wirkt als die Wahl des Serialisierungsformats, obwohl das Format die Nutzlast direkter verkleinert. @sec:evaluation prüft diese Erwartung.

=== Fragmentierung und Rekonstruktion <sec:fragmentierung>

Die Zerlegung einer Nachricht folgt unmittelbar aus den bisherigen Festlegungen. Die serialisierte Nutzlast wird in Abschnitte von höchstens $P$ Byte geteilt, jeder Abschnitt erhält die Kennung der Nachricht und seine Position, und der letzte wird als solcher markiert. Der letzte Abschnitt ist dabei in der Regel kürzer als $P$, die tatsächliche Länge trägt das Längenfeld. 

Wichtig ist, dass diese Zuordnung eindeutig ist, denn zu einer Nachricht und einer Position gehört immer derselbe Block. Die Zerlegung ist damit wiederholbar und nicht an einen Fortschritt gebunden, also idempotent, sodass die Wiederholung einer Übertragung das Ergebnis nicht verändert.

==== Wann ist eine Nachricht vollständig? <pg:vollstaendig>
Die Gesamtlänge einer Nachricht ist dem Empfänger nicht bekannt, er kann die Vollständigkeit also nicht durch einen Vergleich mit ihr feststellen. Erkennbar ist sie nur an den eingetroffenen Blöcken. Trägt der Block an Position $n$ die Endmarkierung, besteht die Nachricht aus $n + 1$ Blöcken. Vollständig ist sie, sobald jede Position von $0$ bis $n$ mindestens einmal eingetroffen ist.

Die Steuerinformationen haben dabei verschiedene Aufgaben, denn Endmarkierung und Position bestimmen, wie viele Blöcke zur Nachricht gehören, während das Längenfeld angibt, wie viele Bytes eines Blocks dazugehören. Die Prüfung auf Vollständigkeit kommt somit ohne Kenntnis des Inhalts aus.

==== Was passiert bei Übertragungswiederholungen? <pg:wiederholung>
Ein Block wird erneut übertragen, wenn die zugehörige Bestätigung ausbleibt. Das kann daran liegen, dass er den Empfänger nicht erreicht hat, dass ihn eine Prüfsumme des Übertragungswegs als beschädigt verworfen hat oder dass die Bestätigung selbst verloren ging. Für den Sender sind diese Fälle nicht unterscheidbar, weshalb er in allen gleich reagiert und den Block erneut sendet. Die Mechanismen dafür werden in @sec:zuverlaessigkeit beschrieben.

Da die Zerlegung eindeutig ist, hat der wiederholte Block denselben Inhalt wie der ursprüngliche, was dem Empfänger allein jedoch nicht hilft, denn hängt er den Block ein zweites Mal an, entsteht eine falsche Nachricht. Die Rekonstruktion muss Wiederholungen deshalb selbst abfangen und Blöcke verwerfen, deren Position bereits vorliegt. Erst dadurch ist auch sie idempotent.

==== Was passiert bei einer abgebrochenen Übertragung? <pg:abbruch>
Bricht eine Übertragung ab, bevor die Nachricht vollständig ist, bleiben die bereits eingetroffenen Blöcke liegen. Der Empfänger kann nicht entscheiden, ob die Übertragung noch fortgesetzt wird, da er weder die Gesamtzahl der Blöcke noch einen Zeitpunkt kennt, zu dem er aufgeben dürfte. Erkennbar wird der Abbruch erst daran, dass eine neue Übertragung beginnt, also ein Block an Position $0$ eintrifft. Die Position ist dafür verlässlicher als die Kennung, da sich die Kennung nach einer festen Anzahl von Nachrichten wiederholt.

Für den Umgang mit den liegengebliebenen Blöcken bestehen zwei Möglichkeiten:

- Die unvollständige Nachricht wird verworfen, sobald eine neue beginnt. Das ist der einfachere Weg, setzt aber voraus, dass nie mehr als eine Nachricht gleichzeitig übertragen wird.
- Die unvollständige Nachricht bleibt erhalten und kann später fortgesetzt werden. Das erlaubt mehrere gleichzeitige Übertragungen, verlangt aber einen Puffer je Kennung, eine Regel, wann eine Nachricht endgültig aufgegeben wird, und eine Laufzeitumgebung, die mehrere Übertragungen nebenläufig verwalten kann.

Der Entwurf wählt die erste Möglichkeit. Die betrachtete Verbindungsklasse ist anfragegetrieben, sodass der Client ohnehin nur eine Nachricht zugleich senden kann. Hinzu kommt, dass die in @sec:einschraenkungen beschriebene Laufzeitumgebung die für die zweite Möglichkeit nötige Nebenläufigkeit nicht bereitstellt.

==== Wie viel Speicher benötigt die Rekonstruktion? <pg:speicher>
Der Empfänger muss alle Blöcke einer Nachricht halten, bis sie vollständig ist. Anforderung K5 verlangt dafür eine zur Entwurfszeit bekannte Obergrenze. Sie ergibt sich aus den bisherigen Festlegungen. Ist $b_"pos"$ die Breite des Positionsfelds in Bit, lassen sich $2^(b_"pos")$ Positionen unterscheiden, und die längste übertragbare Nachricht umfasst höchstens

$ L_"max" = 2^(b_"pos") dot P $ <eq:maxlen>

Bytes. Dieser Wert ist zugleich die Obergrenze des Puffers, den die Gegenseite bereithalten muss.

=== Serialisierung <sec:serialisierung>

Die in @sec:grundlagen-serialisierung eingeführte Serialisierung überführt einen strukturierten Wert in eine Bytefolge und liest ihn auf der Gegenseite wieder aus. Sie liegt damit zwischen der Kommunikationsschicht, die mit Werten arbeitet, und der Fragmentierung, die mit Bytes arbeitet. Aus @sec:nutzlastlaenge folgt dabei eine Reihenfolge. Das Format kann erst dann frei gewählt werden, wenn die Rahmung die Länge der Nutzlast ausdrücklich mitführt.

Für die Transportschicht ist die Nutzlast ohne Struktur. Sie nimmt eine Bytefolge entgegen, zerlegt sie und setzt sie auf der Gegenseite wieder zusammen. Welche Werte darin vorkommen und wie sie angeordnet sind, wertet sie nicht aus. Das Format ist damit austauschbar, ohne dass die Rahmung geändert werden muss.

Die Wahl des Formats ist an drei Bedingungen gebunden, die sich aus den bisherigen Abschnitten ergeben.

Erstens muss das Format kompakt sein. Nach @eq:blöcke bestimmt die Länge der
Nutzdaten unmittelbar die Anzahl der Blöcke, in die eine Nachricht zerfällt,
und damit die Anzahl der Übertragungen.

Zweitens muss es ohne Schema auskommen. Welche Objekte und Methoden es gibt,
steht nicht vorab fest und ändert sich während der Entwicklung. Ein
schemagebundenes Format würde einen Übersetzungsschritt einführen und die
Kommunikationsschicht an diesen Schritt binden.

Drittens muss der Decoder klein sein. Er läuft auf beiden Seiten der
Verbindung, und beide sind Mikrocontroller. Anforderung K5 gilt hier also
auch für den Umfang der eingesetzten Bibliothek und nicht nur für die Puffer.

Welches Format diese Bedingungen erfüllt, zeigt @sec:referenzimplementierung.
Wie stark sich die Wahl auf die Anzahl der Übertragungen auswirkt, misst
@sec:evaluation.

=== Zuverlässigkeitsmechanismen <sec:zuverlaessigkeit>

Die bisherigen Abschnitte setzen voraus, dass ein Block die Gegenseite erreicht, was jedoch nicht garantiert ist. Ein Block kann auf dem Weg verloren gehen oder vom Übertragungsweg als beschädigt verworfen werden, zudem kann die Bestätigung ausbleiben, obwohl der Block angekommen ist.

Für diese Fälle wird Stop-and-Wait @arq @tanenbaumComputernetzwerke2012 verwendet, bei dem ein Block gesendet und auf dessen Bestätigung gewartet wird, die bei Ausbleiben ein erneutes Senden des Blocks auslöst. Verfahren mit Sendefenster erlauben dagegen mehrere unbestätigte Blöcke gleichzeitig und erreichen dadurch einen höheren Durchsatz, weshalb sie weit verbreitet sind und beispielsweise in Mobilfunkstandards und in @tcp eingesetzt werden. Sie setzen jedoch voraus, dass mehrere Blöcke gleichzeitig unterwegs sein können und die Gegenseite Bestätigungen ohne eigene Anfrage zurücksenden kann. In der betrachteten Verbindungsklasse besteht jede Übertragung aus Anfrage und Antwort, sodass ohnehin nie mehr als ein Block unterwegs ist. Stop-and-Wait bildet damit genau das ab, was die Verbindung zulässt.

Die drei genannten Fehlerfälle sind für den Sender nicht unterscheidbar, da er in allen Fällen dasselbe sieht, nämlich eine ausbleibende Bestätigung. Eine Unterscheidung würde zudem nichts bringen, weil die Reaktion immer dieselbe ist. Der Empfänger erkennt die Wiederholung an der Position und verwirft sie, wie in @sec:fragmentierung beschrieben.

Wiederholungen brauchen eine Obergrenze. Ohne sie wartet der Client endlos, sobald der Server dauerhaft nicht antwortet. Aus einem Fehler auf der einen Seite wird dann ein Stillstand der Anwendung auf der anderen. Mit einer Obergrenze scheitert der Aufruf nach einer bekannten Zeit und die Anwendung behält die Kontrolle. Das ist zugleich die Voraussetzung dafür, dass K4 geprüft werden kann, denn eine Antwortzeit lässt sich nur angeben, wenn sie nach oben begrenzt ist.

Dieselbe Überlegung gilt für das Abholen des Ergebnisses, denn der Client fragt so lange nach, bis ein Ergebnis vorliegt, und benötigt auch dafür eine Obergrenze. Für den Server folgt daraus die Zusicherung, dass jeder Aufruf ein Ergebnis oder eine Fehlermeldung hinterlassen muss, auch wenn die Ausführung selbst fehlschlägt. Bleibt beides aus, wartet der Client auf etwas, das nie eintrifft. Die Fehlerbehandlung ist damit Teil des Protokolls und wird nicht der Umsetzung überlassen.

Drei Aufgaben übernimmt die Schicht ausdrücklich nicht. Sie korrigiert keine Fehler, sondern verlässt sich auf die Prüfsumme des Übertragungswegs und wiederholt den betroffenen Block. Sie sichert die Reihenfolge nicht gesondert ab, da der Kanal sequenziell arbeitet, wobei das Positionsfeld die Rekonstruktion gleichwohl von der Reihenfolge unabhängig macht. Außerdem betreibt sie keine Stauvermeidung. Auf einer Punkt-zu-Punkt-Verbindung mit einem Master und einer einzigen Nachricht gleichzeitig kann kein Stau entstehen.

== Kommunikationsschicht <sec:kommunikationsschicht>

Mit der Transportschicht lassen sich Nachrichten beliebiger Länge übertragen, was für eine Anwendung jedoch noch keine geeignete Schnittstelle darstellt, da sie mit Methodenaufrufen arbeitet. Diese Lücke schließt die Kommunikationsschicht, indem sie einen Aufruf auf eine Nachricht abbildet, ihn über die Transportschicht befördert und das Ergebnis an die aufrufende Stelle zurückgibt.

Von der Transportschicht kennt sie nur zwei Vorgänge. Eine Nachricht wird gesendet, und eine Nachricht kommt zurück. In wie viele Blöcke die Nachricht dabei zerfällt, wie oft ein Block wiederholt wird und in welchem Format die Nutzlast vorliegt, bleibt verborgen.

Die Schicht stellt einen @rpc her, wie er in @sec:relatedwork eingeführt wurde. Die Anwendung ruft eine Methode auf, die auf einem anderen Gerät ausgeführt wird, und erhält deren Rückgabewert, wobei an der Aufrufstelle nicht erkennbar ist, dass eine Übertragung stattgefunden hat. Dieses Verhalten wird als Aufrufstransparenz bezeichnet.

Die dort betrachteten Rahmenwerke setzen dafür Eigenschaften voraus, die diese Verbindung nicht bietet. Sie erwarten einen Transport, der Nachrichten beliebiger Länge zuverlässig befördert, und einen Rückkanal, über den der Server sein Ergebnis von sich aus zustellt. Beides ist hier nicht gegeben. Die folgenden Abschnitte entwickeln deshalb einen eigenen Aufrufmechanismus, der mit den Mitteln der Transportschicht auskommt.

Dabei ist zu klären, welche Angaben eine Aufrufnachricht mitführen muss, wie eine Antwort ihrer Anfrage zugeordnet wird, wie der Server den zuständigen Empfänger auswählt und auf welchem Weg ein Ergebnis zurückgelangt.

=== Aufbau einer Aufrufnachricht

Ein @rpc muss so viel mitführen, dass der Server den Aufruf ohne weitere Rückfrage durchführen kann, wofür drei Angaben nötig sind. Die Methodenkennung legt fest, was ausgeführt wird, die Argumente liefern die Werte, mit denen es ausgeführt wird, und der Scope bestimmt, welcher Empfänger die Methode ausführt. Wie das funktioniert, beschreibt der übernächste Abschnitt.

Angaben über Typen oder Signaturen werden nicht mitgeführt, denn nach @sec:serialisierung kommt das Format ohne Schema aus und überträgt nur Werte, keine Beschreibungen von Werten. Ob eine Methode existiert oder bestimmte Argumente erwartet, stellt sich somit erst auf dem Server und damit zur Laufzeit heraus.

Das Ergebnis nimmt denselben Weg zurück. Es ist ebenfalls eine Nachricht und trägt entweder den Rückgabewert oder eine Fehlermeldung. Welcher der beiden Fälle vorliegt, ist am Schlüssel zu erkennen, unter dem der Inhalt steht. Das folgt aus der Zusicherung in @sec:zuverlaessigkeit, denn der Client wartet auf genau eine Antwort und muss auch im Fehlerfall eine erhalten.

Diese Angaben werden mit jedem Aufruf übertragen, und nach @eq:blöcke wirkt sich ihre Länge direkt auf die Anzahl der Blöcke aus. Zwei Festlegungen halten sie deshalb kurz. Die Argumente werden in der Reihenfolge der Parameter übertragen, ohne ihre Namen. Die Methode wird über eine Kennung fester Länge bezeichnet, die beide Seiten auf dieselbe Weise aus ihrem Namen berechnen, sodass keine Tabelle zwischen Namen und Kennungen gepflegt werden muss.

Beide Festlegungen setzen voraus, dass Client und Server dieselbe Schnittstelle kennen. Sie erreichen damit dasselbe wie ein schemagebundenes Format, das Bezeichner einmal vorab vereinbart und in der Nachricht nur noch Werte überträgt. Als Vereinbarung dient hier die gemeinsame Schnittstelle der Objekttypen aus @sec:architektur. Es entsteht kein eigener Übersetzungsschritt, und das Serialisierungsformat bleibt schemafrei.

Fehler in dieser Vereinbarung fallen unterschiedlich auf. Eine unbekannte Methodenkennung erkennt der Server und antwortet mit einer Fehlermeldung, während eine abweichende Reihenfolge der Argumente nur auffällt, wenn sich dabei ihre Anzahl ändert. Vertauschte Werte gleicher Art werden dagegen ohne Fehler ausgeführt.

=== Zuordnung von Anfrage und Antwort

Jede Antwort muss der Anfrage zugeordnet werden, zu der sie gehört. Der Frame führt nach @sec:frame-struktur bereits eine Kennung je Nachricht mit, und ein Aufruf entspricht genau einer Nachricht. Diese Kennung identifiziert also zugleich den Aufruf, und eine zweite Angabe in der Nutzlast ist nicht nötig.

Die Kennung stammt damit aus dem Header, und ihr Wertebereich folgt aus dessen Breite. Sie wiederholt sich nach einer festen Anzahl von Aufrufen. Das ist zulässig, solange zwischen zwei gleichen Kennungen kein älteres Ergebnis mehr unterwegs sein kann. Eine eigene Kennung der Kommunikationsschicht wäre von der Headerbreite unabhängig, müsste aber in jeder Nachricht zusätzlich übertragen werden und würde nach @eq:blöcke die Anzahl der Übertragungen erhöhen. Die Übernahme der Kennung aus dem Header ist also eine Abwägung zwischen doppelten Steuerinformationen und einer strengen Trennung der Schichten.

=== Verteilung eingehender Aufrufe

Der Server erhält eine Nachricht mit Methodenkennung, Argumenten und
Scope und muss daraus bestimmen, wer den Aufruf ausführt. Die Adressierung ist zweistufig und mit dem Routing in @rest\-Frameworks vergleichbar. Dort ist ein Controller für einen Ressourcentyp zuständig, eine Methode darin für die Operation, und die Kennung der einzelnen Ressource kommt als Parameter an. Hier benennt der Scope die Art des Empfängers, der Methodenname die Operation, und die Referenz des einzelnen Objekts reist als Argument mit.

Der Unterschied liegt im Satz der Operationen. @rest beschränkt ihn auf wenige festgelegte Verben, während hier jede Methode des Objektmodells aufrufbar ist. Die Referenz ist außerdem kein Pfad, sondern eine Kennung, die der Server beim Erzeugen des Objekts vergibt. Wie sie gebildet wird, gehört zum Objektmodell und wird in @sec:objektmodell gezeigt.

Die zweistufige Adressierung hat einen weiteren Vorteil, da die Kennungen der Methoden nur innerhalb eines Scopes eindeutig sein müssen. Gleichnamige Methoden können somit auf verschiedenen Arten von Empfängern nebeneinander bestehen, und eine zufällige Übereinstimmung zweier Kennungen stört nur, wenn sie im selben Scope auftritt. Der Server prüft das beim Registrieren eines Empfängers und nicht erst beim Aufruf.

Verteilung und Ausführung bleiben dabei getrennt, denn die Verteilung wählt anhand des Scopes den Empfänger aus, während die Ausführung beim Empfänger selbst liegt. Ein weiterer Empfänger kann somit registriert werden, ohne die Verteilung oder die darunterliegenden Schichten zu ändern, wodurch sich das Objektmodell erweitern lässt.

Findet sich für einen Scope kein Empfänger, muss der Aufruf mit einer Fehlermeldung beantwortet werden. Nach @sec:zuverlaessigkeit wartet der Client auf genau eine Antwort, und ein stillschweigendes Verwerfen würde ihn bis zur Obergrenze warten lassen.

=== Anfragegetriebener Rückkanal

Aufgrund der eingeschränkten Kommunikationsrichtung aus @sec:einschraenkungen kann der Server keine Übertragung anstoßen. Ein Ergebnis kann er deshalb nicht zustellen, sondern nur bereithalten, bis es abgeholt wird. Hinzu kommt, dass die Ausführung noch nicht abgeschlossen ist, wenn der letzte Block des Aufrufs bestätigt wurde. Der Client muss also zunächst feststellen, ob ein Ergebnis vorliegt, und es anschließend abholen. 

Ereignisse folgen demselben Muster, unterscheiden sich jedoch in einem Punkt. Ein Ergebnis erwartet der Client, weil er den zugehörigen Aufruf abgesetzt hat, ein Ereignis dagegen nicht, sodass er regelmäßig nachfragen muss, ohne zu wissen, ob es etwas abzuholen gibt.

Die zeitliche Auflösung hängt damit vom Abfragetakt ab, denn ein Ereignis, das zwischen zwei Abfragen auftritt, wird erst bei der nächsten bemerkt. Häufigeres Abfragen verkürzt zwar diese Verzögerung, kostet jedoch je Abfrage eine Übertragung und damit Zeit, die für Aufrufe fehlt, während selteneres Abfragen Übertragungen spart und die Verzögerung verlängert. Beides lässt sich nicht gleichzeitig verbessern.

Zwischen zwei Abfragen können mehrere Ereignisse auftreten, die der Server puffern muss, wobei der Puffer nach K5 begrenzt ist. Läuft er über, gehen Ereignisse verloren. Für diesen Fall muss ein Verhalten festgelegt sein, da ein stilles Verwerfen für die Anwendung nicht erkennbar wäre.

Am anfragegetriebenen Rückkanal wirkt sich die eingeschränkte Kommunikationsrichtung direkt auf die Anwendung aus. Ob die erreichbare Antwortzeit die Anforderung K4 einhält, prüft @sec:evaluation. Eine Möglichkeit, diesen Weg für reine Darstellungsreaktionen zu umgehen, zeigt @sec:ansteuerung.