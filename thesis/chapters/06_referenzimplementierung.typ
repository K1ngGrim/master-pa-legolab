= Referenzimplementierung <sec:referenzimplementierung>

== Laufzeitumgebung <sec:laufzeitumgebung>

Client und Server laufen beide unter MicroPython, allerdings in sehr unterschiedlichen Ausprägungen.

Auf dem Hub läuft Pybricks @Pybricks. Die Firmware ersetzt die Software von LEGO und stellt eine stark reduzierte Variante von MicroPython bereit. Für die Umsetzung sind vier Einschränkungen von Bedeutung. Ganzzahlen sind auf $2^30 - 1$ begrenzt, da die Firmware ohne Unterstützung für lange Ganzzahlen übersetzt ist. Schon eine größere Konstante im Quelltext verhindert das Laden des Moduls. Threads stehen nicht zur Verfügung, ebenso wenig einige Teile der Standardbibliothek wie `memoryview` oder das Modul `warnings`. Außerdem nimmt der Hub nur einzelne Dateien an, keine Pakete mit Unterverzeichnissen.

Grund für die alternative Firmware sind die Einschränkungen von LEGO. Der Hub ist ein geschlossenes System, das nur die von LEGO bereitgestellten Sensoren und Aktoren akzeptiert. Erst die Pybricks-Firmware @Pybricks erlaubt die Anbindung externer Geräte, jedoch auch nur durch die bereitgestellte Schnittstelle LPF2 und PupRemote @PUPRemoteDocumentationAntons @LMSESP32V20Clever2023.

Die Module der Middleware liegen dagegen in einer Paketstruktur. Ein eigenes Werkzeug, der Bundler in `tools/bundler.py`, führt deshalb alle Module, die der Client benötigt, zu einer einzigen Datei `pybricks_bundle.py` zusammen. Er löst die Importe innerhalb des Projekts auf, sortiert die Module so, dass jedes nach seinen Abhängigkeiten steht, und ersetzt dabei `struct` durch das auf dem Hub vorhandene `ustruct`. Das Anwendungsprogramm auf dem Hub importiert anschließend nur noch diese Datei.

Auf dem ESP32 läuft MicroPython mit der Anbindung an @LVGL. Diese Umgebung ist deutlich umfangreicher. Sie bietet lange Ganzzahlen, Threads, `uasyncio` und einen Zufallszahlengenerator. Knapp ist hier vor allem der Arbeitsspeicher, da @LVGL einen großen Teil des Heaps für die Darstellung belegt. Welche Folgen das für die Nebenläufigkeit hat, beschreibt @sec:nebenlaeufigkeit.

Der gemeinsame Code muss in beiden Umgebungen laufen und richtet sich deshalb nach der engeren, also nach Pybricks. Das betrifft vor allem die Transportschicht, den Codec und die Stellvertreter. Code, der nur auf dem Server läuft, darf die Möglichkeiten des ESP32 nutzen. @tab:zuordnung ordnet die Module den Schichten aus @sec:architektur zu.

@tab:zuordnung ordnet die Module der Referenzimplementierung den Schichten aus @sec:architektur zu.
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

== Hardwareaufbau <sec:hardwareaufbau>

// SCOPE: bewusst knapp gehalten. Die Arbeit ist eine Informatikarbeit; der
// Hardwareaufbau dokumentiert einen funktionsfaehigen Traeger fuer die
// Software, er ist kein eigener Beitrag. Diese Abgrenzung gleich zu Beginn
// aussprechen - ein Abschnitt, der seinen Umfang selbst benennt, wird auch
// nicht an einem groesseren Massstab gemessen.
//
// Leitlinie fuer alle Entscheidungen: jeweils die einfachere Variante.
// Fertige Baugruppen statt eigener Schaltungsentwicklung, ESP32 als Modul
// statt bestuecktem Chip, handelsuebliches Displaymodul statt Panel.
// Bewertung steht in Kap. 7.4, nicht hier.
//
// Es gibt nur eine Ausbaustufe, die Adapterplatine. Die urspruenglich
// geplante integrierte Traegerplatine wurde aus Zeitgruenden nicht gebaut
// und steht als Erweiterung in Kap. 8.3.

=== Aufbau und Komponenten

// - Verweis auf 3.1.2: warum externe Hardware ueberhaupt noetig ist
// - Drei Baugruppen und ihre Rollen: ESP32-Board, Displaymodul, Verbindung
// - Abgrenzung: funktionsfaehiger Aufbau mit handelsueblichen Baugruppen,
//   ausdruecklich keine eigene Schaltungsentwicklung, keine Serienreife
//   (EMV, Zulassung, Fertigungstoleranzen)
// - Busanbindung signalseitig nur UART auf zwei GPIOs, 3,3-V-Logik
// - Versorgung: 8 V auf M+ werden per power=True angefordert; Nebeneffekt
//   ist die Verkuerzung zulaessiger Modusnamen von 11 auf 5 Zeichen, was
//   die Kommandonamen des Protokolls begrenzt (siehe Kap. 3.4.2)

=== Signalzuordnung und Aufbau der Adapterplatine

// Verbindet nur, entwirft nichts neu. Beide Baugruppen aufsteckbar,
// moeglichst ohne aktive Bauteile.
// - Tabelle: Funktion -> ESP32-Pin -> Displaymodul-Pin
// - SPI (MOSI, SCK, CS, DC, RST, Backlight), I2C fuer Touch (SDA, SCL, INT),
//   SD-Karte (CS, ggf. geteilter SPI-Bus), Bus (TX, RX)
// - Konflikte im Pin-Budget und wie sie aufgeloest wurden
// - Schaltplan, Steckerwahl, Bauhoehe, Fertigungsweg, Erstinbetriebnahme

== Busanbindung <sec:busanbindung>

Die Busanbindung wird nicht entworfen, sondern vorgefunden. Beide Seiten verwenden PUPRemote @PUPRemoteDocumentationAntons, auf dem Hub als `PUPRemoteHub` und auf dem ESP32 als `PUPRemoteSensor`. Die Bibliothek setzt das @lpf2\-Protokoll um, über das der Hub mit angeschlossenen Sensoren kommuniziert.

