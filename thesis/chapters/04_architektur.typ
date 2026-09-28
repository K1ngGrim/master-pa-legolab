= Architektur des Systems <sec:architektur>

Dieses Kapitel leitet die Architektur der Lösung aus den Anforderungen des vorigen Kapitels ab. Die Darstellung bleibt auf der konzeptionellen Ebene und nennt weder konkrete Bibliotheken noch Datenformate oder Klassen. Beschrieben werden die Ziele der Architektur, der geschichtete Aufbau mit den Aufgaben der einzelnen Schichten, die wiederkehrenden Rollen innerhalb dieser Schichten sowie das Kommunikationsmodell. Wie sich der Entwurf auf eine konkrete Hardware, Laufzeitumgebung und einen konkreten Bus abbilden lässt, zeigt @sec:referenzimplementierung.

== Zielsetzung der Architektur

Die Architektur verfolgt mehrere Ziele, die sich direkt aus den zuvor formulierten Anforderungen ergeben. Im Mittelpunkt steht die Aufrufstransparenz auf der Anwendungsseite, denn die Anwendung soll mit gewöhnlichen Methodenaufrufen arbeiten und nichts über Pakete, Bestätigungen oder das Abholen von Ergebnissen wissen müssen.

Ein zweites Ziel ist die Unabhängigkeit vom konkreten Übertragungsweg. Die höheren Schichten sollen so entworfen sein, dass der Transport hinter einer einheitlichen Schnittstelle liegt und ausgetauscht werden kann. Hinzu kommen die Bewältigung der kleinen Paketgröße durch Rahmung und Fragmentierung, ein anfragegetriebener Rückkanal für Ergebnisse und Ereignisse sowie ein sparsamer Umgang mit Speicher und Rechenzeit. Schließlich soll die Architektur eine klare und symmetrische Struktur besitzen, in der beide Seiten dieselben Schnittstellen teilen.

Aus diesen Zielen ergibt sich ein geschichteter Aufbau nach dem Vorbild einer Middleware mit entferntem Aufruf. Jede Schicht kapselt eine klar umrissene Aufgabe und stellt der darüberliegenden Schicht eine höhere Abstraktion bereit. Der Vorteil dieses Aufbaus ist, dass sich die schwierigen Eigenschaften des Zielsystems, also die geringe Paketgröße und die eingeschränkte Kommunikationsrichtung, auf wenige Schichten eingrenzen lassen und oberhalb dieser Schichten nicht mehr sichtbar sind.

== Schichtenmodell

Das System ist in fünf Schichten gegliedert, die auf beiden Seiten der Verbindung vorhanden sind, wie @abb:schichten zeigt.

#figure(
  image("../figures/schichtenmodell.png", width: 62%),
  caption: [Schichtenmodell der Architektur. Beide Seiten sind gleich aufgebaut und verkehren jeweils nur mit der unmittelbar darunterliegenden Schicht.],
) <abb:schichten>

Zwei Eigenschaften dieses Aufbaus sind hervorzuheben. Zum einen ist er symmetrisch, da beide Seiten dieselben Schichten mit denselben Aufgaben besitzen und sich lediglich in der Richtung unterscheiden, aus der ein Aufruf eintrifft. Zum anderen ist er streng geschichtet, denn jede Schicht spricht ausschließlich mit der unmittelbar darunterliegenden, sodass eine Änderung innerhalb einer Schicht die übrigen nicht berührt.

Die beiden Seiten nehmen dabei feste Rollen ein. Die Steuereinheit ruft Methoden auf und stößt jede Übertragung an, weshalb sie im Folgenden als Client bezeichnet wird, während die Anzeigeeinheit die Aufrufe ausführt, ausschließlich antwortet und deshalb als Server bezeichnet wird. Die Rollen decken sich mit der Verteilung auf dem Bus, auf dem der Hub als Master arbeitet, und wechseln im Betrieb nicht, auch nicht bei Ereignissen, da auch diese vom Client abgefragt werden.

