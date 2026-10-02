= Referenzimplementierung <sec:referenzimplementierung>

Dieses Kapitel bildet den Entwurf aus @sec:architektur und @sec:entwurf auf eine konkrete Hardware, zwei konkrete Laufzeitumgebungen und einen konkreten Bus ab. Hier stehen die Zahlen, die der Entwurf offengelassen hat, also die Blockgröße, die Breite der Felder im Header und das gewählte Serialisierungsformat. Der Aufbau folgt den Schichten von unten nach oben und schließt mit dem Ablauf eines vollständigen Aufrufs sowie der Nebenläufigkeit.

== Laufzeitumgebung <sec:laufzeitumgebung>

Client und Server laufen beide unter MicroPython, allerdings in sehr unterschiedlichen Ausprägungen.

Auf dem Hub läuft Pybricks @valkPybricks, eine Firmware, die die Software von LEGO ersetzt und eine stark reduzierte Variante von MicroPython bereitstellt. Für die Umsetzung sind vier Einschränkungen von Bedeutung. Ganzzahlen sind auf $2^30 - 1$ begrenzt, da die Firmware ohne Unterstützung für lange Ganzzahlen übersetzt ist, und schon eine größere Konstante im Quelltext verhindert das Laden des Moduls. Threads stehen nicht zur Verfügung, ebenso wenig einige Teile der Standardbibliothek wie `memoryview` oder das Modul `warnings`. Außerdem nimmt der Hub nur einzelne Dateien an, keine Pakete mit Unterverzeichnissen.

Grund für die alternative Firmware sind die Einschränkungen von LEGO. Der Hub ist ein geschlossenes System, das nur die von LEGO bereitgestellten Sensoren und Aktoren akzeptiert. Erst die Pybricks-Firmware @valkPybricks erlaubt die Anbindung externer Geräte, jedoch auch nur durch die bereitgestellte Schnittstelle LPF2 und PUPRemote @PUPRemoteDocumentationAntons @LMSESP32V20Clever2023.

Die Module der Middleware liegen dagegen in einer Paketstruktur. Ein eigenes Werkzeug, der Bundler in `tools/bundler.py`, führt deshalb alle Module, die der Client benötigt, zu einer einzigen Datei `pybricks_bundle.py` zusammen. Er löst die Importe innerhalb des Projekts auf, sortiert die Module so, dass jedes nach seinen Abhängigkeiten steht, und ersetzt dabei `struct` durch das auf dem Hub vorhandene `ustruct`. Das Anwendungsprogramm auf dem Hub importiert anschließend nur noch diese Datei.

Auf dem ESP32 läuft MicroPython mit der Anbindung an @LVGL, wobei diese Umgebung deutlich umfangreicher ausfällt und lange Ganzzahlen, Threads, `uasyncio` sowie einen Zufallszahlengenerator bietet. Knapp ist hier vor allem der Arbeitsspeicher, da @LVGL einen großen Teil des Heaps für die Darstellung belegt. Welche Folgen das für die Nebenläufigkeit hat, beschreibt @sec:nebenlaeufigkeit.

Der gemeinsame Code muss in beiden Umgebungen laufen und richtet sich deshalb nach der engeren, also nach Pybricks. Das betrifft vor allem die Transportschicht, den Codec und die Stellvertreter. Code, der nur auf dem Server läuft, darf die Möglichkeiten des ESP32 nutzen. @tab:zuordnung ordnet die Module der Referenzimplementierung den Schichten aus @sec:architektur zu.
#figure(
  caption: [Zuordnung der Module zu den Schichten aus @sec:architektur],
  table(
    columns: (0.9fr, 2.4fr),
    align: left + top,
    table.header([*Schicht*], [*Module*]),
    [Anwendung und Anzeige], [`hub/main.py`, `display/server/driver/`],
    [Objektmodell], [`display/protocol/`, `display/client/` mit `remote.py`, `display/server/`, `middleware/rpc/registry.py`],
    [Kommunikationsschicht], [`middleware/rpc/dispatcher.py`, `middleware/rpc/names.py`, `middleware/errors.py`, Aufrufteil von `transport/pupremote/client.py` und `server.py`],
    [Transportschicht], [`middleware/frame.py`, `message.py`, `codec.py`, `queue.py`, `constants.py`, Übertragungsteil von `client.py` und `server.py`],
    [Busanbindung], [`transport/base.py`, `transport/pupremote/binding.py`, `vendor/pupremote/`],
  ),
) <tab:zuordnung>

Zwei Zeilen der Tabelle verdienen eine Anmerkung. Die Kommunikationsschicht ist nicht vollständig busunabhängig abgelegt, denn ihr Aufrufteil liegt in denselben beiden Klassen, die auch die Rahmung ansteuern, und diese Klassen stehen im busspezifischen Paket. Die Trennung der Schichten aus @sec:architektur ist an dieser Stelle also eine Eigenschaft des Entwurfs und nicht der Dateiablage. Eine Anbindung an einen anderen Bus müsste die beiden Klassen auftrennen, was den Aufwand gegenüber @sec:testumgebung erhöht, wo die darunterliegende Operation ersetzt und die Klassen selbst unverändert verwendet werden. Spätere Stände holen diese Trennung nach, wie @sec:trennung beschreibt.

== Hardwareaufbau <sec:hardwareaufbau>

Der Hardwareaufbau ist kein eigener Beitrag dieser Arbeit, sondern der Träger, auf dem die Software läuft. Er besteht deshalb aus handelsüblichen Baugruppen, die über eine einfache Adapterplatine verbunden werden. Eine eigene Schaltungsentwicklung, etwa für die Spannungsversorgung, findet nicht statt.

=== Aufbau und Komponenten

Der Aufbau setzt die Anforderungen D1 bis D3 und S1 bis S3 aus @sec:d_s_anforderungen mit handelsüblichen Baugruppen um. Wie weit er sie erfüllt, bewertet @sec:evaluation. Das Displaymodul bietet die geforderte grafische Darstellung und die Berührungseingabe bei einer für Embedded-Anwendungen typischen Auflösung, das ESP32-Board die nötigen Schnittstellen, genügend Speicher für die Anzeigebibliothek und eine Anbindung an den Bus des Hubs.

Der Aufbau besteht aus drei Teilen. Das LMS-ESP32-Board @LMSESP32V20Clever2023 bildet den Mikrocontroller der Anzeigeeinheit, wird über das Kabel eines LEGO-Sensors direkt an einen Port des Hubs angeschlossen und übernimmt die Busanbindung. Das Displaymodul enthält das @tft\-Display mit dem Controller ILI9341 @ilitekILI9341Datasheet2011, einen kapazitiven Touchcontroller sowie einen Steckplatz für eine SD-Karte. Die Adapterplatine verbindet schließlich beide Baugruppen und enthält dabei keine aktiven Bauteile, sondern lediglich Steckverbinder und Leiterbahnen.

Signalseitig benötigt die in @sec:busanbindung beschriebene Anbindung nur eine @uart\-Verbindung auf zwei Leitungen des ESP32, die das LMS-ESP32-Board bereits zum Anschluss des Hubs führt. Die Adapterplatine muss sich deshalb nur um die Signale des Displays kümmern. Versorgt wird der Aufbau über den Port des Hubs, wobei der ESP32 die 8-V-Versorgung anfordert, da das Display mehr Strom benötigt, als die Logikversorgung liefert. Wie @sec:einschraenkungen beschreibt, verkürzt das die zulässige Länge der Kommandonamen auf fünf Zeichen.

=== Signalzuordnung und Aufbau der Adapterplatine

Das Display wird über @spi angesteuert, der Touchcontroller über @i2c, wobei @abb:schematic im Anhang die Schaltung der Adapterplatine zeigt. Die SPI-Leitungen MOSI, MISO, SCK und CS sind an den ESP32 geführt, ebenso der Touchcontroller über SDA und SCL.

Die Hintergrundbeleuchtung ist nicht an den ESP32 geführt und leuchtet dauerhaft. Die Interrupt-Leitung des Touchcontrollers ist zwar verbunden, wird jedoch nicht genutzt, da der Controller abgefragt wird (@sec:ansteuerung). Gleiches gilt für die Auswahlleitung der SD-Karte, die ebenfalls an den ESP32 geführt ist, während die SD-Karte selbst in dieser Arbeit nicht verwendet wird.

Bei der Pinbelegung ist GPIO 12 zu beachten. Der Pin wird beim Start des ESP32 ausgelesen und legt die Spannung des Flash-Speichers fest. Solange nur das Display an MISO hängt, ist das unkritisch, da die Leitung beim Start kaum getrieben wird. Wird die SD-Karte genutzt, teilt sie sich diese Leitung und kann sie über ihren Pull-up-Widerstand beim Start auf High ziehen, sodass der ESP32 nicht mehr zuverlässig startet. Für eine spätere Nutzung der SD-Karte müsste MISO deshalb auf einen anderen Pin gelegt werden. 

