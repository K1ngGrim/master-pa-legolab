#import "../template/template.typ": pg

= Entwurf von Transport- und Kommunikationsschicht <sec:entwurf>

// ABGRENZUNG: konzeptionell. Welche Information uebertragen werden muss und
// warum - nicht, in welchen Bytes. Feldbreiten, Byte-Layout und Opcode-Werte
// gehoeren in Kap. 6.5. Regeln in Abhaengigkeit der MTU formulieren, nicht in
// Zahlen; nur dann ist der Entwurf uebertragbar.
//
// AUFBAU: die beiden mittleren Schichten des Modells aus Kap. 4.2, jede in
// einem eigenen Abschnitt. Die Busanbindung darunter wird nicht entworfen,
// sondern vorgefunden (Kap. 6.4); das Objektmodell darueber ist
// anwendungsspezifisch (Kap. 6.6).

Dieses Kapitel beschreibt den Entwurf der Transport- und Kommunikationsschicht. Diese zwei Schichten bilden die Grundlage für zuverlässige und effiziente Kommunikation zwischen der Anwendung und der darunterliegenden Transporttechnologie.

Die Transportschicht, im OSI-Modell auch als Transport Layer bezeichnet, ist verantwortlich für die Segmentierung von Nachrichten beliebiger Länge in kleinere Pakete und deren korrekte Rekonstruktion auf der Empfängerseite. Sie stellt außerdem Funktionen wie Stauervermeidung (engl. congestion avoidance) und die Sicherstellung einer fehlerfreien Übertragung bereit @tanenbaumComputernetzwerke2012. 

Ebenfalls wird die Kommunikationsschicht beschrieben, die auf der Transportschicht aufsetzt und die Schnittstelle zwischen der Anwendung und dem Transportmechanismus bildet. Sie kapselt die Details der Verbindung und stellt der Anwendung ein einfaches und zuverlässiges Kommunikationsmodell bereit. Die Kommunikationsschicht wird im OSI-Modell auch als Session Layer bezeichnet und ist verantwortlich für die Verwaltung von Kommunikationssitzungen, die Zuordnung von Anfragen und Antworten sowie die Serialisierung der Nutzdaten.

== Motivation und Randbedingungen

Um zu verstehen, warum für die Transport- und Kommunikationsschicht bestimmte Entscheidungen getroffen wurden, ist es essentiell, die Motivation und Randbedingungen zu erläutern. Aus vorherigen Kapiteln geht hervor, dass die Transportschicht eine zuverlässige und effiziente Übertragung von Nachrichten gewährleisten muss, unabhängig von der zugrunde liegenden Transporttechnologie. Auch die Kommunikationsschicht muss sicherstellen, dass Verbindungen korrekt verwaltet werden und das Anfragen und Antworten zuverlässig zugeordnet werden können. Sie sorgt außerdem für Aufruftransparenz und für eine einheitliche Datenverarbeitung, sowie die Serialisierung der Nutzdaten, um eine konsistente und verständliche Datenübertragung zu gewährleisten. Dieses verhalten wird in der Referenzimplementierung später als Codecs beschrieben.

== Transportschicht

// Aufgabe: aus einer Nachricht beliebiger Laenge eine Folge kleiner Pakete
// machen und auf der Gegenseite wieder zusammensetzen. Das sind die
// klassischen Aufgaben dieser Ebene - Segmentierung, Reihenfolge,
// Fehlerfreiheit.

Wie schon in @sec:entwurf beschrieben, sorgt die Transportschicht für die Segmentierung von Nachrichten beliebiger Länge in kleinere Pakete fester Größe und deren korrekte Rekonstruktion auf der Empfängerseite. Um dies zu erreichen, müssen bestimmte Steuerinformationen an jedes Paket angehängt werden. So passiert dies auch in bekannten Protokollen wie TCP oder UDP.

