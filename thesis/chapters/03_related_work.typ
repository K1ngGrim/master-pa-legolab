= Verwandte Arbeiten

Die in dieser Arbeit entwickelte Middleware steht in einer langen Tradition von Ansätzen für entfernte Aufrufe und für die Kommunikation in verteilten und eingebetteten Systemen. Dieses Kapitel ordnet die eigene Lösung in dieses Umfeld ein. Da das Feld sehr breit ist, werden ausgewählte Vertreter betrachtet und entlang einheitlicher Kriterien verglichen. Ziel ist es, die bestehende Lücke zu benennen, die die vorliegende Arbeit schließt.

== Einordnung und Auswahlkriterien

Für den Vergleich werden Kriterien herangezogen, die sich unmittelbar aus den Rahmenbedingungen des Zielsystems ergeben. Das Zielsystem nutzt einen Master-Slave-Bus mit sehr kleinen, festen Paketen und läuft in stark eingeschränkten Laufzeitumgebungen.

Folgende Achsen werden betrachtet:

- *Abstraktionsgrad.* Bietet der Ansatz nur den Transport von Nachrichten, einen entfernten Prozeduraufruf oder darüber hinaus die Abstraktion entfernter Objekte?
- *Serialisierung.* Werden Daten textbasiert oder binär kodiert, und ist dafür ein vorab geteiltes Schema nötig?
- *Transportbindung.* Ist der Ansatz an einen konkreten Übertragungsweg gebunden oder von diesem unabhängig?
- *Fragmentierung.* Bringt der Ansatz Mechanismen für Framing und das Zerlegen großer Nachrichten in kleine Pakete mit?
- *Eignung für einen Master-Slave-Bus.* Setzt der Ansatz voraus, dass die untergeordnete Seite eigenständig senden kann, oder kommt er mit einem rein anfragegetriebenen Kanal aus?
- *Ressourcenbedarf.* Lässt sich der Ansatz innerhalb der Grenzen von MicroPython und Pybricks betreiben?

Die betrachteten Ansätze liegen dabei nicht alle auf derselben Ebene. Einige dieser Rahmenwerke sind vollständig, während andere sich ausschließlich auf die Beschreibung eines Nachrichtenformats beschränken. Wieder andere fokussieren sich lediglich auf die Kodierung von Daten oder die Anbindung an einen bestimmten Bus. Ein Vergleich, der diese Unterschiede außer Acht lässt, stellt Sachverhalte nebeneinander, die sich gegenseitig gar nicht ersetzen können. Gemäß dem abschließenden Vergleich wird die Ebene explizit als separate Spalte ausgewiesen.

Diese Kriterien strukturieren die folgende Betrachtung und münden in den abschließenden Vergleich in @tab:vergleich.

== Etablierte Rahmenwerke für entfernte Aufrufe

Das Konzept von entfernten Prozeduraufrufen wurde früh standardisiert. Der @onc_rpc @CICSTransactionServer2025 @microsystemsRPCRemoteProcedure1988 legt ein Protokoll und mit der External Data Representation ein eigenes Serialisierungsformat fest @thurlowRPCRemoteProcedure2009. Der Ansatz ist auf leistungsfähigere Netzwerke ausgelegt und nicht für Kanäle mit Paketgrößen im Bereich weniger Byte gedacht.

JSON-RPC verfolgt eine deutlich schlankere Idee @JSONRPC20Specification. Die Spezifikation beschreibt ausschließlich das Format der Anfrage- und Antwortnachrichten auf Basis der @json und überlässt den Transport bewusst der Anwendung. In ihrer Philosophie ist diese Trennung dem hier verfolgten Ansatz nahe. Allerdings setzt JSON-RPC voraus, dass eine darunterliegende Schicht vollständige Nachrichten zustellen kann. Es definiert weder ein Framing noch eine Fragmentierung für sehr kleine Pakete und sieht keinen Mechanismus für einen anfragegetriebenen Rückkanal auf einem Master-Slave-Bus vor.

Am anderen Ende des Spektrums steht @g_RPC @GRPC. Das Rahmenwerk verbindet Protocol Buffers als schemagebundene Serialisierung mit HTTP/2 als Transport und unterstützt unter anderem Datenströme in beide Richtungen. Diese Leistungsfähigkeit erfordert jedoch einen vollständigen HTTP/2-Stack und setzt eine bidirektionale Verbindung voraus. Für den betrachteten LEGO-Bus und die eingesetzten Laufzeitumgebungen ist @g_RPC zu schwergewichtig und zu stark an seinen Transport gebunden.

Zusammengefasst setzen die etablierten Rahmenwerke entweder einen leistungsfähigen Transport voraus oder standardisieren nur die Nachrichtenebene und lassen Framing, Fragmentierung und den Rückkanal offen. Genau diese darunterliegende Schicht adressiert die vorliegende Arbeit.

== Serialisierung für ressourcenarme Geräte