Die Platine wurde mit KiCad entworfen und extern gefertigt, wobei beide Baugruppen aufgesteckt werden und sich ohne Löten tauschen lassen. Eine integrierte Trägerplatine, die ESP32, Display und Versorgung auf einer Platine vereint, war ursprünglich als zweite Ausbaustufe geplant. Sie wurde aus Zeitgründen nicht umgesetzt und wird in @sec:standalone als Erweiterung aufgegriffen.

== Busanbindung <sec:busanbindung>

Die Busanbindung wird nicht entworfen, sondern vorgefunden, denn beide Seiten verwenden PUPRemote @PUPRemoteDocumentationAntons in Version 1.6, auf dem Hub als `PUPRemoteHub` und auf dem ESP32 als `PUPRemoteSensor`. Die Bibliothek setzt das @lpf2\-Protokoll um, über das der Hub mit angeschlossenen Sensoren kommuniziert.

Gegenüber dem Hub gibt sich der ESP32 als Ultraschallsensor aus, da der Hub nur Geräte mit bekannter Kennung annimmt. Beim Verbindungsaufbau handeln beide Seiten zunächst bei 2400 Baud die Eigenschaften des Geräts aus und wechseln anschließend auf 115200 Baud. Danach überwacht die Bibliothek die Verbindung selbstständig und baut sie nach einem Abbruch neu auf. Zusätzlich fordert der ESP32 die 8-V-Versorgung am Port an, da das Display mehr Strom benötigt, als die Logikversorgung liefert.

PUPRemote bildet benannte Kommandos auf die Modi des Busses ab und bringt dafür eine eigene Aufrufsemantik mit festen Formaten je Kommando mit, die hier jedoch nicht genutzt wird. Registriert ist stattdessen ein einziges Kommando `xfer`, dessen Format in beide Richtungen ein Block von 16 Byte ist, siehe @lst:register. Für PUPRemote besitzt dieser Block keine Struktur, sodass alles Weitere in den Schichten darüber liegt.

#figure(
  caption: [Registrierung des einzigen Kommandos],
```python
  COMMAND = "xfer"

  def register_interceptor(self):
      self.remote.add_command(
          self.COMMAND,
          from_hub_fmt=f"{FRAME_SIZE}s",
          to_hub_fmt=f"{FRAME_SIZE}s",
      )
```
) <lst:register>

Ein Austausch im Sinne von @sec:interceptor ist auf dem Hub ein Aufruf von `remote.call`. Dabei wird der Block in den Modus des Kommandos geschrieben und anschließend der Inhalt desselben Modus zurückgelesen. Zwischen beidem wartet die Bibliothek eine Zeit, die sich je Aufruf übergeben lässt. Ohne Angabe sieht die Bibliothek 0 ms vor. Mit diesem Wert lief der Austausch während der Entwicklung nicht zuverlässig, weshalb er in der eingesetzten Kopie der Bibliothek auf 100 ms angehoben wurde. Die Middleware übergibt keinen eigenen Wert und erhält damit diese 100 ms, was sich nach @sec:diskussion unmittelbar auf die Dauer jedes Aufrufs auswirkt. Ist die Wartezeit zu kurz, hat der ESP32 den Block bis zum Lesen noch nicht verarbeitet, und der Lesevorgang liefert die vorige Antwort. Solche veralteten Antworten erkennen die darüberliegenden Schichten an Position und Art des Frames, wie @sec:nebenlaeufigkeit ausführt.

Auf dem ESP32 ruft ein Task der Ereignisschleife etwa jede Millisekunde `process` auf, wobei je Durchlauf höchstens ein Kommando bearbeitet wird. Für jedes eintreffende Kommando ruft PUPRemote den registrierten Rückruf auf. Die Bibliothek findet ihn, indem sie den Kommandonamen im Namensraum des Hauptprogramms auswertet. Das Hauptprogramm muss den Rückruf deshalb unter dem Namen `xfer` bereitstellen.

Zwei Grenzen der Busanbindung wirken sich auf den gesamten Entwurf aus. Die Blockgröße ist mit der Firmware des Hubs auf 16 Byte begrenzt, darüber treten Prüfsummenfehler auf. Außerdem dürfen Kommandonamen bei angeforderter 8-V-Versorgung höchstens fünf Zeichen lang sein, gegenüber elf ohne diese Anforderung, weil die Bibliothek dem Namen in diesem Fall sieben Byte anhängt, mit denen sie die Versorgung ankündigt. Oberhalb dieser Schicht ist davon nur noch die Blockgröße sichtbar, und zwar als Zahl, aus der @sec:umsetzung-transport die Nutzlast ableitet.

== Transportschicht <sec:umsetzung-transport>

Die Transportschicht setzt den Entwurf aus @sec:frame-struktur in konkrete Feldbreiten um. Die folgenden Abschnitte beschreiben den Aufbau eines Frames, die Zerlegung einer Nachricht in Frames und die Serialisierung der Nutzlast.

=== Frame

Die Blockgröße ist durch die Busanbindung vorgegeben, da oberhalb von 16 Byte je Modus nach @sec:einschraenkungen Prüfsummenfehler auftreten. Damit steht die in @sec:nutzlastlaenge eingeführte @mtu fest, und alle weiteren Größen leiten sich daraus ab.

Der Header belegt drei Byte.

#figure(
  caption: [Aufbau des Frame-Headers],
  table(
    columns: (auto, auto, 1fr),
    align: left + top,
    table.header([*Byte*], [*Bits*], [*Inhalt*]),
    [0], [8], [Kennung der Nachricht],
    [1], [8], [Position innerhalb der Nachricht],
    [2], [4 obere], [Art des Frames],
    [2], [4 untere], [Länge der Nutzlast in Byte],
  ),
) <tab:header>

@tab:header zeigt den Aufbau des Headers, der für die Nutzlast 13 Byte je Frame übrig lässt.

Diese Aufteilung erfüllt die Bedingungen aus @sec:nutzlastlaenge. Bei einem Header von drei Byte ergibt @eq:payload eine Nutzlast von 13 Byte, und @eq:laengenfeld verlangt dafür ein vier Bit breites Längenfeld. Die obere Hälfte des dritten Bytes enthält die Art des Frames, die untere Hälfte die Länge der Nutzlast, sodass das Längenfeld den Header nicht vergrößert. Ein Header von zwei Byte wäre nur möglich, wenn Kennung oder Position schmaler ausfielen, was die Anzahl unterscheidbarer Nachrichten oder die maximale Nachrichtenlänge verringern würde.

@tab:frame_from_bytes zeigt die Umwandlung von Bytes in einen Frame, bei der auch eine zu kurze Eingabe abgefangen und das dritte Byte in Art und Länge aufgeteilt wird.

#figure(
  caption: [Funktion zur Erzeugung eines Frames aus Bytes],
  ```python
  @classmethod
  def from_bytes(cls, data):
    if data is None or len(data) < cls.HEADER_SIZE:
      return cls.create_error(payload=b"short")

    g_id, frame_nr, b2 = unpack(cls._header_fmt, bytes(data[:cls.HEADER_SIZE]))
    length = b2 & 0x0F
    start = cls.HEADER_SIZE

    return cls(g_id, frame_nr, b2 >> 4, data[start:start + length])
  ```
)<tab:frame_from_bytes>

Gültig bleibt die Aufteilung, solange die Nutzlast 15 Byte nicht überschreitet, da das Längenfeld keine größeren Werte darstellen kann. Bei einem Header von drei Byte entspricht das einer Blockgröße von höchstens 18 Byte. Größere Blöcke erfordern ein breiteres Längenfeld. Bis 34 Byte genügt ein Bit mehr, das sich dem Feld für die Art des Frames entnehmen ließe, solange keine neunte Art hinzukommt, wie @sec:wartezeit ausführt. Darüber wächst der Header auf vier Byte. @tab:frame_to_bytes zeigt die umgekehrte Umwandlung eines Frames in Bytes, bei der eine zu lange Nutzlast abgewiesen wird.

#figure(
  caption: [Funktion zur Umwandlung eines Frames in Bytes],
  ```python
    def to_bytes(self):
      n = len(self.payload)
      if n > MAX_PAYLOAD:
          raise ValueError("payload grew beyond {} bytes: {}".format(MAX_PAYLOAD, n))

      b2 = (self.opcode << 4) | n

      return pack(self._header_fmt, self.g_id, self.frame_nr, b2) + self.payload
  ```
)<tab:frame_to_bytes>