Im folgenden wird beschrieben wie diese Schicht in einer generischen Architektur nach unten einen Übertragungsweg voraus setzt, der Blöcke begrenzter Größe befördert. Welche OSI-Schichten dieser Weg abdeckt, ist für den Entwurf ohne Belang und je nach System verschieden, wobei wir bei dem von uns betrachteten Bus hier um Bitübertragung und Sicherung handelt. Es werden außerdem die benötigten Steuerinformationen beschrieben, ohne feste Angaben über Größe und Format zu machen, um die Übertragbarkeit auf andere Systeme zu gewährleisten. Die konkrete Implementierung dieser Schicht wird in Kapitel 6.5 aufgezeigt.

In verteilten Systemen durchläuft eine Nachricht den Schichtenstapel stets zweimal: auf der Senderseite abwärts, auf der Empfängerseite aufwärts. Grund dafür ist, dass die Nachricht beim Sender in Pakete zerlegt und beim Empfänger wieder zusammengesetzt werden muss. Jede Schicht fügt dabei auf dem Weg nach unten eigene Steuerinformationen hinzu, die auf dem Weg nach oben wieder ausgewertet und entfernt werden. Die folgenden Kapitel müssen daher stets beide Richtungen berücksichtigen. Dieses Prinzip wird im Allgemeinen als Kapselung und Entkapselung bezeichnet @HowEncapsulationWorks.

=== Interceptor-Abstraktion <sec:interceptor>

// Nahtstelle nach unten zur Busanbindung und damit die Stelle, an der
// Anforderung K6 eingeloest wird: alles Wegabhaengige liegt unterhalb dieser
// Schnittstelle, alles darueber kennt nur Bloecke fester Groesse.

Die Transportschicht setzt also nach unten einen Übertragungsweg voraus. Damit die Anforderungen, wie sie in @sec:kommunikationsanforderungen beschrieben wurde, erfüllt werden können, darf sie über diesen Weg möglichst wenig wissen. Jede Eigenschaft, die sie voraussetzt, schließt Übertragungswege aus, die diese Eigenschaft nicht bieten. Die Schnittstelle zwischen beiden ist deshalb nicht danach zu bemessen, was ein bestimmter Bus kann, sondern danach, was die betrachtete Verbindungsklasse mindestens leisten muss.

Da nur eine Seite der Verbindung, die aufrufende Seite, die Übertragung anstoßen kann, lässt sich jede Interaktion auf denselben Ablauf zurückführen:

#figure(
  image("../figures/interceptor_ablauf.png", width: 85%),
  caption: [Ablauf eines Aufrufs an der Interceptor-Schnittstelle. Jede der drei
  Phasen besteht aus Wiederholungen derselben Operation, und jede wird von der
  Steuereinheit angestoßen.],
) <abb:interceptor>

Die Schnittstelle bietet daher eine einzige Operation: Ein Block begrenzter Größe wird übergeben, und im selben Vorgang kommt ein Block zurück. Ob dieser Block Nutzdaten trägt, ein Acknowledgment oder eine Anfrage nach dem Ergebnis, ist für die Schnittstelle ohne Belang, da sie ihn nur befördert, ohne ihn zu lesen. Die drei Phasen in @abb:interceptor unterscheiden sich allein im Inhalt der Blöcke, nicht in der Operation.


Eine reichere Schnittstelle wäre denkbar, würde aber Übertragungswege ausschließen.  Eine Zustellung ohne vorherige Anfrage setzt voraus, dass die untergeordnete Seite von sich aus senden kann und ein Warten auf eine Meldung der Gegenseite setzt zusätzlich voraus, dass sie dies zu einem selbst gewählten Zeitpunkt tut. Beides leistet der hier betrachtete Bus nicht, und beides ist auch für die übrigen Vertreter der in @sec:verallgemeinerung beschriebenen Klasse nicht vorauszusetzen. Die Schnittstelle bildet daher die Schnittmenge dessen, was alle Übertragungswege dieser Klasse leisten können.