Die folgenden Abschnitte beschreiben die Schichten von unten nach oben. Für jede Schicht werden ihre Aufgabe, die nach oben angebotene Abstraktion und die Aufgaben benannt, die sie bewusst nicht übernimmt.

=== Busanbindung

Die Busanbindung ist die einzige Schicht mit Kenntnis des tatsächlichen Übertragungswegs. Ihre Aufgabe besteht darin, einen Block fester Länge zur Gegenseite zu befördern und einen ebensolchen Block als Antwort entgegenzunehmen, ohne den Inhalt dieses Blocks oder dessen Bedeutung zu kennen.

Nach oben bietet sie damit eine sehr schmale Abstraktion an, nämlich einen paketweisen, vom Client angestoßenen Austausch fester Größe. Das ist beabsichtigt, denn nur so bleibt die Schicht austauschbar, und jeder Übertragungsweg, der einen anfragegetriebenen Austausch von Blöcken fester Länge leisten kann, ist als Unterbau geeignet.

Nicht zu ihren Aufgaben gehören die Zerlegung größerer Nachrichten, die Zuordnung von Antworten zu Anfragen und jede Form der Auslegung des Inhalts. Die Paketgröße ist für diese Schicht eine gegebene Eigenschaft des Übertragungswegs und keine Größe, die sie beeinflusst.

=== Transportschicht

Die Transportschicht vermittelt zwischen Nachrichten beliebiger Länge und den kleinen Paketen des Übertragungswegs. In ihr wirkt sich damit die zentrale Einschränkung des Zielsystems aus.

Ihre erste Aufgabe ist die Serialisierung, bei der eine strukturierte Nachricht in eine Folge von Bytes überführt und auf der Gegenseite wieder ausgelesen wird. Ihre zweite Aufgabe ist die Rahmung, bei der jedes Paket Steuerinformationen erhält, mit denen die Gegenseite die ursprüngliche Nachricht wiederherstellen kann. Dazu gehören eine Kennung der Nachricht, die Position des Pakets innerhalb der Nachricht, die Angabe, ob es das letzte Paket ist, und die Anzahl der tatsächlich genutzten Bytes. Ihre dritte Aufgabe ist die Fragmentierung, also das Zerlegen einer Nachricht in eine Folge solcher Pakete und deren Zusammensetzen auf der Gegenseite.

Nach oben verbirgt diese Schicht die Paketgröße vollständig, sodass höhere Schichten mit Nachrichten arbeiten, deren Länge sie nicht zu beachten brauchen.

Zwei Entwurfsentscheidungen dieser Schicht sind besonders wichtig. Erstens ist die Rahmung vom Serialisierungsformat getrennt, und beide sind an je einer Stelle gebündelt, sodass sich das Format wechseln lässt, ohne die Rahmung anzutasten. Zweitens muss die Rahmung die Länge der Nutzlast ausdrücklich mitführen und darf sie nicht aus dem Inhalt ableiten, etwa durch das Entfernen von Füllbytes am Ende. Andernfalls schränkt die Rahmung die zulässigen Inhalte ein und bindet die Schicht an ein textbasiertes Format. Bei einer Nutzlast von wenigen Byte je Paket sind die Steuerinformationen außerdem ein wesentlicher Kostenfaktor der gesamten Übertragung.

=== Kommunikationsschicht

Die Kommunikationsschicht stellt den entfernten Aufruf her. Auf dem Client bildet sie aus dem Namen einer Methode, deren Argumenten und der Angabe des Scopes eine Nachricht, übergibt diese nach unten und nimmt anschließend das Ergebnis entgegen. Auf dem Server nimmt sie eine Nachricht entgegen, wählt den zuständigen Empfänger, ruft die benannte Methode auf und stellt deren Ergebnis zur Abholung bereit.