Gegenüber dem Hub gibt sich der ESP32 als Ultraschallsensor aus, da der Hub nur Geräte mit bekannter Kennung annimmt. Beim Verbindungsaufbau handeln beide Seiten zunächst bei 2400 Baud die Eigenschaften des Geräts aus und wechseln anschließend auf 115200 Baud. Danach überwacht die Bibliothek die Verbindung selbstständig und baut sie nach einem Abbruch neu auf. Zusätzlich fordert der ESP32 die 8-V-Versorgung am Port an, da das Display mehr Strom benötigt, als die Logikversorgung liefert.

PUPRemote bildet benannte Kommandos auf die Modi des Busses ab und bringt dafür eine eigene Aufrufsemantik mit festen Formaten je Kommando mit. Diese wird hier nicht genutzt. Registriert ist ein einziges Kommando `xfer`, dessen Format in beide Richtungen ein Block von 16 Byte ist. Für PUPRemote hat dieser Block keine Struktur. Alles Weitere liegt in den Schichten darüber.

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

Ein Austausch im Sinne von @sec:interceptor ist auf dem Hub ein Aufruf von `remote.call`. Dabei wird der Block in den Modus des Kommandos geschrieben und anschließend der Inhalt desselben Modus zurückgelesen. Zwischen beidem wartet die Bibliothek nicht, sofern keine Wartezeit angegeben ist. Hat der ESP32 den Block bis zum Lesen noch nicht verarbeitet, liefert der Lesevorgang die vorige Antwort. Solche veralteten Antworten erkennen die darüberliegenden Schichten an Kennung, Position und Art des Frames, wie in @sec:zuverlaessigkeit beschrieben.

Auf dem ESP32 ruft ein Task der Ereignisschleife etwa jede Millisekunde `process` auf, wobei je Durchlauf höchstens ein Kommando bearbeitet wird. Für jedes eintreffende Kommando ruft PUPRemote den registrierten Rückruf auf. Die Bibliothek findet ihn, indem sie den Kommandonamen im Namensraum des Hauptprogramms auswertet. Das Hauptprogramm muss den Rückruf deshalb unter dem Namen `xfer` bereitstellen.

Zwei Grenzen der Busanbindung wirken sich auf den gesamten Entwurf aus. Die Blockgröße ist mit der Firmware des Hubs auf 16 Byte begrenzt, darüber treten Prüfsummenfehler auf. Außerdem dürfen Kommandonamen bei angeforderter 8-V-Versorgung höchstens fünf Zeichen lang sein. Oberhalb dieser Schicht ist davon nur noch die Blockgröße sichtbar, und zwar als Zahl, aus der @sec:umsetzung-transport die Nutzlast ableitet.

== Transportschicht <sec:umsetzung-transport>

=== Frame

Die Blockgröße ist durch die Busanbindung vorgegeben. Die Firmware des Hubs begrenzt einen Modus auf 16 Byte. Damit steht die in @sec:nutzlastlaenge eingeführte @mtu fest, und alle weiteren Größen leiten sich daraus ab.

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

Für die Nutzlast verbleiben damit 13 Byte je Frame.

Diese Aufteilung erfüllt die Bedingungen aus @sec:nutzlastlaenge. Bei einem Header von drei Byte ergibt @eq:payload eine Nutzlast von 13 Byte, und @eq:laengenfeld verlangt dafür ein vier Bit breites Längenfeld. Die obere Hälfte des dritten Bytes enthält die Art des Frames, die untere Hälfte die Länge der Nutzlast. Das Längenfeld vergrößert den Header damit nicht. Ein Header von zwei Byte wäre nur möglich, wenn Kennung oder Position schmaler ausfielen. Das würde die Anzahl unterscheidbarer Nachrichten oder die maximale Nachrichtenlänge verringern.

@tab:frame_from_bytes zeigt die Umwandlung von Bytes in einen Frame. Dabei wird auch eine zu kurze Eingabe abgefangen und das dritte Byte in Art und Länge aufgeteilt.

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

Gültig bleibt die Aufteilung, solange die Nutzlast 15 Byte nicht überschreitet, da das Längenfeld keine größeren Werte darstellen kann. Bei einem Header von drei Byte entspricht das einer Blockgröße von höchstens 18 Byte. Größere Blöcke würden ein Längenfeld von einem vollen Byte und damit einen Header von vier Byte erfordern. @tab:frame_to_bytes zeigt die umgekehrte Umwandlung eines Frames in Bytes, bei der eine zu lange Nutzlast abgewiesen wird.

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

Die Position hat durch ihre Breite von acht Bit einen Wertebereich von 0 bis 255. Der Wert `0xFF` ist für Frames reserviert, die sich auf keine Position innerhalb einer Nachricht beziehen. Für Nutzlastframes stehen damit 255 Werte zur Verfügung, was die Länge einer Nachricht auf $13 dot 255 = 3315$ Byte begrenzt. Dieser Wert ist zugleich die nach K5 geforderte Obergrenze des Puffers.

Für die Art des Frames sind von 16 darstellbaren Werten acht belegt (siehe @tab:opcodes). Acht Werte kämen gerade noch mit drei Bit aus, allerdings bliebe dann kein Wert für eine weitere Art frei. Das eingesparte Bit würde außerdem nichts bringen. Im Längenfeld könnte es Werte bis 31 darstellen, obwohl die Nutzlast 13 Byte nie überschreitet. In der Position würde es über die Bytegrenze hinausreichen und Bitoperationen über zwei Byte erfordern. Die Breite von vier Bit ist daher eine pragmatische Entscheidung.

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

Die Zerlegung ist als Funktion über Position und Nutzlast umgesetzt. In einer früheren Version lieferte ein Generator die Frames nacheinander. Diese Variante wurde verworfen, da sie das Wiederholen einzelner Frames erschwerte.