Da die Serialisierung die Nachrichtengröße und damit die Anzahl der nötigen Pakete bestimmt, ist sie für ein System mit kleinen Paketen besonders relevant. Die @json ist schemafrei und gut lesbar, erzeugt aber durch Klartextschlüssel und Strukturzeichen vergleichsweise große Ausgaben @brayJavaScriptObjectNotation2017. Binäre und schemafreie Formate wie MessagePack @MessagePackItsJSON und die @cbor @bormannConciseBinaryObject2020 @CBORConciseBinary erreichen bei gleichem Datenmodell deutlich kompaktere Darstellungen. Schemagebundene Formate wie Protocol Buffers gehen noch einen Schritt weiter und setzen eine geteilte Beschreibung der Datenstruktur voraus @ProtocolBuffers. Für sehr kleine Geräte existiert mit Nanopb @NanopbZephyrProject eine ressourcenschonende Implementierung dieses Ansatzes.

Die vorliegende Arbeit verwendet zunächst die @json. Ausschlaggebend dafür waren zwei praktische Gründe. Zum einen steht das Format in beiden Laufzeitumgebungen ohne zusätzliche Abhängigkeit zur Verfügung. Zum anderen ist die Nutzlast im Klartext lesbar, was auf einem Bus, dessen Datenverkehr sich nur mit erheblichem Aufwand mitschneiden lässt, einen spürbaren Vorteil bei der Fehlersuche darstellt. Solange die übrigen Schichten noch im Entstehen waren, wog diese Lesbarkeit schwerer als die Kompaktheit der Kodierung.

Mit zunehmender Reife der Umsetzung kehrte sich dieses Verhältnis um. Bei einer Nutzlast von wenigen Byte je Paket schlägt jedes zusätzliche Zeichen unmittelbar auf die Anzahl der zu übertragenden Pakete und damit auf die Dauer eines Aufrufs durch. Die Arbeit wechselt daher im weiteren Verlauf auf MessagePack @MessagePackItsJSON. Das Format bildet dasselbe Datenmodell ab, kommt ebenfalls ohne ein vorab geteiltes Schema aus und stellt es binär und damit deutlich kürzer dar. Die Lesbarkeit im Fehlerfall geht dabei verloren, lässt sich jedoch durch ein Umschalten auf die textbasierte Kodierung zurückgewinnen, da beide Formate hinter derselben Schnittstelle liegen.

Das Umwandeln und das Auslesen der Nutzlast sind deshalb an einer einzigen Stelle gebündelt und nicht über die Schichten verteilt. Das Format ist damit ein Variationspunkt: Ein Wechsel der Kodierung betrifft diese Stelle sowie die Rahmung, die dafür eine ausdrückliche Längenangabe je Paket benötigt, nicht aber den entfernten Aufruf oder das Objektmodell. Der beschriebene Wechsel ist zugleich der Nachweis, dass diese Trennung hält. Die Evaluation vergleicht beide Kodierungen und beziffert den Overhead nicht nur, sondern weist ihn in benötigten Paketen je Aufruf aus.

== Protokolle für eingebettete Systeme und Sensornetze

Neben den allgemeinen Rahmenwerken existieren Protokolle, die näher an der betrachteten Domäne liegen. Firmata @FirmataArduino2026 ermöglicht die Steuerung eines Mikrocontrollers von einem übergeordneten Rechner aus und überträgt dazu einen festgelegten Satz von Befehlen über eine serielle Verbindung. Die Asymmetrie zwischen einem treibenden Rechner und einem reagierenden Gerät ähnelt der hier vorliegenden Situation. Allerdings beschränkt sich Firmata auf einen vordefinierten Befehlsumfang und bietet weder einen allgemeinen entfernten Aufruf noch eine Abstraktion entfernter Objekte.

MQTT @MQTTStandardIoT ist auf ressourcenarme Geräte und kleine Pakete ausgelegt und kommt ohne eine durchgehende TCP-Verbindung aus. Es folgt jedoch einem Modell aus Veröffentlichen und Abonnieren, benötigt ein Gateway sowie einen Vermittler und setzt voraus, dass das Gerät eigenständig veröffentlichen kann. Auf einem reinen Master-Slave-Bus, auf dem die untergeordnete Seite nicht von sich aus senden darf, ist dieses Modell nicht unmittelbar anwendbar.

Diese Protokolle sind der betrachteten Domäne nahe, lösen aber eine andere Aufgabe. Sie zielen auf Gerätesteuerung mit festem Befehlssatz oder auf nachrichtenbasiertes Veröffentlichen und Abonnieren und nicht auf einen allgemeinen, objektorientierten entfernten Aufruf über einen anfragegetriebenen Kanal.

== PUPRemote als Transportbasis

PUPRemote @PUPRemoteDocumentationAntons nimmt in diesem Umfeld eine Sonderstellung ein, da es nicht als Alternative, sondern als Baustein der eigenen Lösung auftritt. Die Bibliothek erschließt den PUP- und LPF2-Bus und stellt darauf benannte Aufrufe bereit. Jeder Aufruf belegt einen eigenen Modus des Busses und ist über feste Formatangaben für beide Richtungen beschrieben. Der Hub schreibt die Argumente in den zugehörigen Modus und liest anschließend den Rückgabewert aus demselben Modus zurück. Mittels PUPRemote werden beidseitig befehle registriert, welche dann durch den Master aufgerufen werden können. Jedoch sind länge der Methodennamen, Argumente und Rückgabewerte durch feste Formatangaben begrenzt. Damit besitzt PUPRemote durchaus eine Aufrufsemantik und ist nicht auf reinen Datentransport beschränkt. 