Die Position hat durch ihre Breite von acht Bit einen Wertebereich von 0 bis 255. Der Wert `0xFF` ist für Frames reserviert, die sich auf keine Position innerhalb einer Nachricht beziehen. Für Nutzlastframes stehen damit 255 Werte zur Verfügung, was nach @eq:maxlen die Länge einer Nachricht auf $13 dot 255 = 3315$ Byte begrenzt. Dieser Wert ist zugleich die nach K5 geforderte Obergrenze des Puffers.

Für die Art des Frames sind von 16 darstellbaren Werten acht belegt (siehe @tab:opcodes). Acht Werte kämen gerade noch mit drei Bit aus, allerdings bliebe dann kein Wert für eine weitere Art frei. Das eingesparte Bit würde außerdem nichts bringen, denn im Längenfeld könnte es Werte bis 31 darstellen, obwohl die Nutzlast 13 Byte nie überschreitet. In der Position würde es über die Bytegrenze hinausreichen und Bitoperationen über zwei Byte erfordern. Die Breite von vier Bit ist daher eine pragmatische Entscheidung.

#figure(
  caption: [Werte für die Art des Frames und ihre Bedeutung],
  table(
    columns: (auto, auto, 1fr),
    align: left + top,
    table.header([*Wert*], [*Name*], [*Bedeutung*]),
    [`0x0`], [DATA],      [Nutzlastframe, weitere folgen],
    [`0x1`], [DATA_LAST], [Nutzlastframe, letzter der Nachricht],
    [`0x2`], [ACK],       [Bestätigung eines empfangenen Frames],
    [`0x3`], [NACK],      [Ergebnis noch nicht bereit oder nichts weiter vorhanden],
    [`0x4`], [ERR],       [Fehlermeldung, kann eine kurze Beschreibung tragen],
    [`0x5`], [READY],     [Anfrage, ob ein Ergebnis bereitliegt],
    [`0x6`], [NEXT],      [Anfrage nach dem Ergebnisframe an der angegebenen Position],
    [`0x7`], [DONE],      [Antwort auf READY, das Ergebnis liegt zur Abholung bereit],
  ),
) <tab:opcodes>

=== Message

Ein `Message`-Objekt enthält die Kennung und die serialisierte Nutzlast einer Nachricht. Es dient beiden Seiten als Container für die Nachricht, die über den Bus übertragen wird. Beim Senden wird die Nutzlast gesetzt, und das Objekt liefert daraus die Frames. Beim Empfangen werden Frames gesammelt, und daraus wird die Nutzlast rekonstruiert.

Die Zerlegung ist als Funktion über Position und Nutzlast umgesetzt. In einer früheren Version lieferte ein Generator die Frames mit fortlaufendem Zustand. Diese Variante wurde verworfen, da sie das Wiederholen einzelner Frames erschwerte.

@tab:message_frames berechnet den zugehörigen Abschnitt direkt aus dem Index, ohne einen Fortschritt mitzuführen. Dieselbe Position liefert damit immer denselben Frame, wie es @sec:fragmentierung fordert. Der Rückkanal ist darauf angewiesen, da er Ergebnisframes einzeln über ihre Position anfordert und dieselbe Position mehrfach anfragen kann.

#figure(
  caption: [Funktion zur Erzeugung von Frames aus einer Nachricht],
  ```python
  def frame_at(self, index: int):
    if index < 0 or index >= MAX_FRAMES:
        return None

    start = index * PAYLOAD_SIZE
    if start >= len(self.payload) and not (index == 0 and not self.payload):
        return None

    chunk = self.payload[start:start + PAYLOAD_SIZE]
    last = start + PAYLOAD_SIZE >= len(self.payload)

    return Frame(
        g_id=self.g_id,
        frame_nr=index,
        opcode=OP_DATA_LAST if last else OP_DATA,
        payload=chunk,
    )
  ```
)<tab:message_frames>

Für das Einsammeln eingehender Frames gibt es zwei Wege, die sich in Speicherbedarf und Zusicherung unterscheiden. `collect_frame` behält jeden Frame, bis die Nachricht vollständig ist, und sortiert die Frames nach ihrer Position. Diese Variante ist von der Reihenfolge der Ankunft unabhängig, hält aber alle Frames einer Nachricht gleichzeitig im Speicher. `append_frame` hängt die Nutzlast direkt an und verwirft den Frame, was Speicher spart, aber die richtige Reihenfolge voraussetzt. `get_payload` liefert in beiden Fällen die vollständige Nutzlast.

Der Rückkanal verwendet den sammelnden Weg, der Hinweg den anhängenden. Die in @sec:fragmentierung beschriebene Unabhängigkeit von der Reihenfolge ist damit nur auf dem Rückkanal umgesetzt. Für den hier betrachteten Bus genügt das, da er sequenziell arbeitet. Bei einem Übertragungsweg, der umsortiert, müsste auch der Hinweg auf den sammelnden Weg wechseln.

=== Serialisierung <sec:umsetzung-codec>

#figure(
  image("../figures/codec.png", width: 50%),
  caption: [Klassendiagramm des Codecs],
) <abb:codec_interface>

Die Wahl des Formats ist an einer Stelle gebündelt, an der ein `Codec` zwei Operationen festlegt: `encode` wandelt ein Python-Objekt in Bytes um, `decode` wandelt Bytes wieder in ein Python-Objekt um. @abb:codec_interface zeigt die Schnittstelle des Codecs, ihre zwei Umsetzungen in der Referenzimplementierung sowie die Stellen, an denen sie verwendet werden. Eine Umsetzung muss dabei lediglich eine Bedingung erfüllen, nach der ein Wert beim Kodieren und anschließenden Dekodieren unverändert zurückkommen muss. Formal lässt sich das als

$ op("decode") compose op("encode") = op("id")_D $ <eq:roundtrip>

ausdrücken. Das Zeichen $compose$ bezeichnet die Hintereinanderausführung, wobei die rechte Funktion zuerst angewendet wird. $op("id")_D$ ist die Identität auf der Menge $D$, also die Funktion, die jeden Wert unverändert zurückgibt. @eq:roundtrip besagt damit, dass Kodieren und anschließendes Dekodieren für jeden Wert aus $D$ dasselbe Ergebnis liefert wie gar keine Umwandlung.

$D$ umfasst dabei nur die Werte, die das jeweilige Format unterstützt. Für die hier eingesetzte MessagePack-Umsetzung sind das Wahrheitswerte, Ganzzahlen im Bereich von 16 Bit, Zeichenketten, Bytefolgen sowie Listen und Abbildungen über diesen Typen. Außerhalb von $D$ gilt die Eigenschaft nicht, ein Tupel etwa kommt als Liste zurück. Die Umkehrung gilt ebenfalls nicht, da sich derselbe Wert auf mehrere Arten kodieren lässt und eine fremde Bytefolge deshalb nicht zwingend unverändert zurückkommt.

Die MessagePack-Umsetzung deckt bewusst nur den Teil des Formats ab, den das System tatsächlich austauscht. Fließkommazahlen fehlen ebenso wie die Erweiterungstypen des Formats. Übertragen werden Pixelkoordinaten, Objektreferenzen und kurze Texte, und jeder weggelassene Typ verkleinert den Decoder, der auf beiden Seiten läuft, was dem dritten Kriterium aus @sec:serialisierung entspricht.

Enger als im Format vorgesehen ist auch der Wertebereich der Ganzzahlen. Er endet bei 16 Bit, obwohl MessagePack auch 32 und 64 Bit kennt. Der Grund liegt in der Laufzeitumgebung des Hubs, die ohne Unterstützung für lange Ganzzahlen übersetzt ist, sodass sich dort keine Konstante oberhalb von $2^30 - 1$ darstellen lässt. Die Zweige des Encoders für größere Werte enthielten solche Konstanten und verhinderten das Laden des gesamten Moduls, unabhängig davon, ob je ein so großer Wert übertragen wird. Genau genommen reicht der Bereich von $-32768$ bis $65535$, da positive Werte ohne und negative mit Vorzeichen kodiert werden. Für die hier auftretenden Werte reicht das aus. Größere Werte weist der Encoder mit einem `OverflowError` ab, wie @tab:fehler zeigt.

Welcher Codec verwendet wird, legt eine einzige Zuweisung fest. Möglich ist dieser Wechsel nur, weil die Rahmung die Länge der Nutzlast ausdrücklich mitführt. Die binäre Kodierung erzeugt Nullbytes, und ohne Längenfeld würde das Abschneiden von Füllbytes Teile der Nutzlast entfernen.

Der JSON-Codec ist dabei nicht nur eine Vergleichsgröße, sondern war die erste Umsetzung. Zwei praktische Gründe sprachen dafür. Das Format steht in beiden Laufzeitumgebungen ohne zusätzliche Abhängigkeit zur Verfügung, und die Nutzlast ist im Klartext lesbar. Auf einem Bus, dessen Datenverkehr sich nur mit erheblichem Aufwand mitschneiden lässt, ist das bei der Fehlersuche ein deutlicher Vorteil, und solange die übrigen Schichten noch entstanden, wog die Lesbarkeit schwerer als eine kompakte Kodierung.