@tab:message_frames berechnet den zugehörigen Abschnitt direkt aus dem Index, ohne einen Fortschritt mitzuführen. Dieselbe Position liefert damit immer denselben Frame, wie es @sec:fragmentierung fordert. Der Rückkanal ist darauf angewiesen, da er Ergebnisframes einzeln über ihre Position anfordert und dieselbe Position mehrfach anfragen kann.

#figure(
  caption: [Funktion zur Erzeugung von Frames aus einer Nachricht],
  ```python
  def frame_at(self, index: int):
    if index < 0:
        return None

    start = index * PAYLOAD_SIZE
    if start >= len(self.payload) and not (index == 0 and not self.payload):
        return None

    chunk = self.payload[start:start + PAYLOAD_SIZE]
    last = start + PAYLOAD_SIZE >= len(self.payload)

    return Frame(
        g_id=self.g_id,
        frame_nr=index % 256,
        opcode=OP_DATA_LAST if last else OP_DATA,
        payload=chunk,
    )
  ```
)<tab:message_frames>

Für das Einsammeln eingehender Frames gibt es zwei Wege, die sich in Speicherbedarf und Zusicherung unterscheiden. `collect_frame` behält jeden Frame, bis die Nachricht vollständig ist, und sortiert die Frames nach ihrer Position. Diese Variante ist von der Reihenfolge der Ankunft unabhängig, hält aber alle Frames einer Nachricht gleichzeitig im Speicher. `append_frame` hängt die Nutzlast direkt an und verwirft den Frame. Das spart Speicher, setzt aber die richtige Reihenfolge voraus. `get_payload` liefert in beiden Fällen die vollständige Nutzlast.

Der Rückkanal verwendet den sammelnden Weg, der Hinweg den anhängenden. Die in @sec:fragmentierung beschriebene Unabhängigkeit von der Reihenfolge ist damit nur auf dem Rückkanal umgesetzt. Für den hier betrachteten Bus genügt das, da er sequenziell arbeitet. Bei einem Übertragungsweg, der umsortiert, müsste auch der Hinweg auf den sammelnden Weg wechseln.

=== Serialisierung

#figure(
  image("../figures/codec.png", width: 50%),
  caption: [Klassendiagramm des Codecs],
) <abb:codec_interface>

Die Wahl des Formats ist an einer Stelle gebündelt. Ein `Codec` legt zwei Operationen fest. `encode` wandelt ein Python-Objekt in Bytes um, `decode` wandelt Bytes wieder in ein Python-Objekt um. @abb:codec_interface zeigt die Schnittstelle des Codecs, ihre zwei Umsetzungen in der Referenzimplementierung und die Stellen, an denen sie verwendet werden. Eine Umsetzung muss dabei nur eine Bedingung erfüllen. Ein Wert muss nach dem Kodieren und anschließenden Dekodieren unverändert zurückkommen. Formal lässt sich das als

$ op("decode") compose op("encode") = op("id")_D $ <eq:roundtrip>

ausdrücken. Das Zeichen $compose$ bezeichnet die Hintereinanderausführung, wobei die rechte Funktion zuerst angewendet wird. $op("id")_D$ ist die Identität auf der Menge $D$, also die Funktion, die jeden Wert unverändert zurückgibt. Die Formel besagt damit, dass Kodieren und anschließendes Dekodieren für jeden Wert aus $D$ dasselbe Ergebnis liefert wie gar keine Umwandlung.

$D$ umfasst dabei nur die Werte, die das jeweilige Format unterstützt. Für die hier eingesetzte MessagePack-Umsetzung sind das Wahrheitswerte, Ganzzahlen im Bereich von 16 Bit, Zeichenketten, Bytefolgen sowie Listen und Abbildungen über diesen Typen. Außerhalb von $D$ gilt die Eigenschaft nicht, ein Tupel etwa kommt als Liste zurück. Die Umkehrung gilt ebenfalls nicht, da sich derselbe Wert auf mehrere Arten kodieren lässt und eine fremde Bytefolge deshalb nicht zwingend unverändert zurückkommt.

Die MessagePack-Umsetzung deckt bewusst nur den Teil des Formats ab, den das System tatsächlich austauscht. Fließkommazahlen fehlen ebenso wie die Erweiterungstypen des Formats. Übertragen werden Pixelkoordinaten, Objektreferenzen und kurze Texte, und jeder weggelassene Typ verkleinert den Decoder, der auf beiden Seiten läuft. Das ist das dritte Kriterium aus @sec:serialisierung, angewandt auf die konkrete Umsetzung.

Enger als im Format vorgesehen ist auch der Wertebereich der Ganzzahlen. Er endet bei 16 Bit, obwohl MessagePack auch 32 und 64 Bit kennt. Der Grund liegt in der Laufzeitumgebung des Hubs. Sie ist ohne Unterstützung für lange Ganzzahlen übersetzt, sodass sich dort keine Konstante oberhalb von $2^30 - 1$ darstellen lässt. Die Zweige des Encoders für größere Werte enthielten solche Konstanten und verhinderten das Laden des gesamten Moduls, unabhängig davon, ob je ein so großer Wert übertragen wird. Für die hier auftretenden Werte reichen 16 Bit aus.

Welcher Codec verwendet wird, legt eine einzige Zuweisung fest. Möglich ist dieser Wechsel nur, weil die Rahmung die Länge der Nutzlast ausdrücklich mitführt. Die binäre Kodierung erzeugt Nullbytes, und ohne Längenfeld würde das Abschneiden von Füllbytes Teile der Nutzlast entfernen.

Zusätzlich steht ein JSON-Codec zur Verfügung. Er ist bei der Fehlersuche hilfreich, da ein mitgeschnittener Frame seine Nutzlast dann im Klartext zeigt. Wie sich die beiden Formate auf die Anzahl der Übertragungen auswirken, vergleicht @sec:evaluation.

== Kommunikationsschicht <sec:umsetzung-kommunikation>