Diese Semantik trägt jedoch nur so weit, wie sich ein Aufruf auf einen vorab registrierten Modus und ein einzelnes Paket fester Größe abbilden lässt. Die Anzahl der Modi ist durch den Bus begrenzt, die Formate stehen zur Übersetzungszeit fest, und für Nachrichten, die größer sind als ein Paket, ist kein Mechanismus vorgesehen. Eine Middleware, die beliebige Methoden auf einer zur Laufzeit wachsenden Menge entfernter Objekte anbieten soll, kann daher nicht einen Modus je Aufruf vergeben.

Die vorliegende Arbeit nutzt PUPRemote deshalb nicht als Aufrufmechanismus, sondern als Transportbindung. Sie registriert lediglich zwei Kommandos für den Hin- und den Rückweg, deren Nutzlast aus Sicht von PUPRemote ein undurchsichtiger Block fester Länge ist. Die Zerlegung von Nachrichten in Pakete, deren Rahmung, die Zuordnung von Antworten zu Anfragen, der client-gesteuerte Rückkanal sowie das Objektmodell aus Stellvertretern und serverseitigen Adaptern werden vollständig oberhalb davon angesiedelt. PUPRemote bleibt damit austauschbar und erfüllt die Rolle einer konkreten Transportschicht und kann durch andere Protokolle ersetzt werden, die dieselbe Anforderung erfüllen.

== Abgrenzung

@tab:vergleich fasst die betrachteten Ansätze entlang der eingangs definierten Kriterien zusammen.

#figure(
  caption: [Vergleich der betrachteten Ansätze entlang der Auswahlkriterien],
  text(size: 8pt)[
    #table(
      columns: (0.9fr, 1fr, 1.3fr, 1.2fr, 1.1fr, 0.8fr, 1.2fr),
      align: left + top,
      table.header(
        [*Ansatz*], [*Ebene*], [*Abstraktionsgrad*], [*Serialisierung*], [*Transportbindung*], [*Fragmentierung*], [*Eignung kleiner Master-Slave-Bus*],
      ),
      [gRPC], [Middleware], [RPC und Datenströme], [Protocol Buffers, schemagebunden], [an HTTP/2 gebunden], [über HTTP/2], [ungeeignet, setzt Push voraus],
      [JSON-RPC], [Nachrichtenformat], [nur Nachrichtenformat], [JSON, textbasiert], [unabhängig, offen], [nicht definiert], [offen, Rückkanal fehlt],
      [MessagePack und CBOR], [Serialisierung], [nur Serialisierung], [binär, schemafrei], [entfällt], [entfällt], [entfällt],
      [Firmata], [Geräteprotokoll], [Gerätesteuerung mit festen Befehlen], [binär, fest], [seriell, fest], [nein], [passend, aber fester Befehlssatz],
      [MQTT], [Nachrichtenprotokoll], [Veröffentlichen und Abonnieren], [binär, kompakt], [unabhängig, braucht Gateway], [teilweise], [setzt eigenständiges Senden voraus],
      [PUPRemote], [Transportanbindung, hier als Baustein verwendet], [entfernter Aufruf, ein Modus je Aufruf], [feste Formatangaben je Modus], [an PUP und LPF2 gebunden], [nein, ein Paket], [passend, aber nur ein Paket],
      [Diese Arbeit], [Middleware], [entfernter Aufruf und entfernte Objekte], [JSON, gekapselt und austauschbar], [gekapselt, PUPRemote als erste Bindung], [ja, eingebaut], [passend, client-gesteuerter Rückkanal],
    )
  ],
) <tab:vergleich>

Aus dem Vergleich wird die Lücke deutlich. Die leistungsfähigen Rahmenwerke setzen einen Transport voraus, den das Zielsystem nicht bietet. Die schlanken Ansätze standardisieren nur Teilaspekte und lassen Framing, Fragmentierung und den Rückkanal offen. Die domänennahen Protokolle lösen eine andere Aufgabe oder setzen voraus, dass die untergeordnete Seite eigenständig senden kann. PUPRemote schließlich liegt eine Ebene tiefer: Es erschließt den Bus und wird in dieser Arbeit als Transportbindung genutzt, tritt damit aber nicht an die Stelle der gesuchten Middleware.

Die vorliegende Arbeit verbindet diese Aspekte zu einer zusammenhängenden Lösung. Sie stellt einen transportunabhängig konzipierten entfernten Aufruf samt Objektmodell bereit, bringt Framing und Fragmentierung für sehr kleine Pakete mit und realisiert einen client-gesteuerten Rückkanal für einen Master-Slave-Bus, und das innerhalb der Grenzen von MicroPython und Pybricks. Der Beitrag liegt weniger in einem einzelnen neuen Grundbaustein als in der stimmigen Verbindung bekannter Konzepte für einen bislang nicht abgedeckten Anwendungsfall.