Mit zunehmender Reife änderte sich diese Gewichtung, denn bei dreizehn Byte Nutzlast je Frame wirkt sich jedes zusätzliche Zeichen nach @eq:blöcke unmittelbar auf die Anzahl der Übertragungen aus. Der Wechsel auf MessagePack betraf allein die Stelle, an der kodiert und dekodiert wird, während der entfernte Aufruf und das Objektmodell unverändert blieben. Der JSON-Codec ist dabei erhalten geblieben, weil ein mitgeschnittener Frame seine Nutzlast damit im Klartext zeigt. Wie sich die beiden Formate auf die Anzahl der Übertragungen auswirken, vergleicht @sec:evaluation.

== Kommunikationsschicht <sec:umsetzung-kommunikation>

Die Kommunikationsschicht ist auf beide Seiten verteilt. Auf dem Client, also dem Hub, bildet `PyBricksInterceptor.call()` einen Methodenaufruf auf eine Nachricht ab und wartet auf das Ergebnis, während auf dem Server, also dem ESP32, `MiddlewareInterceptor` die Nachricht entgegennimmt, sie der Verteilung übergibt und das Ergebnis zur Abholung bereitlegt. Beide Klassen übernehmen zugleich Aufgaben der Transportschicht, wie @tab:zuordnung zeigt, weshalb die folgenden Abschnitte ausschließlich den Teil beschreiben, der zur Kommunikationsschicht gehört.

Die Umsetzung folgt dem Entwurf aus @sec:kommunikationsschicht und legt zwei Punkte fest, die dort nur als Prinzip beschrieben wurden. Erstens werden Argumente nach ihrer Position übertragen, wobei objektgebundene Methoden die Referenz des Objekts als erstes Argument erhalten. Zweitens werden Methoden über eine Kennung von 16 Bit angesprochen, die beide Seiten aus dem Methodennamen berechnen.

=== Aufrufnachricht

Die Nutzlast einer Nachricht tritt in drei Ausprägungen auf, je nach Richtung und Ausgang des Aufrufs.

#figure(
  caption: [Aufbau der Nutzlast je Ausprägung],
  table(
    columns: (auto, auto, 1fr),
    align: left + top,
    table.header([*Ausprägung*], [*Schlüssel*], [*Inhalt*]),
    [`CommandPayload`], [`s`, `c`, `a`], [Scope, Methodenkennung, Liste der Argumente],
    [`DataPayload`],    [`d`],           [Rückgabewert],
    [`ErrorPayload`],   [`e`, `k`],      [Fehlerbeschreibung, optional die Fehlerart],
  ),
) <tab:payload>

@tab:payload zeigt die drei Ausprägungen, deren Schlüssel jeweils einbuchstabig sind. Die Argumente stehen als Liste in der Reihenfolge der Parameter, wie sie die gemeinsamen Schnittstellen in `display/protocol` festlegen. Die Methode wird durch eine Kennung von 16 Bit bezeichnet, die @lst:name_hash aus ihrem Namen berechnet.

#figure(
  caption: [Berechnung der Methodenkennung aus dem Methodennamen],
  ```python
  def name_hash(name):
    h = 5381
    for ch in name:
        h = ((h * 33) ^ ord(ch)) & 0xFFFF
    return h
  ```
)<lst:name_hash>

Das Verfahren ist eine auf 16 Bit begrenzte Variante des bekannten djb2-Hashs @CseyorkucaOzHashhtml. Die eingebaute Funktion `hash` ist dafür nicht verwendbar, da CPython ihr Ergebnis je Prozess zufällig verändert und MicroPython es anders berechnet. Die Maskierung nach jedem Schritt hält alle Zwischenwerte unter $2^30$, was auf dem Hub aus demselben Grund nötig ist wie die Begrenzung der Ganzzahlen in @sec:umsetzung-transport. Ein gebräuchlicher 32-Bit-Hash wie FNV würde diese Grenze überschreiten.

Die Breite von 16 Bit stellt eine Abwägung dar, denn MessagePack kodiert Werte bis 65535 in drei Byte, gegenüber 13 Byte für den Namen `create_label`. Eine Kennung von acht Bit wäre zwar ein Byte kürzer, bei zehn Methoden in einem Scope läge die Wahrscheinlichkeit einer Kollision dann jedoch bei etwa 16,3 %. Eine Kollision liegt vor, wenn zwei verschiedene Methodennamen denselben Hashwert ergeben, wobei die Wahrscheinlichkeit dafür mit der Anzahl der Methoden pro Scope steigt. Die folgende Gleichung

$ P"Kollision" = 1 - product_(i=0)^(n-1) (1 - i / N) $ <eq:collision_probability>

schätzt die Wahrscheinlichkeit ab, dass bei $n$ Methoden in einem Scope und $N$ möglichen Kennungen mindestens zwei denselben Hashwert liefern. Sie ist nur eine Näherung, da sie gleichverteilte Hashwerte annimmt und djb2 nicht gleichverteilt ist. Nach @eq:collision_probability liegt die Wahrscheinlichkeit einer Kollision bei 16 Bit und zehn Methoden bei etwa 0,069 %, bei 20 Methoden bei etwa 0,29 % und bei 50 Methoden bei 1,852 %.

Kollisionen sind somit möglich, werden jedoch beim Start des Servers erkannt. Der Server trägt dazu jede Methode in ein Dictionary ein, wobei der Hashwert als Schlüssel dient und eine zweite Methode mit demselben Hashwert zu einer Ausnahme führt, die den Start verhindert. @lst:index_methods zeigt die Funktion, die diese Indizierung vornimmt und in der Basisklasse `RPCDispatcher` liegt, von der alle Empfänger erben. Die genaue Struktur beschreibt @sec:objektmodell.

#figure(
  caption: [Funktion zur Registrierung einer Methode],
  ```python
  def _index_methods(self):
    index = {}
    for name in dir(self):
      if name.startswith("_") or name in self.NOT_REMOTE:
          continue
      if not callable(getattr(self, name)):
          continue

      h = name_hash(name)
      if h in index:
          raise ValueError("hash collision in scope '{}': {} and {}".format(
              self.scope, index[h], name))
      index[h] = name
    return index
  ```
)<lst:index_methods>

Ergebnis und Fehler unterscheiden sich allein im Schlüssel. Der Client prüft, ob `e` vorhanden ist, und löst in diesem Fall eine Ausnahme aus. Welche Ausnahme das ist, bestimmt die Fehlerart unter `k`, wie @sec:objektmodell beschreibt. Antworten enthalten keinen Scope, denn der Server braucht ihn zur Auswahl des Empfängers, während eine Antwort immer an den einen Aufrufer zurückgeht, der auf sie wartet.

=== Verteilung eingehender Aufrufe <sec:umsetzung-verteilung>

Die Zuordnung eines Aufrufs zur ausführenden Methode erfolgt in zwei Stufen. Zunächst wird anhand des Scopes ein Dispatcher ausgewählt, wobei der Scope die Art des Empfängers benennt, der den Aufruf ausführt, und im `CommandPayload` unter dem Schlüssel `s` mitgeführt wird. Die Dispatcher sind in einem `RPCDispatcherPool` registriert, wobei jeder einen eigenen Scope bedient. Die Registrierung erfolgt beim Start des Servers, und der Versuch, einen Scope ein zweites Mal zu belegen, löst eine Ausnahme aus.

Anschließend schlägt der ausgewählte Dispatcher die Methodenkennung aus `c` nach und ruft die Methode mit den Argumenten aus `a` auf. Dass diese Kennungen innerhalb eines Scopes eindeutig sind, prüft der Dispatcher beim Aufbau seines Index, wie @lst:index_methods zeigt.

Findet sich eine Kennung nicht im Index, löst der Dispatcher eine Ausnahme aus. Sie wird in eine Fehlermeldung überführt und erreicht den Client, womit die Zusicherung aus @sec:zuverlaessigkeit auch für Aufrufe gilt, die es nicht gibt.

Aufrufbar ist damit jede öffentliche Methode eines Adapters. Das ist enger als ein Zugriff über den bloßen Namen, bei dem auch Attribute wie die Registratur erreichbar wären, aber weiter gefasst als die gemeinsame Schnittstelle in `display/protocol`. Der Adapter für Screens etwa erbt die Rückrufe der Anzeigebibliothek, die ebenfalls im Index stehen. Damit wächst auch $n$ in @eq:collision_probability über die Zahl der Methoden der Schnittstelle hinaus, und mit ihm die Wahrscheinlichkeit einer Kollision, die der Start dann meldet. Für die betrachtete Punkt-zu-Punkt-Verbindung, in die kein Dritter Nachrichten einspeisen kann, ist das hinnehmbar. Bei mehreren Teilnehmern müsste der Index auf die Methoden der Schnittstelle beschränkt werden.