Die Kommunikationsschicht ist auf beide Seiten verteilt. Auf dem Client, also dem Hub, bildet `PyBricksInterceptor.call()` einen Methodenaufruf auf eine Nachricht ab und wartet auf das Ergebnis. Auf dem Server, also dem ESP32, nimmt `MiddlewareInterceptor` die Nachricht entgegen, übergibt sie der Verteilung und legt das Ergebnis zur Abholung bereit. Beide Klassen übernehmen zugleich Aufgaben der Transportschicht, wie @tab:zuordnung zeigt. Die folgenden Abschnitte beschreiben nur den Teil, der zur Kommunikationsschicht gehört.

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

Die Schlüssel sind einbuchstabig. Die Argumente stehen als Liste in der Reihenfolge der Parameter, wie sie die gemeinsamen Schnittstellen in `display/protocol` festlegen. Die Methode wird durch eine Kennung von 16 Bit bezeichnet, die @lst:name_hash aus ihrem Namen berechnet.

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

Das Verfahren ist eine auf 16 Bit begrenzte Variante des bekannten djb2-Hashs. Die eingebaute Funktion `hash` ist dafür nicht verwendbar, da CPython ihr Ergebnis je Prozess zufällig verändert und MicroPython es anders berechnet. Die Maskierung nach jedem Schritt hält alle Zwischenwerte unter $2^30$. Das ist auf dem Hub aus demselben Grund nötig wie die Begrenzung der Ganzzahlen in @sec:umsetzung-transport. Ein gebräuchlicher 32-Bit-Hash wie FNV würde diese Grenze überschreiten.

Die Breite von 16 Bit ist eine Abwägung. MessagePack kodiert Werte bis 65535 in drei Byte, gegenüber 13 Byte für den Namen `create_label`. Eine Kennung von acht Bit wäre ein Byte kürzer, bei zehn Methoden in einem Scope läge die Wahrscheinlichkeit einer Kollision dann aber bei etwa 16,3 %. Eine Kollision liegt vor, wenn zwei verschiedene Methodennamen denselben Hashwert ergeben. Die Wahrscheinlichkeit dafür steigt mit der Anzahl der Methoden pro Scope. Die folgende Gleichung

$ P"Kollision" = 1 - product_(i=0)^(n-1) (1 - i / N) $ <eq:collision_probability>

schätzt die Wahrscheinlichkeit ab, dass bei $n$ Methoden in einem Scope und $N$ möglichen Kennungen mindestens zwei denselben Hashwert liefern. Sie ist nur eine Näherung, da sie gleichverteilte Hashwerte annimmt und djb2 nicht gleichverteilt ist. Nach @eq:collision_probability liegt die Wahrscheinlichkeit einer Kollision bei 16 Bit und zehn Methoden bei etwa 0,069 %, bei 20 Methoden bei etwa 0,29 % und bei 50 Methoden bei 1,852 %.

Kollisionen sind also möglich, werden aber beim Start des Servers erkannt. Der Server trägt dazu jede Methode in ein Dictionary ein, wobei der Hashwert als Schlüssel dient. Eine zweite Methode mit demselben Hashwert führt zu einer Ausnahme, die den Start verhindert. @lst:index_methods zeigt die Funktion, die die Indizierung vornimmt. Sie liegt in der Basisklasse `RPCDispatcher`, von der alle Empfänger erben. Die genaue Struktur beschreibt @sec:objektmodell.

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

Ergebnis und Fehler unterscheiden sich allein im Schlüssel. Der Client prüft, ob `e` vorhanden ist, und löst in diesem Fall eine Ausnahme aus. Welche Ausnahme das ist, bestimmt die Fehlerart unter `k`, wie @sec:objektmodell beschreibt. Antworten enthalten keinen Scope. Der Server braucht ihn zur Auswahl des Empfängers, eine Antwort geht dagegen immer an den einen Aufrufer zurück, der auf sie wartet.

=== Verteilung eingehender Aufrufe <sec:umsetzung-verteilung>

Die Zuordnung eines Aufrufs zur ausführenden Methode erfolgt in zwei Stufen. Zunächst wird anhand des Scopes ein Dispatcher ausgewählt. Zur Erinnerung: Der Scope benennt die Art des Empfängers, der den Aufruf ausführt, und wird im `CommandPayload` unter dem Schlüssel `s` mitgeführt. Die Dispatcher sind in einem `RPCDispatcherPool` registriert, wobei jeder einen eigenen Scope bedient. Die Registrierung erfolgt beim Start des Servers, und der Versuch, einen Scope ein zweites Mal zu belegen, löst eine Ausnahme aus.

Anschließend schlägt der ausgewählte Dispatcher die Methodenkennung aus `c` nach und ruft die Methode mit den Argumenten aus `a` auf. Dass diese Kennungen innerhalb eines Scopes eindeutig sind, prüft der Dispatcher beim Aufbau seines Index, wie @lst:index_methods zeigt.

Findet sich eine Kennung nicht im Index, löst der Dispatcher eine Ausnahme aus. Sie wird in eine Fehlermeldung überführt und erreicht den Client, womit die Zusicherung aus @sec:zuverlaessigkeit auch für Aufrufe gilt, die es nicht gibt.

Aufrufbar ist damit jede öffentliche Methode eines Adapters. Das ist enger als ein Zugriff über den bloßen Namen, bei dem auch Attribute wie die Registratur erreichbar wären, aber weiter gefasst als die gemeinsame Schnittstelle in `display/protocol`. Der Adapter für Screens etwa erbt die Rückrufe der Anzeigebibliothek, die ebenfalls im Index stehen. Für die betrachtete Punkt-zu-Punkt-Verbindung, in die kein Dritter Nachrichten einspeisen kann, ist das hinnehmbar. Bei mehreren Teilnehmern müsste der Index auf die Methoden der Schnittstelle beschränkt werden.

=== Rückkanal

Nach der Bestätigung des letzten Frames ist ein Aufruf zwar vollständig übertragen, aber noch nicht ausgeführt. Der Server muss das Ergebnis erst berechnen. Anschließend legt er es in einem Ausgangspuffer ab, bis der Client es abholt.