In dieser Schicht liegt außerdem die Behandlung des Rückkanals. Da der Server nicht von sich aus senden kann, wird das Ergebnis nicht zugestellt, sondern bereitgehalten und auf Anfrage herausgegeben. Die Kommunikationsschicht verbirgt diesen Umstand, sodass ein Aufruf nach oben als gewöhnlicher, synchroner Methodenaufruf erscheint, der zurückkehrt, sobald das Ergebnis vorliegt.

Diese Schicht kennt die aufgerufenen Objekte nicht und befördert einen Aufruf zu einem benannten Empfänger, ohne zu wissen, was dieser darstellt.

=== Objektmodell

Das Objektmodell hebt den entfernten Aufruf auf die Ebene entfernter Objekte. Grafische Elemente wie Bildschirme, Beschriftungen und Schaltflächen werden als Objekte abgebildet, die auf dem Server bestehen und auf dem Client durch Stellvertreter vertreten werden.

Grundlage ist eine gemeinsame abstrakte Schnittstelle je Objekttyp, die auf beiden Seiten vorliegt. Damit ein Stellvertreter ein bestimmtes entferntes Objekt anspricht, vergibt der Server beim Erzeugen eines Objekts eine Referenz und verwaltet die Objekte in einer Registratur. Der Stellvertreter führt diese Referenz mit und übergibt sie bei jedem Aufruf. Auf diese Weise lassen sich beliebig viele Objekte erzeugen und gezielt ansprechen.

Nach oben bietet diese Schicht eine Sicht an, die sich von einer rein lokalen Programmierung nicht unterscheidet, womit das Ziel der Aufrufstransparenz erreicht ist.

=== Anwendung und Anzeige

Die oberste Schicht unterscheidet sich auf beiden Seiten, da hier die eigentliche Aufgabe liegt. Auf der Steuereinheit ist es die Anwendung, die das Objektmodell nutzt und nichts von der Kommunikation weiß. Auf der Anzeigeeinheit ist es die Darstellung und die Entgegennahme von Eingaben, also die Ansteuerung der Anzeigehardware und die Erkennung von Berührungen.

Beide Seiten sind über die darunterliegenden Schichten vollständig entkoppelt, weshalb ein Wechsel der Anzeigehardware ausschließlich diese oberste Schicht auf der Anzeigeeinheit berührt.

== Rollen im Entwurf

Innerhalb der Schichten treten drei wiederkehrende Rollen auf. Sie sind als Entwurfsmuster zu verstehen und legen fest, welche Verantwortung an welcher Stelle liegt, während die Umsetzung offenbleibt.

=== Interceptor

Der Interceptor bildet die Schnittstelle zwischen Kommunikationsschicht und Busanbindung und folgt dem gleichnamigen Muster aus @PDFPatternOrientedSoftware. Eine für beide Seiten gemeinsame Schnittstelle legt fest, wie ein Block zur Gegenseite gelangt und wie die Antwort zurückkommt. Auf dem Client verpackt der Interceptor einen Methodenaufruf, sendet dessen Pakete und holt anschließend das Ergebnis ab. Auf dem Server nimmt er die Pakete entgegen, setzt die Nachricht zusammen und stellt das Ergebnis zur Abholung bereit.

Da diese Schnittstelle ohne Bezug auf einen konkreten Übertragungsweg formuliert ist, ist der Interceptor der Ansatzpunkt für die Unabhängigkeit vom Übertragungsweg. Ein anderer Übertragungsweg wird angebunden, indem eine weitere Umsetzung dieser Rolle bereitgestellt wird, ohne dass die höheren Schichten davon berührt werden.

=== Dispatcher

Der Dispatcher ordnet eine eingehende Nachricht der auszuführenden Methode zu. Jede Nachricht führt dazu die Angabe ihres Scopes, eine Methodenkennung und die Argumente mit sich. Anhand des Scopes wählt der Dispatcher den zuständigen Empfänger und ruft dort die benannte Methode auf.