=== Rückkanal

Nach der Bestätigung des letzten Frames ist ein Aufruf zwar vollständig übertragen, aber noch nicht ausgeführt. Der Server muss das Ergebnis erst berechnen und legt es anschließend in einem Ausgangspuffer ab, bis der Client es abholt.

Das Abholen erfolgt über denselben anfragegetriebenen Kanal wie die Übertragung der Aufrufe. Der Client fragt in einem festen Intervall mit `READY` an, ob ein Ergebnis bereitliegt. Der Server antwortet mit `DONE`, wenn das der Fall ist, und sonst mit `NACK`. Liegt das Ergebnis vor, holt der Client es mit `NEXT` Frame für Frame ab, wobei jede Anfrage die Position des nächsten Frames angibt. Der Server beantwortet jede Anfrage mit `frame_at(index)`, sodass eine wiederholte Anfrage denselben Frame liefert. @lst:rückkanal zeigt die Beantwortung beider Anfragen. 

#figure(
  caption: [Beantwortung der beiden Anfragen auf dem Server],
```python
  if frame.opcode == OP_READY:
      if self.__is_result_ready__(frame.g_id):
          return Frame.create_done(g_id=frame.g_id).to_bytes()
      return Frame.create_no_ack(g_id=frame.g_id).to_bytes()

  if frame.opcode == OP_NEXT:
      msg = self.outgoing.get(frame.g_id)
      if msg is None:
          return Frame.create_error(g_id=frame.g_id, payload=b"nomsg").to_bytes()

      res_frame = msg.frame_at(frame.frame_nr)
      if res_frame is None:
          return Frame.create_no_ack(g_id=frame.g_id, frame_nr=frame.frame_nr).to_bytes()

      return res_frame.to_bytes()

  return Frame.create_error(g_id=frame.g_id, payload=b"badop").to_bytes()
```) <lst:rückkanal>

Die Grenzen dieses Ablaufs sind als Konstanten festgelegt.

#figure(
  caption: [Grenzen des Rückkanals],
  table(
    columns: (auto, auto, 1fr),
    align: left + top,
    table.header([*Konstante*], [*Wert*], [*Bedeutung*]),
    [RESULT_POLL_MS], [50 ms], [Abstand zwischen zwei READY-Anfragen, siehe @sec:evaluation],
    [MAX_RESULT_WAIT_MS], [5000 ms], [Wartezeit, nach der ein Aufruf als gescheitert gilt],
    [MAX_FRAME_ATTEMPTS], [8], [Versuche je Frame beim Senden und je Position beim Abholen],
    [MAX_KEPT_RESULTS], [4], [Ergebnisse, die der Server zur Abholung bereithält],
    [MAX_EVENTS], [10], [gepufferte Ereignisse je Objekt],
  ),
) <tab:rückkanal>

Der Server behält nur die jüngsten Ergebnisse und verwirft ältere, wodurch der Speicherbedarf nach K5 begrenzt bleibt. Da der Client streng nacheinander aufruft, fragt er ohnehin nur nach dem Ergebnis seines letzten Aufrufs. Ereignisse nutzen keinen eigenen Mechanismus. Der Server legt sie je Objekt in der Registratur ab und hält dort die letzten zehn vor, wobei bei Überlauf das älteste Ereignis verworfen und gezählt wird. Abgefragt werden sie über einen gewöhnlichen Aufruf wie `is_button_pressed`, der den Puffer dabei leert und die Anzahl der verworfenen Ereignisse mitliefert. Jede Abfrage kostet einen vollständigen Aufruf mit Übertragung, Wartezeit und Abholung. Ein Verlust ist für die Anwendung damit erkennbar, wie K3 in @sec:kommunikationsanforderungen es verlangt.

Wie viel Zeit ein Aufruf im Warten auf das Ergebnis verbringt, misst @sec:evaluation. Reaktionen, die ohne diesen Weg auskommen, weil der Server sie selbst ausführt, behandelt @sec:ansteuerung.

== Objektmodell <sec:objektmodell>

Das Objektmodell bildet die grafischen Elemente der Anzeige auf Objekte ab, die die Anwendung auf dem Hub wie lokale Objekte benutzt. Bildschirme, Beschriftungen und Schaltflächen heißen in der Umsetzung Screens, Labels und Buttons. Je Objekttyp gibt es eine Basisklasse in `display/protocol`. Sie wird auf dem Client von einem Stellvertreter erfüllt, der jeden Methodenaufruf weiterleitet, und auf dem Server von einem Adapter, der ihn ausführt. Die Adapter erben zusätzlich von `RPCDispatcher` und werden dadurch über ihren Scope erreichbar, wie @sec:umsetzung-verteilung beschreibt. Jeder Stellvertreter hält ein `RemoteObject`, das die Referenz des Objekts führt und sie jedem Aufruf voranstellt. Dass die Stellvertreter es halten und nicht von ihm erben, liegt an Pybricks. Die Laufzeitumgebung unterstützt keine Mehrfachvererbung, und die eine mögliche Basisklasse belegt bereits die gemeinsame Schnittstelle des Objekttyps. @abb:objektmodell zeigt diese Beziehungen beispielhaft.

#figure(
  image("../figures/objektmodell.png", width: 90%),
  caption: [Klassen des Objektmodells auf beiden Seiten],
) <abb:objektmodell>

=== Referenzen

Eine Referenz ist eine Ganzzahl von 16 Bit, die der Server beim Erzeugen eines Objekts vergibt und die aus zwei Teilen besteht. Die unteren zehn Bit bezeichnen einen Slot, also die Position des Objekts in der Tabelle der Registratur, während die oberen sechs Bit die Generation dieses Slots enthalten, einen Zähler, der bei jeder Freigabe um eins steigt. Dieses Verfahren ist als Generational Handle bekannt und wird unter anderem in der Spieleentwicklung für Referenzen auf wiederverwendete Plätze eingesetzt @niklasBitsquidDevelopmentBlog2011.

#figure(
  caption: [Auflösung einer Referenz in der Registratur],
  ```python
  def _slot(self, ref):
      # gekürzt: die Prüfung, ob ref eine nicht negative Ganzzahl ist
      index = ref & SLOT_MASK
      if index >= len(self._slots):
          return None
      slot = self._slots[index]
      if slot[2] is None or slot[0] != ref >> SLOT_BITS:
          return None
      return slot
  ```
) <lst:slot>

Ein Slot speichert neben dem Objekt und seiner Generation auch die Art des Objekts und die Referenz seines Parents. Die Art ist `screen`, `label` oder `button`, und jede Methode eines Adapters gibt beim Nachschlagen an, welche Art sie erwartet. Übergibt die Anwendung etwa die Referenz eines Screens an `set_text`, wird das erkannt, bevor auf das Objekt zugegriffen wird.

Zehn Bit erlauben 1024 gleichzeitig bestehende Objekte. Wie viele Objekte der Speicher des ESP32 tatsächlich trägt, wurde nicht gemessen und hängt mit der Lücke beim Speicherbedarf des Servers zusammen, die @sec:evaluation benennt. Die Breite von 16 Bit folgt aus @sec:umsetzung-transport, da der Codec Ganzzahlen nur bis zu dieser Größe überträgt und MessagePack eine Referenz damit in höchstens drei Byte kodiert. Eine Referenz in Textform wie `obj_12` belegt dagegen sieben Byte.

=== Lebenszyklus

Objekte entstehen immer innerhalb eines übergeordneten Objekts, wobei Screens vom Display und Labels sowie Buttons von einem Screen erzeugt werden. Ein Button besteht auf dem Server aus zwei Objekten, dem Button selbst und dem Label für seine Beschriftung. Beide werden getrennt registriert, und der Stellvertreter auf dem Client erhält beide Referenzen. So lässt sich die Beschriftung über den Scope `label` ändern, ohne dass der Button-Adapter dafür eine eigene Methode braucht.

Die Registratur bildet dabei den Objektbaum der Anzeigebibliothek nach. Jeder Eintrag kennt seinen Parent, und `release_tree` gibt ein Objekt zusammen mit allen darin erzeugten Objekten frei. Das ist nötig, weil @LVGL beim Löschen eines Objekts auch dessen Kinder löscht. Ohne den Baum würden deren Einträge in der Registratur bestehen bleiben und auf nicht mehr vorhandene Objekte verweisen.