Das Abholen erfolgt über denselben anfragegetriebenen Kanal wie die Übertragung der Aufrufe. Der Client fragt in einem festen Intervall mit `READY` an, ob ein Ergebnis bereitliegt. Der Server antwortet mit `DONE`, wenn das der Fall ist, und sonst mit `NACK`. Liegt das Ergebnis vor, holt der Client es mit `NEXT` Frame für Frame ab, wobei jede Anfrage die Position des nächsten Frames angibt. Der Server beantwortet jede Anfrage mit `frame_at(index)`, sodass eine wiederholte Anfrage denselben Frame liefert. 

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
    [RESULT_POLL_MS], [50 ms], [Abstand zwischen zwei READY-Anfragen],
    [MAX_RESULT_WAIT_MS], [5000 ms], [Wartezeit, nach der ein Aufruf als gescheitert gilt],
    [MAX_FRAME_ATTEMPTS], [8], [Anfragen je Position, bevor das Abholen abbricht],
    [MAX_KEPT_RESULTS], [4], [Ergebnisse, die der Server zur Abholung bereithält],
    [MAX_EVENTS], [10], [gepufferte Ereignisse je Objekt],
  ),
) <tab:rückkanal>

Der Server behält nur die jüngsten Ergebnisse. Ältere werden verworfen, wodurch der Speicherbedarf nach K5 begrenzt bleibt. Da der Client streng nacheinander aufruft, fragt er ohnehin nur nach dem Ergebnis seines letzten Aufrufs. Ereignisse nutzen keinen eigenen Mechanismus. Der Server legt sie je Objekt in der Registratur ab und hält dort die letzten zehn vor, wobei bei Überlauf das älteste Ereignis verworfen wird. Abgefragt werden sie über einen gewöhnlichen Aufruf wie `is_button_pressed`, der das jüngste Ereignis zurückgibt. Jede Abfrage kostet damit einen vollständigen Aufruf mit Übertragung, Wartezeit und Abholung. Der Überlauf des Puffers wird der Anwendung nicht gemeldet. Das Verhalten ist damit zwar festgelegt, wie @sec:kommunikationsschicht es verlangt, für die Anwendung aber nicht erkennbar.

Wie viel Zeit ein Aufruf im Warten auf das Ergebnis verbringt, misst @sec:evaluation. Reaktionen, die ohne diesen Weg auskommen, weil der Server sie selbst ausführt, behandelt @sec:ansteuerung.

== Objektmodell <sec:objektmodell>

Das Objektmodell bildet die grafischen Elemente der Anzeige auf Objekte ab, die die Anwendung auf dem Hub wie lokale Objekte benutzt. Bildschirme, Beschriftungen und Schaltflächen heißen in der Umsetzung Screens, Labels und Buttons. Je Objekttyp gibt es eine Basisklasse in `display/protocol`. Sie wird auf dem Client von einem Stellvertreter erfüllt, der jeden Methodenaufruf weiterleitet, und auf dem Server von einem Adapter, der ihn ausführt. Die Adapter erben zusätzlich von `RPCDispatcher` und werden dadurch über ihren Scope erreichbar, wie @sec:umsetzung-verteilung beschreibt. Die Stellvertreter erben von `RemoteObject`, das die Referenz des Objekts hält und sie jedem Aufruf voranstellt. @abb:objektmodell zeigt diese Beziehungen beispielhaft.

#figure(
  image("../figures/objektmodell.png", width: 90%),
  caption: [Klassen des Objektmodells auf beiden Seiten],
) <abb:objektmodell>

=== Referenzen

Eine Referenz ist eine Ganzzahl von 16 Bit, die der Server beim Erzeugen eines Objekts vergibt. Sie besteht aus zwei Teilen. Die unteren zehn Bit bezeichnen einen Slot, also die Position des Objekts in der Tabelle der Registratur. Die oberen sechs Bit enthalten die Generation des Slots. Das ist ein Zähler, der bei jeder Freigabe des Slots um eins steigt. Dieses Verfahren ist als Generational Handle bekannt.

#figure(
  caption: [Auflösung einer Referenz in der Registratur],
  ```python
  def _slot(self, ref):
      index = ref & SLOT_MASK
      if index >= len(self._slots):
          return None
      slot = self._slots[index]
      if slot[2] is None or slot[0] != ref >> SLOT_BITS:
          return None
      return slot
  ```
) <lst:slot>

Ein Slot speichert neben dem Objekt und seiner Generation auch die Art des Objekts und die Referenz seines Parents. Die Art ist `screen`, `label` oder `button`. Jede Methode eines Adapters gibt beim Nachschlagen an, welche Art sie erwartet. Übergibt die Anwendung etwa die Referenz eines Screens an `set_text`, wird das erkannt, bevor auf das Objekt zugegriffen wird.

Zehn Bit erlauben 1024 gleichzeitig bestehende Objekte. Der Speicher des ESP32 ist schon bei deutlich weniger Objekten erschöpft, sodass diese Grenze in der Praxis nicht erreicht wird. Die Breite von 16 Bit folgt aus @sec:umsetzung-transport. Der Codec überträgt Ganzzahlen nur bis zu dieser Größe, und MessagePack kodiert eine Referenz damit in höchstens drei Byte. Eine Referenz in Textform wie `obj_12` belegt sieben Byte.

=== Lebenszyklus

Objekte entstehen immer innerhalb eines übergeordneten Objekts. Screens werden vom Display erzeugt, Labels und Buttons von einem Screen. Ein Button besteht auf dem Server aus zwei Objekten, dem Button selbst und dem Label für seine Beschriftung. Beide werden getrennt registriert, und der Stellvertreter auf dem Client erhält beide Referenzen. So lässt sich die Beschriftung über den Scope `label` ändern, ohne dass der Button-Adapter dafür eine eigene Methode braucht.

Die Registratur bildet dabei den Objektbaum der Anzeigebibliothek nach. Jeder Eintrag kennt seinen Parent, und `release_tree` gibt ein Objekt zusammen mit allen darin erzeugten Objekten frei. Das ist nötig, weil @LVGL beim Löschen eines Objekts auch dessen Kinder löscht. Ohne den Baum würden deren Einträge in der Registratur bestehen bleiben und auf nicht mehr vorhandene Objekte verweisen.