Für jeden Objekttyp kann ein eigener Empfänger registriert werden, was das Routing der Nachrichten von der Umsetzung der Methoden entkoppelt. Das Objektmodell lässt sich dadurch schrittweise erweitern, ohne die darunterliegenden Schichten zu verändern.

=== Stellvertreter und Adapter

Stellvertreter und Adapter sind die beiden Seiten desselben Objekttyps. Der Stellvertreter implementiert die gemeinsame Schnittstelle auf dem Client und leitet jeden Methodenaufruf weiter. Der Adapter implementiert dieselbe Schnittstelle auf dem Server und enthält die eigentliche Logik, die der Dispatcher aufruft.

Dass beide dieselbe Schnittstelle erfüllen, ist die Grundlage der Aufrufstransparenz, denn für die Anwendung ist weder erkennbar noch relevant, ob sie mit einem Stellvertreter oder mit einer lokalen Umsetzung arbeitet.

== Kommunikationsmodell

Aus Sicht der Anwendung ist die Kommunikation synchron, da ein Aufruf erst zurückkehrt, wenn das Ergebnis vorliegt. Intern folgt die Übertragung dagegen dem anfragegetriebenen Muster des Übertragungswegs, bei dem jede Übertragung vom Client angestoßen wird und der Server ausschließlich antwortet.

Logisch werden zwei Kanäle unterschieden. Über den ersten Kanal sendet der Client die Pakete eines Aufrufs, und der Server bestätigt jedes Paket. Über den zweiten Kanal fragt der Client den Zustand und das Ergebnis ab, indem er zunächst prüft, ob ein Ergebnis bereitsteht, und es anschließend Paket für Paket abholt.

Ereignisse wie Berührungen werden nach demselben Prinzip behandelt, indem der Server sie puffert und der Client sie bei Bedarf abfragt. Damit ist auch die Ereignisbehandlung an den Takt des Clients gebunden, was die zeitliche Auflösung begrenzt. Dieser anfragegetriebene Rückkanal ist die Antwort der Architektur auf die eingeschränkte Kommunikationsrichtung.

== Datenfluss im System

Der Weg eines Aufrufs durch die Schichten lässt sich in vier Phasen gliedern. Zunächst nimmt der Stellvertreter den Methodenaufruf entgegen und übergibt ihn der Kommunikationsschicht. Diese bildet aus Methodennamen, Argumenten und Scope eine Nachricht, welche die Transportschicht serialisiert, in Pakete zerlegt und mit Steuerinformationen versieht.

In der zweiten Phase überträgt der Client die Pakete. Der Server bestätigt jedes empfangene Paket und setzt die Nachricht zusammen, sobald das letzte Paket eingetroffen ist. In der dritten Phase übergibt die Kommunikationsschicht die zusammengesetzte Nachricht dem Dispatcher, der die zugehörige Methode auf dem Adapter aufruft. Das Ergebnis wird wiederum zu einer Nachricht verpackt und zur Abholung bereitgestellt.

In der letzten Phase fragt der Client ab, ob das Ergebnis bereitsteht, und holt es anschließend Paket für Paket ab. Die Kommunikationsschicht setzt die Antwort zusammen, liest die Nutzlast aus und gibt das Ergebnis an den Stellvertreter zurück, der es an die Anwendung weiterreicht.

An diesem Ablauf zeigt sich das Verhältnis von Nutzlast und Steuerverkehr. Ein einzelner Aufruf zerfällt in eine Folge von Paketen, die jeweils einzeln bestätigt werden, gefolgt von wiederholten Abfragen nach dem Ergebnis. Die Dauer eines Aufrufs hängt damit vor allem von der Anzahl der Übertragungen ab und weniger von der Geschwindigkeit des Übertragungswegs, was die Evaluation aufgreift und beziffert.