Gelöscht wird über die Methode `delete()`, die jeder Objekttyp anbietet. Der Adapter löscht dabei zuerst das @LVGL\-Objekt und gibt anschließend die Einträge frei, wobei auch die Ereignisse des Objekts und alle Bindings entfallen, an denen es beteiligt ist. Den gerade angezeigten Screen kann die Anwendung hingegen nicht löschen, da @LVGL nicht festlegt, was angezeigt wird, wenn der aktive Screen fehlt. Ein solcher Aufruf wird deshalb mit einem Fehler beantwortet.

`clear()` löscht alle Objekte auf einmal. Die Registratur allein zu leeren genügt dafür nicht, da @LVGL die Objekte in einem eigenen Baum hält und sie nicht freigibt, wenn die letzte Python-Referenz entfällt. Der Server lädt daher zuerst einen leeren Screen und löscht anschließend jeden Screen der Registratur mit allem, was darauf liegt. Die Slots bleiben dabei erhalten und werden einzeln freigegeben, damit ihre Generationen weiterzählen.

=== Veraltete Referenzen

Nach dem Löschen eines Objekts kann dessen Stellvertreter auf dem Client weiter bestehen, wobei seine Referenz dann veraltet ist. Da freie Slots wiederverwendet werden, kann derselbe Slot inzwischen ein neues Objekt enthalten. Ohne Generation würde ein Aufruf über den alten Stellvertreter unbemerkt das neue Objekt verändern. Mit Generation passt die Referenz nicht mehr zum Slot, und der Aufruf wird abgewiesen.

Die Prüfung geschieht an zwei Stellen. Auf dem Server prüft die Registratur jede Referenz wie in @lst:slot. Auf dem Client führt der `PyBricksInterceptor` eine Session, die bei `clear()` und bei einem Verbindungsabbruch endet. Jeder Stellvertreter merkt sich die Session, in der er entstanden ist. Gehört er zu einer früheren Session, löst er den Fehler aus, ohne eine Übertragung zu starten. Nach einem Verbindungsabbruch ist das die einzige verlässliche Prüfung, denn der ESP32 kann in der Zwischenzeit neu gestartet sein und seine Registratur von vorn aufbauen. Damit eine alte Referenz auch in diesem Fall nicht zufällig passt, beginnen die Generationen nach einem Start bei einem zufälligen Wert.

Beide Prüfungen melden denselben Fehler, wobei die Fehlernutzlast neben der Beschreibung unter `e` eine Fehlerart unter `k` trägt und der Client anhand dieser Art die passende Ausnahme auslöst. `StaleReferenceError` steht dabei für ein nicht mehr vorhandenes Objekt, `WrongKindError` für eine Referenz der falschen Art, während alle übrigen Fehler als `RemoteError` ankommen. Alle drei erben von `RuntimeError`, wodurch die Anwendung gezielt auf eine veraltete Referenz reagieren und beispielsweise die Oberfläche neu aufbauen kann, ohne den Fehlertext auswerten zu müssen.

Ganz ausgeschlossen sind Verwechslungen allerdings nicht. Nach 64 Freigaben desselben Slots wiederholt sich die Generation, und ein Stellvertreter, der die ganze Zeit bestanden hat, passt wieder. Löscht die Anwendung einen Screen, bleiben außerdem die Stellvertreter der Elemente darauf auf dem Client gültig, da der Client sie nicht kennt. Ihr nächster Aufruf erreicht den Server und wird erst dort abgewiesen.

=== Erweiterung um einen Objekttyp <sec:erweiterung>

Wie weit das Objektmodell erweiterbar ist, zeigt sich an einem zusätzlichen Element. Für einen Fortschrittsbalken sind vier Schritte nötig. Zunächst entsteht in `display/protocol` eine Basisklasse `ProgressBarBase` mit den Methoden, die beide Seiten teilen, etwa `set_value` und `delete`. Anschließend wird auf dem Client ein Stellvertreter ergänzt, der wie die übrigen ein `RemoteObject` hält, und auf dem Server ein Adapter, der von `RPCDispatcher` erbt und den Scope `progress` belegt. Der Adapter erzeugt das @LVGL\-Objekt und trägt es mit der Art `progress` in die Registratur ein.

Der vierte Schritt betrifft eine bestehende Klasse, denn ein Fortschrittsbalken wird auf einem Screen erzeugt. Der Screen-Adapter und der Screen-Stellvertreter brauchen deshalb je eine zusätzliche Methode `create_progress_bar`. Transport- und Kommunikationsschicht bleiben dagegen unberührt, da ein neuer Scope lediglich registriert und eine neue Methodenkennung beim Start indiziert wird.

Die Grenze der Erweiterbarkeit liegt damit im Objektmodell selbst. Ein neuer Objekttyp kostet drei neue Klassen und einen Eingriff in das erzeugende Objekt. Soll das neue Element außerdem Ereignisse liefern, kommt ein Rückruf bei der Anzeigebibliothek hinzu, wie ihn bisher nur Buttons anmelden.

== Ansteuerung der Anzeige <sec:ansteuerung>

Die Ansteuerung der Anzeige bildet auf dem Server die oberste Schicht aus @sec:architektur. Sie ist die einzige Stelle mit Kenntnis der Anzeigehardware und liegt in `display/server/driver`. Die Darstellung übernimmt @LVGL in der MicroPython-Anbindung @LvglLv_binding_micropython2026, die auch den Treiber für den Displaycontroller ILI9341 mitbringt. Das Display ist über @spi angebunden, der kapazitive Touchcontroller über @i2c.

Aufgebaut wird die Anzeige vom `ESPDisplayAdapter`, der die @i2c\-Verbindung öffnet, den Touchcontroller erzeugt und ihn dem Displaytreiber übergibt, welcher ihn als Zeigegerät bei @LVGL anmeldet. Anschließend reicht er das @LVGL\-Modul an die Adapter für Screens, Labels und Buttons weiter. Ausschließlich diese Adapter rufen @LVGL auf, während die Schichten darunter die Bibliothek nicht kennen.

Das Zeichnen ist von der Ausführung der Aufrufe getrennt. Der Treiber startet beim Initialisieren eine Ereignisschleife, die in festem Takt über einen Hardware-Timer den Task-Handler von @LVGL einplant, welcher geänderte Bereiche neu zeichnet und die Eingabegeräte abfragt. Gemessen liegt dieser Takt bei 40 ms, siehe @sec:reaktionszeit. Ein Adapter ändert somit lediglich den Zustand eines Objekts, beispielsweise den Text eines Labels, wobei die Änderung erst beim nächsten Durchlauf des Task-Handlers sichtbar wird. Ein Aufruf kann deshalb bereits abgeschlossen sein, bevor die Änderung auf dem Display erscheint.

Der Touchcontroller wird regelmäßig abgefragt, seine Interrupt-Leitung dagegen nicht genutzt. @LVGL ruft dazu bei jedem Durchlauf die Funktion `touch_read_cb` auf, die das Registerabbild des Controllers liest, wobei jede Abfrage eine @i2c\-Transaktion kostet, auch wenn keine Berührung vorliegt. Die Funktion darf zudem keine Ausnahme weitergeben, weshalb ein fehlgeschlagener Lesevorgang als fehlende Berührung gemeldet wird, wie @sec:nebenlaeufigkeit begründet.

Erkennt @LVGL eine Berührung auf einem Button, löst es ein Ereignis aus. Der Screen-Adapter registriert dafür beim Erzeugen eines Buttons die Methode `on_event` für die Ereignisse `PRESSED` und `RELEASED`. `on_event` ermittelt über die Registratur die Referenz des Buttons, übersetzt den Ereigniscode in einen Namen wie `press` und ergänzt einen Zeitstempel. Das Ergebnis wird im Ereignispuffer des Objekts abgelegt, aus dem der Client es wie in @sec:umsetzung-kommunikation beschrieben abfragt.

Der Puffer beantwortet zwei verschiedene Fragen, und beide werden in einem Aufruf beantwortet. Die erste ist der aktuelle Zustand, also ob ein Button gerade gedrückt ist. Dafür hält die Registratur das jüngste Ereignis getrennt vor, das eine Abfrage überdauert. Die zweite ist, was seit der letzten Abfrage geschehen ist. Dafür wird der Puffer beim Abfragen geleert und die Anzahl der Betätigungen gezählt. Ohne diese Trennung ginge eine kurze Berührung verloren, die vor der nächsten Abfrage schon wieder beendet ist, weil dann nur noch das Loslassen im Puffer stünde. Da eine Abfrage einen vollständigen Aufruf kostet, ist dieser Fall der Normalfall und nicht die Ausnahme.