Gelöscht wird über die Methode `delete()`, die jeder Objekttyp anbietet. Der Adapter löscht zuerst das @LVGL\-Objekt und gibt danach die Einträge frei. Beim Freigeben entfallen auch die Ereignisse des Objekts und alle Bindungen, an denen es beteiligt ist. Den gerade angezeigten Screen kann die Anwendung nicht löschen. @LVGL legt nicht fest, was angezeigt wird, wenn der aktive Screen fehlt. Ein solcher Aufruf wird deshalb mit einem Fehler beantwortet.

`clear()` löscht alle Objekte auf einmal. Die Registratur allein zu leeren genügt dafür nicht, da @LVGL die Objekte in einem eigenen Baum hält und sie nicht freigibt, wenn die letzte Python-Referenz entfällt. Der Server lädt daher zuerst einen leeren Screen und löscht anschließend jeden Screen der Registratur mit allem, was darauf liegt. Die Slots bleiben dabei erhalten und werden einzeln freigegeben, damit ihre Generationen weiterzählen.

=== Veraltete Referenzen

Nach dem Löschen eines Objekts kann dessen Stellvertreter auf dem Client weiter bestehen. Seine Referenz ist dann veraltet. Da freie Slots wiederverwendet werden, kann derselbe Slot inzwischen ein neues Objekt enthalten. Ohne Generation würde ein Aufruf über den alten Stellvertreter unbemerkt das neue Objekt verändern. Mit Generation passt die Referenz nicht mehr zum Slot, und der Aufruf wird abgewiesen.

Die Prüfung geschieht an zwei Stellen. Auf dem Server prüft die Registratur jede Referenz wie in @lst:slot. Auf dem Client führt der `PyBricksInterceptor` eine Session, die bei `clear()` und bei einem Verbindungsabbruch endet. Jeder Stellvertreter merkt sich die Session, in der er entstanden ist. Gehört er zu einer früheren Session, löst er den Fehler aus, ohne eine Übertragung zu starten. Nach einem Verbindungsabbruch ist das die einzige verlässliche Prüfung, denn der ESP32 kann in der Zwischenzeit neu gestartet sein und seine Registratur von vorn aufbauen. Damit eine alte Referenz auch in diesem Fall nicht zufällig passt, beginnen die Generationen nach einem Start bei einem zufälligen Wert.

Beide Prüfungen melden denselben Fehler. Die Fehlernutzlast trägt dafür neben der Beschreibung unter `e` eine Fehlerart unter `k`, und der Client löst anhand dieser Art die passende Ausnahme aus. `StaleReferenceError` steht für ein nicht mehr vorhandenes Objekt, `WrongKindError` für eine Referenz der falschen Art. Alle übrigen Fehler kommen als `RemoteError` an. Alle drei erben von `RuntimeError`. Die Anwendung kann dadurch gezielt auf eine veraltete Referenz reagieren und beispielsweise die Oberfläche neu aufbauen, ohne den Fehlertext auswerten zu müssen.

Ganz ausgeschlossen sind Verwechslungen allerdings nicht. Nach 64 Freigaben desselben Slots wiederholt sich die Generation, und ein Stellvertreter, der die ganze Zeit bestanden hat, passt wieder. Löscht die Anwendung einen Screen, bleiben außerdem die Stellvertreter der Elemente darauf auf dem Client gültig, da der Client sie nicht kennt. Ihr nächster Aufruf erreicht den Server und wird erst dort abgewiesen.

== Ansteuerung der Anzeige <sec:ansteuerung>

Die Ansteuerung der Anzeige bildet auf dem Server die oberste Schicht aus @sec:architektur. Sie ist die einzige Stelle mit Kenntnis der Anzeigehardware und liegt in `display/server/driver`. Die Darstellung übernimmt @LVGL in der MicroPython-Anbindung, die auch den Treiber für den Displaycontroller ILI9341 mitbringt. Das Display ist über @spi angebunden, der kapazitive Touchcontroller über @i2c.

Aufgebaut wird die Anzeige vom `ESPDisplayAdapter`. Er öffnet die @i2c\-Verbindung, erzeugt den Touchcontroller und übergibt ihn dem Displaytreiber, der ihn als Zeigegerät bei @LVGL anmeldet. Anschließend reicht er das @LVGL\-Modul an die Adapter für Screens, Labels und Buttons weiter. Nur diese Adapter rufen @LVGL auf. Die Schichten darunter kennen die Bibliothek nicht.

Das Zeichnen ist von der Ausführung der Aufrufe getrennt. Der Treiber startet beim Initialisieren eine Ereignisschleife, die in festem Takt über einen Hardware-Timer den Task-Handler von @LVGL einplant. Dieser zeichnet geänderte Bereiche neu und fragt die Eingabegeräte ab. Ein Adapter ändert also nur den Zustand eines Objekts, etwa den Text eines Labels. Sichtbar wird die Änderung erst beim nächsten Durchlauf des Task-Handlers. Ein Aufruf kann deshalb bereits abgeschlossen sein, bevor die Änderung auf dem Display erscheint.

Der Touchcontroller wird regelmäßig abgefragt, seine Interrupt-Leitung wird nicht genutzt. @LVGL ruft dazu bei jedem Durchlauf die Funktion `touch_read_cb` auf, die das Registerabbild des Controllers liest. Jede Abfrage kostet eine @i2c\-Transaktion, auch wenn keine Berührung vorliegt. Die Funktion darf außerdem keine Ausnahme weitergeben. Bei einer unbehandelten Ausnahme beendet sich die Ereignisschleife dauerhaft. Die Anzeige würde danach nicht mehr neu gezeichnet, obwohl weiterhin Aufrufe ankommen. Ein fehlgeschlagener Lesevorgang wird deshalb als fehlende Berührung gemeldet.

Erkennt @LVGL eine Berührung auf einem Button, löst es ein Ereignis aus. Der Screen-Adapter registriert dafür beim Erzeugen eines Buttons die Methode `on_event` für die Ereignisse `PRESSED` und `RELEASED`. `on_event` ermittelt über die Registratur die Referenz des Buttons, übersetzt den Ereigniscode in einen Namen wie `press` und ergänzt einen Zeitstempel. Das Ergebnis wird im Ereignispuffer des Objekts abgelegt, aus dem der Client es wie in @sec:umsetzung-kommunikation beschrieben abfragt.