Beide Seiten erfüllen dieselbe Schnittstelle und unterscheiden sich allein in der Richtung, aus der ein Block eintrifft. Die aufrufende Seite übergibt Blöcke und erhält Antworten, die ausführende nimmt Blöcke entgegen und beantwortet sie. Die Schnittstelle ist also symmetrisch, wodurch eine Änderung des Übertragungsweges eine Stelle pro Seite betrifft.

Nicht zur Schnittstelle gehört jede Auslegung des Inhalts. Sie kennt weder die Zugehörigkeit eines Blocks zu einer Nachricht noch dessen Position darin, sie setzt nichts zusammen, erkennt keine Wiederholungen und ordnet keine Antworten zu. Alles, was Struktur voraussetzt, liegt darüber und ist Gegenstand der folgenden Kapitel. Die Interceptor-Schnittstelle erfüllt damit die Anforderung K6 aus @sec:kommunikationsanforderungen, dass die Transportschicht möglichst wenig über den Übertragungsweg wissen darf.

=== Frame-Struktur <sec:frame-struktur>

// Je Feld die Notwendigkeit begruenden:
// - Nachrichtenzugehoerigkeit: mehrere Nachrichten unterscheiden, veraltete
//   Ergebnisse verwerfen
// - Position: Wiederzusammensetzung und Erkennung von Wiederholungen
// - Ende-Markierung: Empfaenger kennt die Gesamtlaenge nicht vorab
// - Art des Frames: derselbe Kanal traegt Daten und Steuerung
// - Abwaegung: weniger Headerbits <-> weniger gleichzeitige Nachrichten,
//   kleinere Maximalnachricht

Für die Schnitstelle aus dem vorherigen Abschnitt ist ein Block ohne weitere Struktur ausreichend. Die Transportschicht legt diese Struktur hinein, um aus einer folge von unabhängigen Blöcken eine Nachricht beliebiger Länge zu machen. Dazu benötigt also jeder Block neben der Nutzlast noch Steuerinformationen, die die Zugehörigkeit zu einer Nachricht, die Position innerhalb der Nachricht und andere Eigenschaften beschreiben. Diese Steuerinformationen werden in einem Header zusammengefasst, der jedem Block vorangestellt wird. Ein Block mit dieser Struktur wird im Folgenden als Frame bezeichnet.

Folgende Felder sind für die Rahmung eines Frames notwendig, jedoch wird keine Vorgabe über Größe und Format dieser Felder gemacht, um die Übertragbarkeit auf andere Systeme zu gewährleisten. Eine konkrete Ausprägung dieser Felder stellt @sec:referenzimplementierung vor und stellt ihr eine frühere gegenüber, die dieselbe Aufgabe mit erheblich mehr Steuerinformationen löste.

*Zugehörigkeit:* Ohne Kennung der Nachricht lässt sich nicht entscheiden, ob ein eintreffender Block zu einer laufenden Übertragung gehört. Das ist selbst dann nötig, wenn ein rein Synchroner Nachrichtenaustausch, also immer nur eine Nachricht gleichzeitig gesendet wird, stattfindet. Da unmittelbar nach dem Absetzen einer Anfrage gelesen wird, kann die Gegenseite diese noch nicht verarbeitet haben. Gelesen wird dann die Antwort auf die vorangegangene Anfrage. Erst die Kennung macht solche veralteten Antworten erkennbar.

*Position:* Die Blöcke müssen in der richtigen Reihenfolge zusammengesetzt werden. Dazu ist es nötig, die Position jedes Blocks innerhalb der Nachricht zu kennen. Dies erlaubt es auch, Wiederholungen zu erkennen und zu verwerfen, die durch Übertragungsfehler oder Paketverlust entstehen können.

