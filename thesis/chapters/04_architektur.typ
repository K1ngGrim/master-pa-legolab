= Architektur des Systems <sec:architektur>

Dieses Kapitel entwickelt die Architektur der Lösung aus den Anforderungen des vorigen Kapitels. Die Darstellung bleibt bewusst auf der konzeptionellen Ebene und benennt weder konkrete Bibliotheken noch Datenformate oder Klassen. Beschrieben werden die Entwurfsziele, der geschichtete Aufbau mit den Aufgaben der einzelnen Schichten, die wiederkehrenden Entwurfsrollen innerhalb dieser Schichten sowie das Kommunikationsmodell. Wie sich dieser Entwurf auf eine bestimmte Hardware, eine bestimmte Laufzeitumgebung und einen bestimmten Bus abbilden lässt, zeigt @sec:referenzimplementierung anhand des im Rahmen dieser Arbeit umgesetzten Systems.

== Zielsetzung der Architektur

Die Architektur verfolgt mehrere Ziele, die sich unmittelbar aus den zuvor formulierten Anforderungen ableiten. Im Mittelpunkt steht die Aufrufstransparenz auf der Anwendungsseite. Die Anwendungslogik soll mit gewöhnlichen Methodenaufrufen arbeiten und nichts über Pakete, Bestätigungen oder das Abholen von Ergebnissen wissen müssen.

Ein zweites Ziel ist die Unabhängigkeit vom konkreten Übertragungsweg. Die höheren Schichten sollen so entworfen sein, dass der Transport hinter einer einheitlichen Schnittstelle liegt und ausgetauscht werden kann. Hinzu kommen die Bewältigung der kleinen Paketgröße durch Rahmung und Fragmentierung, ein anfragegetriebener Rückkanal für Ergebnisse und Ereignisse sowie ein sparsamer Umgang mit Speicher und Rechenzeit. Schließlich soll die Architektur eine klare und symmetrische Struktur besitzen, in der beide Seiten dieselben Schnittstellen teilen.

Aus diesen Zielen ergibt sich ein geschichteter Aufbau nach dem Vorbild einer Middleware mit entferntem Aufruf. Jede Schicht kapselt eine klar umrissene Aufgabe und stellt der darüberliegenden Schicht eine höherwertige Abstraktion bereit. Der Gewinn dieses Aufbaus liegt darin, dass sich die schwierigen Eigenschaften des Zielsystems, die geringe Paketgröße und die eingeschränkte Kommunikationsrichtung, auf wenige Schichten eingrenzen lassen. Oberhalb dieser Schichten sind sie nicht mehr sichtbar.

== Schichtenmodell

Das System ist in fünf Schichten gegliedert, die auf beiden Seiten der Verbindung vorhanden sind. @abb:schichten zeigt den Aufbau.

#figure(
  image("../figures/schichtenmodell.png", width: 62%),
  caption: [Schichtenmodell der Architektur. Beide Seiten sind gleich aufgebaut und verkehren jeweils nur mit der unmittelbar darunterliegenden Schicht.],
) <abb:schichten>

Zwei Eigenschaften dieses Aufbaus sind hervorzuheben. Zum einen ist er symmetrisch: Beide Seiten besitzen dieselben Schichten mit denselben Verantwortlichkeiten, sie unterscheiden sich lediglich in der Richtung, aus der ein Aufruf eintrifft. Zum anderen ist er streng geschichtet. Jede Schicht spricht ausschließlich mit der unmittelbar darunterliegenden, sodass eine Änderung innerhalb einer Schicht die übrigen nicht berührt.

Die beiden Seiten nehmen dabei feste Rollen ein. Die Steuereinheit ruft Methoden auf und stößt jede Übertragung an. Sie wird im Folgenden als Client bezeichnet. Die Anzeigeeinheit führt die Aufrufe aus und antwortet ausschließlich. Sie wird im Folgenden als Server bezeichnet. Die Rollen decken sich mit der Verteilung auf dem Bus, auf dem der Hub als Master arbeitet. Sie wechseln im Betrieb nicht, auch nicht bei Ereignissen, da auch diese vom Client abgefragt werden.