Vor dem Ablegen prüft `on_event`, ob für das Ereignis eine Bindung besteht. Eine Bindung legt fest, dass ein Ereignis auf einem Objekt eine Aktion auf einem anderen auslöst. Der Client legt sie einmal mit einem gewöhnlichen Aufruf an. Danach führt der Server die Aktion direkt im Rückruf aus, ohne dass eine Übertragung nötig ist. Der Client erfährt trotzdem von jedem Ereignis, da es unabhängig von der Bindung gepuffert wird.

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

Die Menge der Aktionen ist absichtlich klein und fest vorgegeben. Sie enthält keine Bedingungen, keinen Zustand und keine Berechnungen. Bindungen bleiben damit auf Reaktionen beschränkt, die nur die Darstellung betreffen, etwa den Wechsel zwischen zwei Screens. Die Logik der Anwendung liegt weiterhin auf dem Client. Unbekannte Aktionen weist `bind` ebenso zurück wie Referenzen, die veraltet sind oder die falsche Art haben (@sec:objektmodell).

== Ablauf eines vollständigen Aufrufs

Die vorigen Abschnitte haben die Schichten einzeln beschrieben. Dieser Abschnitt verfolgt einen einzelnen Aufruf durch alle Schichten. Als Beispiel dient folgende Zeile

```python
counter_label.set_text("Counter: {}".format(counter))
```

aus dem Beispielprogramm des Hubs (siehe @lst:beispielprogramm). Sie ändert den Text eines Labels und liefert keinen Rückgabewert. Der Einfachheit halber gehen wir von `counter = 42`aus. 

*Aufruf auf dem Client.* `counter_label` ist ein Stellvertreter vom Typ `Label`. Seine Methode `set_text` prüft zunächst, ob er zur aktuellen Session gehört, und übergibt den Aufruf dann an `PyBricksInterceptor.call()`. Die Referenz des Labels wird dabei den Argumenten vorangestellt. Die Kommunikationsschicht bildet daraus einen `CommandPayload` mit dem Scope `label`, der Methodenkennung von `set_text` und der Argumentliste aus Referenz und Text. Die Nachricht erhält die nächste freie Kennung.

*Zerlegung.* MessagePack kodiert diese Nutzlast in 32Byte. Bei 13 Byte Nutzlast je Frame zerfällt sie nach @eq:blöcke in drei Frames. Die ersten beiden tragen `DATA`, der letzte `DATA_LAST` mit den verbleibenden sechs Byte. 

*Übertragung.* Der Client sendet jeden Frame einzeln und wartet auf dessen Bestätigung. Jeder Austausch ist ein Aufruf von `remote.call` und damit ein Round Trip über den Bus. Stimmen Kennung oder Position der Antwort nicht, war die Antwort veraltet oder der Frame ist verloren gegangen, und der Client wiederholt seine letzte Übertragung. Der Server legt jeden neuen Frame ab und bestätigt ihn sofort. Mit dem letzten Frame setzt er die Nutzlast zusammen und startet die Ausführung als eigenen Task der Ereignisschleife. Der letzte Frame wird bestätigt, bevor der Aufruf ausgeführt wird.

*Ausführung.* Der Task dekodiert die Nutzlast, wählt über den Scope den Label-Adapter aus und schlägt dort die Methodenkennung nach. `set_text` löst die Referenz in der Registratur auf, prüft dabei Generation und Art und setzt den Text des @LVGL\-Objekts. Sichtbar wird der neue Text erst beim nächsten Durchlauf des Task-Handlers, wie in @sec:ansteuerung beschrieben wurde. Das Ergebnis `None` wird als `DataPayload` kodiert. Der Server legt es anschließend unter der Kennung im Ausgangspuffer ab.

Ein sofortiges Neuzeichnen im Adapter wäre möglich, würde aber die Ereignisschleife für die Dauer der Übertragung zum Display blockieren und damit auch die Bearbeitung weiterer Frames verzögern.

*Abholen.* Der Client fragt mit `READY` nach, ob das Ergebnis bereitliegt. Ob ein Ergebnis schon beim ersten Versuch vorliegt, hängt davon ab, ob die Ereignisschleife des Servers den Task bis dahin ausgeführt hat. Antwortet der Server mit `NACK`, wartet der Client 50 ms und fragt erneut. Auf `DONE` folgt eine Anfrage `NEXT` für Position 0, die den einzigen Ergebnisframe liefert, gekenzeichnet mit `DATA_LAST`, womit der Abholprozess endet. 

*Rückgabe.* Der Client dekodiert die Nutzlast und gibt den Rückgabewert `None` an den Aufrufer zurück, falls das Ergebnis nicht als Fehler gekennzeichnet ist. Andernfalls löst er die passende Ausnahme aus, wie in @sec:objektmodell beschrieben.

Ein Aufruf, der nur einen Text ändert, kostet damit mindestens fünf Round Trips. Nur drei davon transportieren den eigentlichen Aufruf und Nutzdaten. Mindestens zwei weitere sind nötig, um das Ergebnis abzuholen, enthalten also Steuerinformationen. Wie viele Round Trips in der Praxis nötig sind misst @sec:evaluation. 

Das Aufrufschema folgt somit der in @sec:interceptor beschriebenen Abfolge. Das Sequenzdiagramm @abb:interceptor zeigt die generischen Abläufe, die hier mit einem konkreten Beispiel gefüllt wurden. Die Abbildung zeigt auch die beiden Round Trips, die der Client für das Abholen des Ergebnisses benötigt. 

== Nebenläufigkeit und Fehlerbehandlung <sec:nebenlaeufigkeit>

=== Nebenläufigkeit