*Art:* Über denselben Kanal werden sowohl Nutzdaten als auch Steuerinformationen wie Acknowledgments, Anfragen nach dem Ergebnis und Fehlermeldungen übertragen. Da die Schnittstelle selbst nicht zwischen diesen Arten unterscheidet, muss der Header die Art des Blocks angeben.

*Länge der Nutzlast:* Der Übertragungsweg liefert Blöcke fester Größe, unabhängig davon, wie viel davon tatsächlich genutzt wird. Ohne ausdrückliche Angabe der Länge muss sie aus dem Inhalt abgeleitet werden. Warum das die Schicht an bestimmte Formate bindet, behandelt der nächste Abschnitt. 

*Ende der Nachricht:* Der Empfänger kennt die Gesamtlänge der Nachricht nicht vorab. Daher muss das Ende der Nachricht explizit markiert werden, um zu erkennen, wann die Übertragung abgeschlossen ist. Ableiten ließe sich das Ende daraus, dass der letzte Block nicht vollständig gefüllt ist. Diese Annahme trägt aber nur, solange sie zutrifft: Ist die Nachrichtenlänge ein exaktes Vielfaches der Nutzlastgröße, ist auch der letzte Block voll und würde nicht als Ende erkannt. Der Empfänger wartete dann auf einen Block, der nie folgt.

=== Nutzlastlänge und Formatunabhängigkeit

// Wichtigster Abschnitt des Kapitels, weil hier eine Architektureigenschaft
// entschieden wird:
// - Die Busanbindung liefert Bloecke fester Groesse; der Empfaenger kennt die
//   tatsaechlich genutzte Laenge nicht
// - Ohne ausdrueckliche Angabe muss sie aus dem Inhalt abgeleitet werden
//   (Fuellbytes entfernen) -> bindet die Schicht an textbasierte Formate
// - Regel statt Zahl: das Laengenfeld braucht ceil(log2(MTU - Header + 1)) Bit
// - Das Laengenfeld ist die Voraussetzung des Formatwechsels, nicht sein
//   Nebenprodukt -> Reihenfolge: erst Rahmung, dann Serialisierung

Neben Steuerinformationen trägt ein Block natürlich auch Nutzdaten. Da der Übertragungsweg, wie vorher festgestellt, Blöcke fester Größe liefert, ist die Länge der Nutzdaten in einem Block nicht immer gleich. Wie im vorherigen Abschnitt beschrieben, würde das Fehlen einer expliziten Längenangabe kein Problem darstellen, solange der Inhalt der Nutzdaten ein Format besitzt, das die Länge oder das Ende eindeutig macht. Textbasierte Formate wie @json oder @xml besitzen diese Eigenschaft. Mittels Zeichen die ein Ende der Syntax markieren, lässt sich die Länge der Nutzdaten ableiten. Binäre Formate wie CBOR oder das in der Referenzimplementierung verwendete MessagePack besitzen diese Eigenschaft nicht. 

Diese Eigenschaft bindet die Transportschicht also an solche Formate. Formatwechsel, also die Möglichkeit, zwischen verschiedenen Formaten zu wechseln, oder den Entwicklern die Wahl des Formats zu überlassen, ist damit nicht möglich. Formatunabhängigkeit ist keine unbekannte Anforderung an Kommunikationsschichten. Beispielsweise bieten Protokolle wie @http die Möglichkeit, den Inhaltstyp der Nutzdaten zu spezifizieren, um Formatwechsel zu ermöglichen @ArchitecturalStylesDesign.

Um Formatunabhängigkeit zu gewährleisten, muss die Länge der Nutzdaten
ausdrücklich angegeben werden. Dazu nimmt der Header ein Längenfeld auf, das angibt, wie viele Bytes des Blocks tatsächlich Nutzdaten sind.

Die Breite dieses Feldes folgt aus der Blockgröße. Bezeichnet $"MTU"$ die Größe eines Blocks und $H$ die Größe des Headers, jeweils in Byte, so verbleibt als Nutzlast