Die folgenden Abschnitte beschreiben die Schichten von unten nach oben. Für jede Schicht werden ihre Aufgabe, die von ihr nach oben angebotene Abstraktion und die bewusst nicht von ihr übernommenen Aufgaben benannt.

=== Busanbindung

Die Busanbindung ist die einzige Schicht mit Kenntnis des tatsächlichen Übertragungswegs. Ihre Aufgabe besteht darin, einen Block fester Länge zur Gegenseite zu befördern und einen ebensolchen Block als Antwort entgegenzunehmen. Sie kennt weder den Inhalt dieses Blocks noch dessen Bedeutung.

Nach oben bietet sie damit eine denkbar schmale Abstraktion an: einen paketweisen, vom Client angestoßenen Austausch fester Größe. Diese Schmalheit ist beabsichtigt, denn sie ist der Preis dafür, dass die Schicht austauschbar bleibt. Jeder Übertragungsweg, der einen anfragegetriebenen Austausch von Blöcken fester Länge leisten kann, ist als Unterbau geeignet.

Nicht zu ihren Aufgaben gehören die Zerlegung größerer Nachrichten, die Zuordnung von Antworten zu Anfragen und jede Form der Auslegung des Inhalts. Die Paketgröße ist für diese Schicht eine gegebene Eigenschaft des Übertragungswegs und keine Größe, die sie beeinflusst.

=== Transportschicht

Die Transportschicht überbrückt den Abstand zwischen einer Nachricht beliebiger Länge und den kleinen Paketen des Übertragungswegs. Sie ist damit die Schicht, in der sich die zentrale Einschränkung des Zielsystems niederschlägt.

Ihre erste Aufgabe ist die Serialisierung: Eine strukturierte Nachricht wird in eine Folge von Bytes überführt und auf der Gegenseite wieder ausgelesen. Ihre zweite Aufgabe ist die Rahmung. Jedes Paket erhält Steuerinformationen, die es der Gegenseite erlauben, die ursprüngliche Nachricht wiederherzustellen: eine Kennung der Nachricht, zu der das Paket gehört, seine Position innerhalb dieser Nachricht, die Angabe, ob es das letzte Paket ist, und die Anzahl der tatsächlich genutzten Nutzbytes. Ihre dritte Aufgabe ist die Fragmentierung, also das Zerlegen einer Nachricht in eine Folge solcher Pakete und deren Zusammensetzen auf der Gegenseite.

Nach oben verbirgt diese Schicht die Paketgröße vollständig. Höhere Schichten arbeiten mit Nachrichten, deren Länge sie nicht zu beachten brauchen.

Zwei Entwurfsentscheidungen dieser Schicht verdienen Beachtung. Erstens ist die Rahmung vom Serialisierungsformat getrennt. Beide sind an je einer Stelle gebündelt, sodass sich das Format wechseln lässt, ohne die Rahmung anzutasten. Zweitens muss die Rahmung die Länge der Nutzlast ausdrücklich mitführen und darf sie nicht aus dem Inhalt ableiten, etwa durch das Entfernen von Füllbytes am Ende. Andernfalls schränkt die Rahmung die zulässigen Inhalte ein und bindet die Schicht an ein textbasiertes Format. Bei einer Nutzlast von wenigen Byte je Paket ist die Größe der Steuerinformationen zudem kein Randaspekt, sondern der wesentliche Kostenfaktor der gesamten Übertragung.

=== Kommunikationsschicht

Die Kommunikationsschicht stellt den entfernten Aufruf her. Auf dem Client bildet sie aus dem Namen einer Methode, deren Argumenten und der Angabe des Wirkungsbereichs eine Nachricht, übergibt diese nach unten und nimmt anschließend das Ergebnis entgegen. Auf dem Server nimmt sie eine Nachricht entgegen, wählt den zuständigen Empfänger, ruft die benannte Methode auf und stellt deren Ergebnis zur Abholung bereit.