Vor dem Ablegen prüft `on_event`, ob für das Ereignis ein Binding besteht. Ein Binding legt fest, dass ein Ereignis auf einem Objekt eine Aktion auf einem anderen auslöst. Der Client legt es einmal mit einem gewöhnlichen Aufruf an. Danach führt der Server die Aktion direkt im Rückruf aus, ohne dass eine Übertragung nötig ist. Das Ereignis wird unabhängig davon gepuffert und steht der nächsten Abfrage zur Verfügung. Der Client erfährt von der ausgeführten Aktion selbst jedoch nichts. Welcher Screen gerade angezeigt wird, weiß er nur, solange er die Ereignisse regelmäßig abfragt und die Bindings selbst nachhält.

#figure(
  caption: [Aktionen, die an ein Ereignis gebunden werden können],
  table(
    columns: (auto, auto, 1fr),
    align: left + top,
    table.header([*Wert*], [*Name*], [*Wirkung auf das Ziel*]),
    [`0x1`], [ACT_SHOW_SCREEN], [Screen laden und anzeigen],
    [`0x2`], [ACT_SHOW],        [Objekt sichtbar machen],
    [`0x3`], [ACT_HIDE],        [Objekt verbergen],
    [`0x4`], [ACT_TOGGLE],      [Sichtbarkeit umkehren],
  ),
) <tab:aktionen>

Die Menge der Aktionen ist absichtlich klein und fest vorgegeben, da sie weder Bedingungen noch Zustand oder Berechnungen enthält. Bindings bleiben somit auf Reaktionen beschränkt, die lediglich die Darstellung betreffen, beispielsweise den Wechsel zwischen zwei Screens, während die Logik der Anwendung weiterhin auf dem Client liegt. Unbekannte Aktionen weist `bind` ebenso zurück wie Referenzen, die veraltet sind oder die falsche Art haben (@sec:objektmodell).

== Ablauf eines vollständigen Aufrufs

Nachdem die vorigen Abschnitte die Schichten einzeln beschrieben haben, verfolgt dieser Abschnitt einen einzelnen Aufruf durch alle Schichten. Als Beispiel dient folgende Zeile

```python
counter_label.set_text("Counter: {}".format(counter))
```

aus dem Beispielprogramm des Hubs (siehe @lst:beispielprogramm). Sie ändert den Text eines Labels und liefert keinen Rückgabewert, wobei der Einfachheit halber `counter = 42` angenommen wird. 

*Aufruf auf dem Client.* `counter_label` ist ein Stellvertreter vom Typ `Label`, dessen Methode `set_text` zunächst prüft, ob er zur aktuellen Session gehört, und den Aufruf anschließend an `PyBricksInterceptor.call()` übergibt. Die Referenz des Labels wird dabei den Argumenten vorangestellt. Die Kommunikationsschicht bildet daraus einen `CommandPayload` mit dem Scope `label`, der Methodenkennung von `set_text` und der Argumentliste aus Referenz und Text, wobei die Nachricht die nächste freie Kennung erhält.

*Zerlegung.* MessagePack kodiert diese Nutzlast in 32 Byte, die bei 13 Byte Nutzlast je Frame nach @eq:blöcke in drei Frames zerfallen. Die ersten beiden tragen `DATA`, der letzte `DATA_LAST` mit den verbleibenden sechs Byte. 

*Übertragung.* Der Client sendet jeden Frame einzeln und wartet auf dessen Bestätigung. Jeder Austausch ist ein Aufruf von `remote.call` und damit ein Round Trip über den Bus. Stimmen Position oder Art der Antwort nicht, war die Antwort veraltet oder der Frame ist verloren gegangen, und der Client wiederholt seine letzte Übertragung. Der Server legt jeden neuen Frame ab und bestätigt ihn sofort. Mit dem letzten Frame setzt er die Nutzlast zusammen und startet die Ausführung als eigenen Task der Ereignisschleife. Der letzte Frame wird bestätigt, bevor der Aufruf ausgeführt wird.

*Ausführung.* Der Task dekodiert die Nutzlast, wählt über den Scope den Label-Adapter aus und schlägt dort die Methodenkennung nach. `set_text` löst die Referenz in der Registratur auf, prüft dabei Generation und Art und setzt den Text des @LVGL\-Objekts. Sichtbar wird der neue Text erst beim nächsten Durchlauf des Task-Handlers, wie in @sec:ansteuerung beschrieben wurde. Das Ergebnis `None` wird als `DataPayload` kodiert, das der Server anschließend unter der Kennung im Ausgangspuffer ablegt.

Ein sofortiges Neuzeichnen im Adapter wäre möglich, würde aber die Ereignisschleife für die Dauer der Übertragung zum Display blockieren und damit auch die Bearbeitung weiterer Frames verzögern.

*Abholen.* Der Client fragt mit `READY` nach, ob das Ergebnis bereitliegt. Ob ein Ergebnis schon beim ersten Versuch vorliegt, hängt davon ab, ob die Ereignisschleife des Servers den Task bis dahin ausgeführt hat. Antwortet der Server mit `NACK`, wartet der Client 50 ms und fragt erneut. Auf `DONE` folgt eine Anfrage `NEXT` für Position 0, die den einzigen Ergebnisframe liefert, gekennzeichnet mit `DATA_LAST`, womit der Abholprozess endet. 

*Rückgabe.* Der Client dekodiert die Nutzlast und gibt den Rückgabewert `None` an den Aufrufer zurück, falls das Ergebnis nicht als Fehler gekennzeichnet ist. Andernfalls löst er die passende Ausnahme aus, wie in @sec:objektmodell beschrieben.

Dieser Aufruf kostet damit mindestens fünf Round Trips. Nur drei davon transportieren den eigentlichen Aufruf mit seiner Nutzlast, während mindestens zwei weitere nur Steuerinformationen tragen und das Ergebnis abholen. Wie viele Round Trips in der Praxis nötig sind, misst @sec:evaluation. 

Das Aufrufschema folgt somit der in @sec:interceptor beschriebenen Abfolge. Das Sequenzdiagramm @abb:interceptor zeigt die generischen Abläufe, die hier mit einem konkreten Beispiel gefüllt wurden. Die Abbildung zeigt auch die beiden Round Trips, die der Client für das Abholen des Ergebnisses benötigt. 

=== Zustände eines Aufrufs <sec:automat>

Der beschriebene Ablauf lässt sich für beide Seiten als Zustandsautomat
angeben. Das ist genauer als eine Beschreibung im Fließtext, weil sich damit
auch die Fälle festhalten lassen, die im Beispiel nicht vorkommen, also
ausbleibende Bestätigungen, veraltete Antworten und abgebrochene Übertragungen.
Eine Kante nennt jeweils den eintreffenden Frame und, nach dem Schrägstrich, die
Reaktion darauf.

#figure(
  image("../figures/automat_client.svg", width: 100%),
  caption: [Zustände eines Aufrufs auf dem Client],
) <abb:automat_client>

@abb:automat_client zeigt den Client. Zwischen dem Verlassen von `Senden` und
dem Eintreffen von `DONE` ist die Anwendung blockiert, und es ist stets nur ein
Aufruf unterwegs. Jeder der drei Zustände `Senden`, `Warten` und `Abholen`
besitzt eine eigene Obergrenze, nach deren Überschreiten der Aufruf in
`Fehler` übergeht und die Anwendung eine Ausnahme erhält. Damit ist die
Zusicherung aus @sec:zuverlaessigkeit auch dann eingehalten, wenn die Gegenseite
gar nicht mehr antwortet.

#figure(
  image("../figures/automat_server.svg", width: 88%),
  caption: [Zustände eines Aufrufs auf dem Server, je Nachrichtenkennung],
) <abb:automat_server>

@abb:automat_server zeigt den Server. Zwei Kanten sind dort die eigentlichen
Zusicherungen. Eine bereits bekannte Position wird bestätigt, aber nicht erneut
abgelegt, und ein wiederholter letzter Frame wird bestätigt, ohne den Aufruf ein
zweites Mal auszuführen. Zusammen ergibt das die in @sec:zuverlaessigkeit
beschriebene At-most-once-Semantik. Der Übergang von `Ergebnis bereit` zurück
nach `Empfangen` ist der Punkt, an dem eine wiederverwendete Kennung ihren
alten Eintrag verwirft, was @sec:zuordnung begründet.

Der Automat zeigt zugleich eine Lücke dieses Stands. Ein Frame an Position 0, der
zugleich der letzte ist, führt aus `Ergebnis bereit` erneut nach `Ausführen`,
da der Server die Kennung nicht mit der zuletzt empfangenen vergleicht. Wird
eine Nachricht aus einem einzigen Frame nach einer veralteten Antwort
wiederholt, führt er den Aufruf deshalb ein zweites Mal aus. Die Anwendung kann
diesen Fall nicht auslösen, da mit der eingesetzten Kodierung schon der kürzeste
Aufruf 18 Byte lang ist und zwei Frames belegt. Bei einem kürzeren Scope-Namen
oder einem anderen Codec wäre er aber erreichbar. Eine Wiederholung des letzten
Frames an einer späteren Position ist dagegen unkritisch, da diese Position
bereits bekannt ist. Spätere Stände schließen die Lücke mit dem Vergleich der
Kennung, den @sec:fragmentierung beschreibt.