$ P = "MTU" - H $ <eq:payload>

@mtu beschreibt dabei die maximale Größe eines Blocks, die der Übertragungsweg liefern kann. Das Längenfeld muss jeden Wert von $0$ bis $P$ ausdrücken können. Seine Breite $b$ in Bit beträgt damit

$ b = ceil(log_2 (P + 1)) $ <eq:laengenfeld>

Da das Längenfeld selbst Teil des Headers ist, hängen @eq:payload und
@eq:laengenfeld voneinander ab: $H$ bestimmt $P$, $P$ bestimmt $b$, und $b$ geht wieder in $H$ ein. Aufgelöst wird das, indem der kleinste Header gewählt wird, für den beide Gleichungen zugleich gelten. @sec:referenzimplementierung führt diese Rechnung für die konkrete Blockgröße aus.

Aus diesem zusammenhang folgt, dass das Längenfeld die Voraussetzung für Formatunabhängigkeit ist.

=== Kosten der Rahmung

// Traegt die Evaluationsaussage in Kap. 7.2:
// - Nutzlasteffizienz = Nutzlast / uebertragene Bytes
// - Bei kleiner MTU wiegt die Aufrundung auf ganze Pakete schwerer als die
//   Kodierung der Nutzlast
// - These hier aufstellen, in Kap. 7.2 messen

Jedes Byte des Headers ist Overhead und trägt daher nicht zur Nutzlast bei. Bei den hier betrachteten Blockgrößen ist das keine vernachlässigbare Größe, sondern bestimmt den Aufwand der Übertragung maßgeblich. 

Sichtbar wird dieses Problem erst, wenn nicht Bytes gezählt werden, sondern Blöcke. Eine Nachricht der Länge $L$ zerfällt in

$ N = ceil(L / P) $ <eq:blöcke>

Blöcke. Übertragen werden damit $N dot "MTU"$ Bytes, unabhängig davon, wie viel davon genutzt wird. Der letzte Block ist in der Regel nur teilweise gefüllt und wird trotzdem mit der vollen Blockgröße übertragen. Als maß für dieses Verhältnis dient die Nutzlasteffizienz, also das Verhältnis von tatsächlich genutzten Bytes zu übertragenen Bytes:

$ eta = L / (N dot "MTU") $ <eq:effizienz> 

Daraus ergibt sich, wie stark die Größe des Headers und die Blockgröße die Effizienz der Übertragung beeinflussen. Verkleinert man den Header bei gleicher Blockgröße um ein Byte, so wächst $P$ um eins, und nach @eq:blöcke kann das $N$ um einen ganzen Block verringern. Eingespart wird dann nicht ein Byte, sondern eine vollständige Übertragung und damit ein Round Trip.

Jedoch nicht nur Blockgröße und Headerbreite beeinflussen die Effizienz, sondern auch die Länge der Nutzlast $L$. Diese ist selbst bei gleichem Inhalt nicht immer gleich, da sie von der Serialisierung im gewählten Format abhängt. Wie zwei verschiedene Formate die Länge der Nutzlast beeinflussen, wird ebendfalls in @sec:referenzimplementierung beschrieben. Die Nutzlasteffizienz hängt also von drei Faktoren ab: Blockgröße, Headerbreite und Länge der Nutzlast.

Headerbreite und Nutzlastlänge wirken über dieselbe Aufrundung, aber unterschiedlich. Eine kürzere Nutzlast senkt $N$ nur dann, wenn sie eine Blockgrenze unterschreitet, und ein kleinerer Header verschiebt alle Blockgrenzen zugleich. Bei kleiner @mtu ist deshalb zu erwarten, dass die Rahmung stärker auf die Anzahl der Übertragungen wirkt als die Wahl des Serialisierungsformats, obwohl letzteres die Nutzlast unmittelbarer verkleinert. @sec:evaluation prüft das nach.


=== Fragmentierung und Rekonstruktion