In dieser Schicht liegt außerdem die Behandlung des Rückkanals. Da der Server nicht von sich aus senden kann, wird das Ergebnis nicht zugestellt, sondern bereitgehalten und auf Anfrage herausgegeben. Die Kommunikationsschicht verbirgt diesen Umstand: Nach oben erscheint ein Aufruf als gewöhnlicher, synchroner Methodenaufruf, der zurückkehrt, sobald das Ergebnis vorliegt.

Nicht zu ihren Aufgaben gehört die Kenntnis der aufgerufenen Objekte. Sie befördert einen benannten Aufruf zu einem benannten Empfänger, ohne zu wissen, was dieser darstellt.

=== Objektmodell

Das Objektmodell hebt den entfernten Aufruf auf die Ebene entfernter Objekte. Grafische Elemente wie Bildschirme, Beschriftungen und Schaltflächen werden als Objekte abgebildet, die auf dem Server bestehen und auf dem Client durch Stellvertreter vertreten werden.

Grundlage ist eine gemeinsame abstrakte Schnittstelle je Objekttyp, die auf beiden Seiten vorliegt. Damit ein Stellvertreter ein bestimmtes entferntes Objekt anspricht, vergibt der Server beim Erzeugen eines Objekts eine Referenz und verwaltet die Objekte in einer Registratur. Der Stellvertreter führt diese Referenz mit und übergibt sie bei jedem Aufruf. Auf diese Weise lassen sich beliebig viele Objekte erzeugen und gezielt ansprechen.

Nach oben bietet diese Schicht eine Sicht an, die sich von einer rein lokalen Programmierung nicht unterscheidet. Sie ist damit die Schicht, die das Ziel der Aufrufstransparenz einlöst.

=== Anwendung und Anzeige

Die oberste Schicht ist auf beiden Seiten verschieden, da hier die eigentliche Aufgabe liegt. Auf der Steuereinheit ist es die Anwendung, die das Objektmodell nutzt und keinerlei Kenntnis der Kommunikation besitzt. Auf der Anzeigeeinheit ist es die tatsächliche Darstellung und die Entgegennahme von Eingaben, also die Ansteuerung der Anzeigehardware und die Erkennung von Berührungen.

Beide Seiten sind über die darunterliegenden Schichten vollständig entkoppelt. Ein Wechsel der Anzeigehardware berührt ausschließlich diese oberste Schicht auf der Anzeigeeinheit.

== Rollen im Entwurf

Innerhalb der Schichten treten drei wiederkehrende Rollen auf. Sie sind als Entwurfsmuster zu verstehen und legen fest, welche Verantwortung an welcher Stelle liegt, nicht wie sie umzusetzen ist.

=== Interceptor

Der Interceptor bildet die Nahtstelle zwischen Kommunikationsschicht und Busanbindung. Eine für beide Seiten gemeinsame Schnittstelle legt fest, wie ein Aufruf abgesetzt, eine Bestätigung verarbeitet und die Bereitschaft eines Ergebnisses geprüft wird. Auf dem Client verpackt der Interceptor einen Methodenaufruf, sendet dessen Pakete und holt anschließend das Ergebnis ab. Auf dem Server nimmt er die Pakete entgegen, setzt die Nachricht zusammen und stellt das Ergebnis zur Abholung bereit.

Da diese Schnittstelle ohne Bezug auf einen konkreten Übertragungsweg formuliert ist, bildet der Interceptor den Ansatzpunkt für die Unabhängigkeit vom Übertragungsweg. Ein anderer Übertragungsweg wird angebunden, indem eine weitere Ausprägung dieser Rolle bereitgestellt wird; die höheren Schichten bleiben unberührt.

=== Dispatcher

Der Dispatcher ordnet eine eingehende Nachricht der auszuführenden Methode zu. Jede Nachricht führt dazu die Angabe ihres Wirkungsbereichs, eine Kennung der Methode und deren Argumente mit sich. Anhand des Wirkungsbereichs wählt der Dispatcher den zuständigen Empfänger und ruft dort die benannte Methode auf.