== Nebenläufigkeit und Fehlerbehandlung <sec:nebenlaeufigkeit>

Die bisherigen Abschnitte beschreiben den Ablauf eines Aufrufs, der gelingt. Dieser Abschnitt behandelt, wie die Aufgaben auf dem Server nebeneinander laufen und wie Fehler behandelt werden.

=== Nebenläufigkeit

Auf dem Client gibt es keine Möglichkeit zur Nebenläufigkeit, sodass ein Aufruf die Anwendung blockiert, bis das Ergebnis vorliegt oder eine Obergrenze erreicht ist. Da immer nur ein Aufruf gleichzeitig unterwegs ist, braucht der Client weder Sperren noch Puffer für mehrere offene Aufrufe.

Auf dem Server laufen dagegen drei Tasks nebenläufig. Ein Task ruft etwa jede Millisekunde `process` von PUPRemote auf und beantwortet damit die Anfragen des Clients. @LVGL zeichnet außerdem in einem festen Takt die Anzeige neu und fragt den Touchcontroller ab. Schließlich läuft jeder empfangene Aufruf in einem eigenen Task. Alle drei teilen sich eine einzige Ereignisschleife von `uasyncio` und damit einen Thread, weshalb sie sich nur an festen Stellen abwechseln, beispielsweise beim Warten eines der anderen Tasks. Dieses Vorgehen ist für speicherbeschränkte Geräte üblich, weil es den Stack je Aufgabe einspart, den ein eigener Thread benötigt @ProtothreadsSimplifyingEventdriven2026.

Die Ausführung von Aufrufen lief in einer früheren Version in einem eigenen Thread. Das führte zu zwei Fehlern. Der Stack eines Threads wird vom Heap genommen, den @LVGL bereits zum großen Teil belegt. Nach einigen Dutzend Aufrufen ließ sich deshalb kein neuer Thread mehr anlegen. Außerdem ist @LVGL nicht reentrant @TimerLv_timerLVGL, und der Task-Handler der Bibliothek lief teilweise im Thread mit seinem kleineren Stack. Dort lief der Stack im Rückruf des Touchcontrollers über. Mit einer gemeinsamen Ereignisschleife treten beide Fehler nicht mehr auf, da nie zwei Stellen gleichzeitig auf @LVGL zugreifen.

Der Preis dafür ist, dass die Ereignisschleife während der Ausführung eines Aufrufs belegt ist. Anfragen des Clients werden in dieser Zeit nicht beantwortet, und die Anzeige wird nicht neu gezeichnet. Da der Client ohnehin auf das Ergebnis wartet, ist das hier unkritisch.

=== Fehlerbehandlung

Fehler werden in der Schicht behandelt, in der sie auftreten, und gelangen nach oben nur, wenn die Schicht sie nicht selbst behandeln kann. @tab:fehler fasst die Fälle zusammen.

#figure(
  caption: [Fehlerfälle und ihre Behandlung],
  text(size: 9pt)[
    #table(
      columns: (1.2fr, 0.8fr, 1.6fr),
      align: left + top,
      table.header([*Fehler*], [*Schicht*], [*Behandlung*]),
      [Veraltete Antwort oder verlorene Bestätigung], [Transport], [Frame erneut senden, höchstens acht Versuche],
      [Wiederholter Frame auf dem Server], [Transport], [bestätigen, aber nicht erneut ablegen, außer bei Nachrichten aus einem Frame],
      [Abgebrochene Übertragung], [Transport], [Reste verwerfen, sobald Frame Nr. 0 einer neuen Nachricht eintrifft],
      [Nachricht länger als 255 Frames], [Transport], [Aufruf scheitert auf dem Client, bevor etwas gesendet wird],
      [Ganzzahl außerhalb von 16 Bit im Argument], [Transport], [`OverflowError` auf dem Client, bevor etwas gesendet wird],
      [Ganzzahl außerhalb von 16 Bit im Ergebnis], [Transport], [Aufruf ist ausgeführt, Fehlermeldung an den Client, `RemoteError`],
      [Ergebnis bleibt aus], [Kommunikation], [nach 5000 ms Ausnahme auf dem Client],
      [Unbekannter Scope oder Methodenkennung], [Kommunikation], [Fehlermeldung an den Client, `RemoteError`],
      [Veraltete Referenz oder falsche Art], [Objektmodell], [Fehlermeldung mit Fehlerart `StaleReferenceError` oder `WrongKindError`],
      [Ausnahme in einer Methode des Adapters], [Objektmodell], [Fehlermeldung an den Client, `RemoteError`],
      [Verbindungsabbruch], [Busanbindung], [Session beenden, `OSError` an die Anwendung],
      [Fehler beim Lesen des Touchcontrollers], [Anzeige], [als fehlende Berührung werten],
    )
  ],
) <tab:fehler>

@sec:automat zeigt die folgenden Fälle als Zustandsübergänge, dieser Abschnitt ordnet sie den Schichten zu.

Die Transportschicht muss mit veralteten Antworten rechnen. Da der Client direkt nach dem Schreiben auch liest, kann er die Antwort auf die vorherige Anfrage erhalten, wenn der Server den Frame bis dahin nicht verarbeitet hat. Wie selten das im Betrieb vorkommt, zeigt @sec:evaluation. Der Client erkennt sie an Position und Art des Frames und sendet diesen anschließend erneut.

Die Kennung wertet er dabei nicht aus, obwohl @sec:frame-struktur sie als das Mittel benennt, an dem eine veraltete Antwort erkennbar wird. Sie adressiert in der Umsetzung nur die Anfrage nach dem Ergebnis, das der Client unter der Kennung seines Aufrufs anfordert. Für die Bestätigungen genügen Position und Art, solange der Client streng nacheinander sendet und auf jede Bestätigung wartet, denn eine veraltete Antwort gehört dann zum vorangegangenen Frame und trägt dessen Position. Offen bleibt der Fall, in dem beide Frames dieselbe Position tragen, etwa Frame 0 zweier aufeinanderfolgender Aufrufe. Solange eine Bestätigung nichts weiter transportiert, hat das keine Folgen. @sec:bestaetigung greift die Prüfung dort auf, wo sie nötig wird. Der Server bestätigt eine Wiederholung, legt den Frame aber kein zweites Mal ab. Das gilt auch für den letzten Frame einer Nachricht, sofern sie mehr als einen Frame umfasst, wie @sec:automat ausführt. Würde dieser bei einer Wiederholung die Ausführung erneut starten, liefe derselbe Aufruf zweimal, beim zweiten Mal mit einer leeren Nachricht. Erst wenn eine Obergrenze aus @tab:rückkanal erreicht ist, gibt der Client auf und löst eine Ausnahme aus, die den betroffenen Frame und den Aufruf nennt.

Für den Server gilt die Zusicherung aus @sec:zuverlaessigkeit, nach der jeder Aufruf ein Ergebnis oder eine Fehlermeldung hinterlässt. Jede Ausnahme bei der Ausführung wird abgefangen und als `ErrorPayload` im Ausgangspuffer abgelegt. Lässt sich selbst das Ergebnis nicht kodieren, legt er eine kurze Fehlermeldung ab. Anfragen, die der Server nicht zuordnen kann, beantwortet er mit einem Frame der Art `ERR`, etwa wenn nach dem Ergebnis einer unbekannten Nachricht gefragt wird.

Ein Verbindungsabbruch zeigt sich auf dem Client als `OSError: [Errno 19] ENODEV:` von PUPRemote. Der Client beendet dann die Session, da der Server in der Zwischenzeit neu gestartet sein kann, und reicht den Fehler an die Anwendung weiter. Ob sie es erneut versucht oder die Oberfläche neu aufbaut, entscheidet die Anwendung. Alle Stellvertreter aus der alten Session melden danach `StaleReferenceError`, wie @sec:objektmodell beschreibt.

Eine Stelle darf gar keinen Fehler weitergeben, nämlich der Rückruf, mit dem @LVGL den Touchcontroller abfragt. Eine Ausnahme dort beendet die Ereignisschleife von @LVGL dauerhaft, sodass die Anzeige nicht mehr neu gezeichnet würde, obwohl weiterhin Aufrufe ankommen. Ein fehlgeschlagener Lesevorgang wird deshalb als nicht vorhandene Berührung gewertet. Die Anwendung kann das nicht erkennen, da sie keinen Zugriff auf den Touchcontroller hat und nur die Ereignisse abfragen kann, die @LVGL aus der Abfrage erzeugt.