Die Zerlegung einer Nachricht folgt unmittelbar aus den bisherigen Festlegungen. Die serialisierte Nutzlast wird in Abschnitte von höchstens $P$ Byte geteilt, jeder Abschnitt erhält die Kennung der Nachricht und seine Position, und der letzte wird als solcher markiert. Der letzte Abschnitt ist dabei in der Regel kürzer als $P$, die tatsächliche Länge trägt das Längenfeld. 

Maßgeblich ist, dass diese Zuordnung der Abschnitte eindeutig ist: Zu einer Nachricht und einer Position gehört stets derselbe Block. Die Zerlegung ist damit wiederholbar und nicht an einen Fortschritt gebunden. Sie ist demnach Idempotent, und die Wiederholung einer Übertragung hat keine Auswirkungen auf das Ergebnis.

==== Wann ist eine Nachricht vollständig? <pg:vollstaendig>
Die Gesamtlänge einer Nachricht ist dem Empfänger nicht bekannt, er kann die Vollständigkeit also nicht durch einen Vergleich mit ihr feststellen. Erkennbar ist sie allein aus den eingetroffenen Blöcken: Trägt der Block an Position $n$ die Endmarkierung, so besteht die Nachricht aus $n + 1$ Blöcken. Vollständig ist sie, sobald jede Position von $0$ bis $n$ mindestens einmal eingetroffen ist.

Die beiden Steuerinformationen haben dabei verschiedene Aufgaben: Endmarkierung und Position bestimmen, wie viele Blöcke zur Nachricht gehören, das Längenfeld bestimmt, wie viele Bytes eines Blocks zu ihr beitragen. Die Prüfung auf Vollständigkeit kommt damit ohne Kenntnis des Inhalts aus.

==== Was passiert bei Übertragungswiederholungen? <pg:wiederholung>
Ein Block wird erneut übertragen, wenn die zugehörige Bestätigung ausbleibt. Das kann daran liegen, dass er den Empfänger nicht erreicht hat, dass ihn eine Prüfsumme des Übertragungswegs als beschädigt verworfen hat oder dass die Bestätigung selbst verloren ging. Für den Sender sind diese Fälle nicht unterscheidbar, weshalb er in allen dieselbe Antwort gibt und die Position erneut sendet. Die Mechanismen dafür werden in @sec:zuverlaessigkeit beschrieben.

Da die Zerlegung eindeutig ist, trägt der wiederholte Block denselben Inhalt wie der ursprüngliche. Für den Empfänger folgt daraus jedoch nichts: Hängt er ihn ein zweites Mal an, entsteht eine falsche Nachricht. Die Rekonstruktion muss die Wiederholung deshalb selbst abfangen, indem sie Blöcke verwirft, deren Position bereits vorliegt. Erst dadurch wird auch sie idempotent.

==== Was passiert bei einer abgebrochenen Übertragung? <pg:abbruch>
Bricht eine Übertragung ab, bevor die Nachricht vollständig ist, bleiben die bereits eingetroffenen Blöcke liegen. Der Empfänger kann nicht entscheiden, ob die Übertragung fortgesetzt wird, da er weder weder die Gesamtzahl der Blöcke noch einen Zeitpunkt kennt, zu dem er aufgeben dürfte. Erkennbar wird der Abbruch erst daran, dass eine neue Übertragung beginnt, also ein Block an Position $0$ eintrifft. Die Position ist dafür der verlässlichere Anhaltspunkt als die Kennung, da sich diese modulo ihrer Breite wiederholt.

Für den Umgang mit den liegengebliebenen Blöcken bestehen zwei Möglichkeiten:

- Die unvollständige Nachricht wird verworfen, sobald eine neue beginnt. Das ist der einfachere Weg, setzt aber voraus, dass nie mehr als eine Nachricht gleichzeitig übertragen wird.
- Die unvollständige Nachricht bleibt erhalten und kann später fortgesetzt werden. Das erlaubt mehrere gleichzeitige Übertragungen, verlangt aber einen Puffer je Kennung, eine Regel, wann eine Nachricht endgültig aufgegeben wird, und eine Laufzeitumgebung, die mehrere Übertragungen nebenläufig verwalten kann.