Für jeden Objekttyp kann ein eigener Empfänger registriert werden. Diese Trennung entkoppelt das Routing der Nachrichten von der eigentlichen Umsetzung der Methoden und erlaubt es, das Objektmodell schrittweise zu erweitern, ohne die darunterliegenden Schichten zu berühren.

=== Stellvertreter und Adapter

Stellvertreter und Adapter sind die beiden Seiten desselben Objekttyps. Der Stellvertreter implementiert die gemeinsame Schnittstelle auf dem Client und leitet jeden Methodenaufruf weiter. Der Adapter implementiert dieselbe Schnittstelle auf dem Server und enthält die reale Logik, die der Dispatcher aufruft.

Dass beide dieselbe Schnittstelle erfüllen, ist die strukturelle Grundlage der Aufrufstransparenz: Für die Anwendung ist nicht erkennbar und nicht erheblich, ob sie mit einem Stellvertreter oder mit einer lokalen Umsetzung arbeitet.

== Kommunikationsmodell

Aus Sicht der Anwendung ist die Kommunikation synchron. Ein Aufruf kehrt erst zurück, wenn das Ergebnis vorliegt. Unter dieser Oberfläche folgt die Übertragung dem anfragegetriebenen Muster des Übertragungswegs. Jede Übertragung wird vom Client angestoßen, der Server antwortet nur.

Logisch werden zwei Kanäle unterschieden. Über den ersten Kanal sendet der Client die Pakete eines Aufrufs, und der Server bestätigt jedes Paket. Über den zweiten Kanal fragt der Client den Zustand und das Ergebnis ab. Er prüft zunächst, ob ein Ergebnis bereitsteht, und holt es anschließend Paket für Paket ab.

Ereignisse wie Berührungen werden nach demselben Prinzip behandelt. Der Server puffert sie, und der Client fragt sie bei Bedarf ab. Damit ist auch die Ereignisbehandlung an den Takt des Clients gebunden, was die zeitliche Auflösung begrenzt. Dieser client-gesteuerte Rückkanal ist die zentrale Antwort der Architektur auf die eingeschränkte Kommunikationsrichtung.

== Datenfluss im System

Der Weg eines Aufrufs durch die Schichten lässt sich in vier Phasen gliedern. Zunächst nimmt der Stellvertreter den Methodenaufruf entgegen und übergibt ihn der Kommunikationsschicht. Diese bildet aus Methodennamen, Argumenten und Wirkungsbereich eine Nachricht. Die Transportschicht serialisiert sie, zerlegt sie in Pakete und versieht diese mit Steuerinformationen.

In der zweiten Phase überträgt der Client die Pakete. Der Server bestätigt jedes empfangene Paket und setzt die Nachricht zusammen, sobald das letzte Paket eingetroffen ist. In der dritten Phase übergibt die Kommunikationsschicht die zusammengesetzte Nachricht dem Dispatcher, der die zugehörige Methode auf dem Adapter aufruft. Das Ergebnis wird wiederum zu einer Nachricht verpackt und zur Abholung bereitgestellt.

In der letzten Phase fragt der Client ab, ob das Ergebnis bereitsteht, und holt es anschließend Paket für Paket ab. Die Kommunikationsschicht setzt die Antwort zusammen, liest die Nutzlast aus und gibt das Ergebnis an den Stellvertreter zurück, der es an die Anwendung weiterreicht.

Bemerkenswert an diesem Ablauf ist das Verhältnis von Nutzlast und Steuerverkehr. Ein einzelner Aufruf zerfällt in eine Folge von Paketen, die jeweils einzeln bestätigt werden, gefolgt von wiederholten Abfragen nach dem Ergebnis. Die Anzahl der erforderlichen Übertragungen und nicht die Geschwindigkeit des Übertragungswegs bestimmt damit die Dauer eines Aufrufs. Die Evaluation greift diese Beobachtung auf und beziffert sie.