Auf dem Client gibt es keine möglichkeit zur Nebenläufigkeit. Ein Aufruf blockiert die Anwendung, bis das Ergebnis vorliegt oder eine Obergrenze erreicht ist. Da immer nur ein Aufruf gleichzeitig unterwegs ist, braucht der Client weder Sperren noch Puffer für mehrere offene Aufrufe.

Auf dem Server laufen dagegen drei Tasks nebenläufig. Ein Task ruft etwa jede Millisekunde `process` von PUPRemote auf und beantwortet damit die Anfragen des Clients. @LVGL zeichnet außerdem in einem festen Takt die Anzeige neu und fragt den Touchcontroller ab. Schließlich läuft jeder empfangene Aufruf in einem eigenen Task. Alle drei teilen sich eine einzige Ereignisschleife von `uasyncio` und damit einen Thread. Sie wechseln sich nur an festen Stellen ab, beispielsweise beim Warten eines der anderen Tasks.

Die Ausführung von Aufrufen lief in einer früheren Version in einem eigenen Thread. Das führte zu zwei Fehlern. Der Stack eines Threads wird vom Heap genommen, den @LVGL bereits zum großen Teil belegt. Nach einigen Dutzend Aufrufen ließ sich deshalb kein neuer Thread mehr anlegen. Außerdem ist @LVGL nicht reentrant, und der Task-Handler der Bibliothek lief teilweise im Thread mit seinem kleineren Stack. Dort lief der Stack im Rückruf des Touchcontrollers über. Mit einer gemeinsamen Ereignisschleife treten beide Fehler nicht mehr auf, da nie zwei Stellen gleichzeitig auf @LVGL zugreifen.

Der Preis dafür ist, dass die Ereignisschleife während der Ausführung eines Aufrufs belegt ist. Anfragen des Clients werden in dieser Zeit nicht beantwortet, und die Anzeige wird nicht neu gezeichnet. Da der Client ohnehin auf das Ergebnis wartet, ist das hier unkritisch.

=== Fehlerbehandlung

Fehler werden in der Schicht behandelt, in der sie auftreten. Nach oben gelangen sie nur, wenn die Schicht sie nicht selbst behandeln kann. @tab:fehler fasst die Fälle zusammen.

#figure(
  caption: [Fehlerfälle und ihre Behandlung],
  text(size: 9pt)[
    #table(
      columns: (1.2fr, 0.8fr, 1.6fr),
      align: left + top,
      table.header([*Fehler*], [*Schicht*], [*Behandlung*]),
      [Veraltete Antwort oder verlorene Bestätigung], [Transport], [Frame erneut senden, höchstens acht Versuche],
      [Wiederholter Frame auf dem Server], [Transport], [bestätigen, aber nicht erneut ablegen],
      [Abgebrochene Übertragung], [Transport], [Reste verwerfen, sobald Frame Nr. 0 einer neuen Nachricht eintrifft],
      [Ergebnis bleibt aus], [Kommunikation], [nach 5000 ms Ausnahme auf dem Client],
      [Unbekannter Scope oder Methodenkennung], [Kommunikation], [Fehlermeldung an den Client, `RemoteError`],
      [Veraltete Referenz oder falsche Art], [Objektmodell], [Fehlermeldung mit Fehlerart `StaleReferenceError` oder `WrongKindError`],
      [Ausnahme in einer Methode des Adapters], [Objektmodell], [Fehlermeldung an den Client, `RemoteError`],
      [Verbindungsabbruch], [Busanbindung], [Session beenden, `OSError` an die Anwendung],
      [Fehler beim Lesen des Touchcontrollers], [Anzeige], [als fehlende Berührung werten],
    )
  ],
) <tab:fehler>

In der Transportschicht sind Fehler der Normalfall. Da der Client direkt nach dem Schreiben auch liest, erhält er häufig die Antwort auf die vorherige Anfrage. Er erkennt sie an Kennung, Position und Art des Frames. Er sendet diesen anschließend erneut. Der Server bestätigt eine Wiederholung, legt den Frame aber kein zweites Mal ab. Das gilt auch für den letzten Frame einer Nachricht. Würde dieser bei einer Wiederholung die Ausführung erneut starten, liefe derselbe Aufruf zweimal, beim zweiten Mal mit einer leeren Nachricht. Erst wenn eine Obergrenze aus @tab:rückkanal erreicht ist, gibt der Client auf und löst eine Ausnahme aus, die den betroffenen Frame und den Aufruf nennt.

Für den Server gilt die Zusicherung aus @sec:zuverlaessigkeit. Jeder Aufruf hinterlässt ein Ergebnis oder eine Fehlermeldung. Jede Ausnahme bei der Ausführung wird abgefangen und als `ErrorPayload` im Ausgangspuffer abgelegt. Lässt sich selbst das Ergebnis nicht kodieren, legt er eine kurze Fehlermeldung ab. Anfragen, die der Server nicht zuordnen kann, beantwortet er mit einem Frame der Art `ERR`, etwa wenn nach dem Ergebnis einer unbekannten Nachricht gefragt wird.

Ein Verbindungsabbruch zeigt sich auf dem Client als `OSError: [Errno 19] ENODEV:` von PUPRemote. Der Client beendet dann die Session, da der Server in der Zwischenzeit neu gestartet sein kann, und reicht den Fehler an die Anwendung weiter. Ob sie es erneut versucht oder die Oberfläche neu aufbaut, entscheidet die Anwendung. Alle Stellvertreter aus der alten Session melden danach `StaleReferenceError`, wie @sec:objektmodell beschreibt.

Eine Stelle darf gar keinen Fehler weitergeben, nämlich der Rückruf, mit dem @LVGL den Touchcontroller abfragt. Eine Ausnahme dort beendet die Ereignisschleife von @LVGL dauerhaft. Die Anzeige würde dann nicht mehr neu gezeichnet, obwohl weiterhin Aufrufe ankommen. Ein fehlgeschlagener Lesevorgang wird deshalb als nicht vorhandene Berührung gewertet. Die Anwendung kann das nicht erkennen, da sie keinen Zugriff auf den Touchcontroller hat. Sie kann nur die Ereignisse abfragen, die @LVGL aus der Abfrage erzeugt.