Der Entwurf wählt die erste Möglichkeit. Die betrachtete Verbindungsklasse ist anfragegetrieben, sodass die aufrufende Seite ohnehin nur eine Nachricht zugleich senden kann. Hinzu kommt, dass die in @sec:einschraenkungen beschriebene Laufzeitumgebung die für die zweite Möglichkeit nötige Nebenläufigkeit nicht bereitstellt.

==== Wie viel Speicher die Rekonstruktion benötigt <pg:speicher>
Der Empfänger muss alle Blöcke einer Nachricht halten, bis sie vollständig ist. Anforderung K5 verlangt dafür eine zur Entwurfszeit bekannte Obergrenze. Sie ergibt sich aus den bisherigen Festlegungen: Ist $b_"pos"$ die Breite des Positionsfelds in Bit, so lassen sich $2^(b_"pos")$ Positionen unterscheiden, und die längste übertragbare Nachricht beträgt

$ L_"max" = 2^(b_"pos") dot P $ <eq:maxlen>

Bytes. Dieser Wert ist zugleich die Obergrenze des Puffers, den die Gegenseite bereithalten muss.

=== Serialisierung

=== Zuverlässigkeitsmechanismen <sec:zuverlaessigkeit>

// - Bestaetigung je Frame, Wiederholung bei ausbleibender Bestaetigung
// - Warum die Wiederholung idempotent sein muss: der Endmarker darf die
//   Verarbeitung nur beim ersten Mal ausloesen
// - Warum jede Wiederholung eine Obergrenze braucht: sonst wird aus einem
//   voruebergehenden Fehler der Gegenseite ein Stillstand der Anwendung
// - Zusicherung: jeder Aufruf hinterlaesst ein Ergebnis, auch im Fehlerfall
// - Stauvermeidung entfaellt: ein Master, eine Nachricht gleichzeitig
//   unterwegs. Ausdruecklich sagen, sonst wird es als Luecke gelesen.

== Kommunikationsschicht <sec:kommunikationsschicht>

// Die Schicht, die aus der blossen Uebertragung eine Middleware macht. Sie
// setzt auf der Transportschicht auf und kennt von ihr nur "Nachricht
// hinschicken, Nachricht zurueckbekommen".

=== Aufbau einer Aufrufnachricht

// - Was mitgefuehrt werden muss: Wirkungsbereich, Methodenname, Argumente
// - Warum die Schluessel einbuchstabig sind: bei wenigen Nutzbyte je Paket
//   schlaegt jedes Zeichen unmittelbar auf die Paketzahl durch
// - Ergebnis und Fehler reisen auf demselben Weg und sind am Schluessel
//   unterscheidbar

=== Zuordnung von Anfrage und Antwort

// - Mitgefuehrte Kennung je Nachricht
// - Wozu sie ausser der Zuordnung dient: veraltete Ergebnisse verwerfen
// - Wertebereich und Ueberlauf als Abwaegung gegen die Headerbreite

=== Verteilung eingehender Aufrufe

// - Auswahl des Empfaengers ueber den Wirkungsbereich
// - Trennung von Verteilung und Ausfuehrung: das Objektmodell laesst sich
//   erweitern, ohne die darunterliegenden Schichten zu beruehren

=== Anfragegetriebener Rückkanal

// Die Antwort auf die eingeschraenkte Kommunikationsrichtung aus Kap. 3.4.1:
// das Ergebnis wird nicht zugestellt, sondern bereitgehalten und abgefragt.
// Ereignisse nach demselben Muster. Preis: die zeitliche Aufloesung haengt am
// Abfragetakt der Steuereinheit.
