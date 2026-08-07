# Architektur-Review und Verbesserungsvorschläge

Dieses Dokument sammelt kritische Anmerkungen zur aktuellen Implementierung der Middleware im Projekt `legolab-tft-display`. Es ist als konstruktive Gegenlese gedacht und geht ausdrücklich nicht davon aus, dass die Architektur bereits optimal ist. Viele Punkte sind natürliche Folgen eines Prototyps und eignen sich gut als Material für die Kapitel Evaluation, Limitierungen und Ausblick.

Stand der Durchsicht: 16.06.2026. Bezug ist der Code unter `src/`.

Prioritäten: P1 hoch (Korrektheit oder blockierende Lücke), P2 mittel (Robustheit oder Effizienz), P3 niedrig (Wartbarkeit oder Kosmetik).

## Stärken (zur Einordnung)

- Klare Schichtung von Transport, Messaging, Interceptor und Objektmodell.
- Symmetrisches Stub- und Skeleton-Modell mit gemeinsamen abstrakten Basisklassen auf beiden Seiten.
- Ansatz einer Transportabstraktion über `InterceptorBase` und `PupRemoteInterceptor`.
- Korrelations-Id (`g_id`) zur Zuordnung von Anfrage und Antwort.
- Eigener Bundler mit getrennten Build-Profilen für Hub und ESP32.

## Verbesserungsvorschläge

### 1. Framing-Overhead reduzieren (P2)

**Beobachtung.** Der Frame-Header `<BB5sB` belegt 8 Byte. `PAYLOAD_SIZE = FRAME_SIZE - 9 = 7`. Bei `FRAME_SIZE = 16` werden pro Frame 16 Byte übertragen, davon tragen nur 7 Byte Nutzlast. Das sind rund 44 Prozent Nutzdatenanteil. Zusätzlich bleibt durch die Differenz von 9 statt 8 ein Byte strukturell ungenutzt.

**Auswirkung.** Hoher relativer Overhead und mehr Frames pro Nachricht, was die Latenz auf dem ohnehin langsamen Bus erhöht.

**Vorschlag.** `PAYLOAD_SIZE` mindestens auf `FRAME_SIZE - 8` setzen, um das freie Byte zu nutzen. Prüfen, ob das `request`-Feld mit 5 Byte in jedem Frame nötig ist oder nur im ersten Frame einer Nachricht stehen muss. Den Steuerteil schlanker fassen, etwa Flags und `frame_nr` in ein Byte packen. Mittelfristig eine kompakte binäre Serialisierung statt JSON erwägen. Falls Pybricks größere Pakete erlaubt, `max_packet_size` und `FRAME_SIZE` anheben.

**Bezug.** Evaluation (Overhead durch Framing), Ausblick (alternative Serialisierung).

### 2. Ende-zu-Ende-Fehlerbehandlung fehlt (P1)

**Beobachtung.** In `MiddlewareInterceptor.__handle_message_background__` werden Ausnahmen gefangen und nur geloggt. Es wird kein Ergebnis und kein Fehler in `outgoing[g_id]` abgelegt. Das vorhandene ERROR-Flag im Frame wird im Ergebnispfad nicht genutzt.

**Auswirkung.** Tritt im Dispatcher ein Fehler auf, wird `outgoing[g_id]` nie gesetzt. Der Client wartet in `while not self.__is_result_ready__(...)` dann unbegrenzt. Ein einzelner Serverfehler blockiert den Client dauerhaft.

**Vorschlag.** Im Fehlerfall eine Antwortnachricht mit gesetztem ERROR-Flag und einer Fehlerbeschreibung in `outgoing[g_id]` ablegen. Clientseitig das ERROR-Flag prüfen und eine Ausnahme auslösen oder einen definierten Fehlerwert zurückgeben.

**Bezug.** Limitierungen, Zuverlässigkeitsmechanismen.

### 3. Keine Timeouts und kein begrenztes Retry beim Abholen (P1)

**Beobachtung.** Sowohl die Bereitschaftsabfrage als auch die Ergebnisschleife in `PyBricksInterceptor.call` laufen ohne Zeitlimit. Auch das erneute Senden eines Frames in der Sendeschleife hat keine Obergrenze.

**Auswirkung.** Bei Frame-Verlust oder Serverausfall blockiert der Aufruf endlos. Das deckt sich mit den im Zwischenstand selbst genannten offenen Punkten.

**Vorschlag.** Zeitlimits mit `StopWatch` einführen, eine maximale Anzahl Wiederholungen festlegen und nach Ablauf eine Ausnahme auslösen. Die Wartezeit zwischen Bereitschaftsabfragen adaptiv gestalten statt fest 50 Millisekunden.

**Bezug.** Zuverlässigkeitsmechanismen, Limitierungen.

### 4. Speicherlecks auf dem Server (P1)

**Beobachtung.** `received_frames` und `outgoing` in `MiddlewareInterceptor` werden nie geleert. `received_frames[g_id]` wächst mit jedem Frame, `outgoing[g_id]` bleibt nach dem Abholen erhalten.

**Auswirkung.** Auf einem speicherbeschränkten ESP32 führt langer Betrieb zu stetig steigendem Speicherverbrauch und am Ende zum Absturz.

**Vorschlag.** `received_frames[g_id]` nach vollständigem Empfang einer Nachricht entfernen. `outgoing[g_id]` löschen, sobald der letzte Frame abgeholt wurde. Optional eine TTL oder eine Obergrenze je Eintrag einführen.

**Bezug.** Ressourcenverbrauch, Implementierung.

### 5. Nebenläufigkeitsmodell überdenken (P2)

**Beobachtung.** Pro vollständig empfangener Nachricht wird über `_thread.start_new_thread` ein neuer Thread gestartet. `incoming_queue` ist global und wird in `__s_call__` komplett geleert, unabhängig von der `g_id`. Es gibt keine Synchronisierung der gemeinsam genutzten Strukturen.

**Auswirkung.** Das funktioniert nur unter der Annahme genau einer Nachricht zur Zeit. Bei Pipelining oder mehreren Clients vermischen sich Frames verschiedener `g_id`. Häufige Thread-Erzeugung ist auf dem ESP32 zudem teuer und kann zu Wettlaufsituationen führen.

**Vorschlag.** Frames je `g_id` getrennt puffern statt eine gemeinsame Queue komplett zu leeren. Statt eines Threads pro Nachricht einen einzelnen Worker mit Auftragsqueue verwenden oder die Verarbeitung direkt in der `uasyncio`-Schleife abwickeln. Zugriffe auf gemeinsame Strukturen absichern.

**Bezug.** Implementierung (Nebenläufigkeit und Verarbeitung).

### 6. Identitätsvergleich statt Gleichheit (P1, kleiner Aufwand)

**Beobachtung.** In `PyBricksInterceptor.call` steht `while ack_frame.frame_nr is not frame.frame_nr`. In `EspButtonAdapter.is_button_pressed` steht `event["type"] is not "release"`.

**Auswirkung.** `is` und `is not` vergleichen Objektidentität, nicht Werte. Für Zahlen und Zeichenketten funktioniert das nur zufällig durch internierte Objekte. Das ist eine schwer zu findende Fehlerquelle.

**Vorschlag.** Durchgängig `==` und `!=` verwenden.

**Bezug.** Implementierung, Fehlerbehandlung.

### 7. Brüchige Rekonstruktion der Nutzlast (P2)

**Beobachtung.** Es gibt zwei Wege, eine Nachricht wieder zusammenzusetzen. Der Client nutzt `add_frame` und `get_payload` mit Sortierung und `rstrip(b"\x00")` je Chunk. Der Server nutzt `Message.add` ohne Sortierung und filtert in `__sanitize_message__` alle Zeichen unter Codepoint 32 heraus.

**Auswirkung.** Beide Verfahren sind an die Annahme reiner JSON-Textnutzlast gebunden. Bei binären Daten oder bestimmten Steuerzeichen gehen Bytes verloren. Die zwei unterschiedlichen Pfade erschweren zudem das Verständnis.

**Vorschlag.** Eine explizite Längenangabe je Nachricht oder je Frame einführen, sodass kein Null-Padding interpretiert werden muss. Beide Seiten auf einen gemeinsamen Rekonstruktionsweg vereinheitlichen.

**Bezug.** Fragmentierung und Rekonstruktion, Implementierung.

### 8. eval-basierte Bindung und Bindung an globale Funktionen (P2)

**Beobachtung.** `PUPRemoteSensor.add_command` bindet den Kanalnamen über `eval(mode_name)` an eine gleichnamige globale Funktion. In `src/main.py` werden dafür global `call` und `ack` gesetzt.

**Auswirkung.** Es kann praktisch nur eine Interceptor-Instanz geben, da die Namen global sind. Die Bindung ist fragil gegenüber Umbenennungen und stellt einen leichten Sicherheits- und Wartbarkeitsgeruch dar.

**Vorschlag.** Die aufzurufenden Methoden explizit als gebundene Funktionen übergeben statt über globale Namen aufzulösen. Falls die Bibliothek das nicht erlaubt, die Einschränkung klar dokumentieren und kapseln.

**Bezug.** Implementierung, Limitierungen.

### 9. Transportabstraktion schärfen (P2, relevant fürs Paper)

**Beobachtung.** `InterceptorBase` vermischt RPC-Semantik wie `__s_call__`, `__ack__` und `__is_result_ready__` mit der Anbindung an einen konkreten Transport. Es existiert nur eine Transportbindung über PUPRemote.

**Auswirkung.** Der Anspruch der Transportunabhängigkeit ist im Code noch nicht klar belegt, da RPC-Logik und Transport nicht sauber getrennt sind.

**Vorschlag.** Eine minimale Transportschnittstelle definieren, etwa mit den Operationen Frame senden und Frame empfangen, und die RPC-Logik darauf aufsetzen. Dann lässt sich konzeptionell und in der Arbeit zeigen, wie ein zweiter Transport wie UART, BLE oder TCP eingehängt würde. Das stützt direkt den Titel des geplanten Papers.

**Bezug.** Architektur, Kommunikations- und Transportschicht, Ausblick.

### 10. Ereignismodell verfeinern (P2)

**Beobachtung.** `ObjectRegistry.get_last_event` liefert nur das jeweils letzte Ereignis und entfernt es nicht. `EspButtonAdapter.is_button_pressed` wertet daraus ab, ob das letzte Ereignis kein Release war.

**Auswirkung.** Ereignisse können mehrfach oder gar nicht erkannt werden, je nach Polling-Zeitpunkt. Flüchtige Ereignisse wie ein kurzer Klick gehen leicht verloren oder werden mehrfach gezählt.

**Vorschlag.** Ereignisse je Objekt in einer Queue mit Konsum-Semantik führen, sodass jedes Ereignis genau einmal abgeholt wird. Ereignistypen klar definieren und die clientseitige Abfrage darauf abstimmen.

**Bezug.** Abstraktion des Displays, Evaluation (Interaktion).

### 11. Lebenszyklus entfernter Objekte (P2)

**Beobachtung.** Die `ObjectRegistry` legt Objekte an und vergibt Referenzen, bietet aber keinen Weg, ein Objekt wieder freizugeben. Es gibt keine Lösch- oder Aufräum-Schnittstelle für Stubs.

**Auswirkung.** Die Registry und der LVGL-Kontext wachsen mit jeder Erzeugung, was auf dem ESP32 relevant ist.

**Vorschlag.** Eine `destroy`- oder `free`-Operation im Objektmodell ergänzen, die das LVGL-Objekt entfernt und den Registry-Eintrag samt Event-Puffer löscht.

**Bezug.** Objekterzeugung und Lebenszyklus.

### 12. Kleinere Korrektheits- und Konsistenzpunkte (P3)

- `Frame.create_error` nimmt einen Parameter `g_id`, gibt ihn aber nicht an den Konstruktor weiter. Fehlerframes tragen dadurch immer `g_id = 0`.
- `MiddlewareInterceptor.__ack__` gibt im `IndexError`-Fall den Platzhalter `"Halli"` zurück. Stattdessen sollte ein definierter Fehlerframe zurückkommen.
- `magische` Zeichenketten für Scopes wie `"display"`, `"screen"`, `"label"` und `"button"` als Konstanten oder Aufzählung führen.
- Namensgebung vereinheitlichen, etwa `EspLabeladapter` zu `EspLabelAdapter`.
- `EspButtonAdapter.set_text` liest `kwargs.get("label_id")`, wird aber über den Pfad `Button.set_text` nicht erreicht, da dieser an den Label-Scope geht. Toter Pfad, der entfernt oder konsolidiert werden sollte.

### 13. Display- und Touch-Loop ist deaktiviert (P1, vermutlich Regression)

**Beobachtung.** In `src/main.py` ist `uasyncio.create_task(adapter_task(pool))` auskommentiert. `adapter_task` startet die `process_loop` der Dispatcher, in der `Display.process` und damit `lv.task_handler` sowie das Touch-Auslesen laufen.

**Auswirkung.** Ohne diesen Loop werden LVGL-Aktualisierungen und Touch-Eingaben nicht regelmäßig verarbeitet. Die Anzeige und die Interaktion funktionieren dann nur eingeschränkt oder gar nicht.

**Vorschlag.** Den Loop wieder aktivieren oder den LVGL-Task gezielt in der Hauptschleife ausführen. Beim Schreiben der Implementierung den tatsächlichen aktiven Zustand prüfen.

**Bezug.** Implementierung, Evaluation.

### 14. Tests und Verifizierbarkeit (P2)

**Beobachtung.** Es gibt keine automatisierten Tests. Positiv ist, dass `constants.py` einen Fallback für `const` außerhalb von MicroPython bereitstellt, was Tests auf dem Host grundsätzlich erlaubt.

**Auswirkung.** Regressionen wie die Identitätsvergleiche oder die Rekonstruktionslogik fallen erst spät auf.

**Vorschlag.** Unit-Tests für `Frame` und `Message` mit Hin- und Rückserialisierung, gezielte Tests der Rekonstruktion mit mehreren Frames und ein Fake-Transport für einen Ende-zu-Ende-Test auf dem Host. Das liefert zugleich belastbare Zahlen für die Evaluation.

**Bezug.** Evaluation (funktionale Tests).

### 15. Wartbarkeit und veraltete Artefakte (P3)

**Beobachtung.** Mehrere Artefakte sind nicht mehr stimmig.

- `esp_firmware_entry.py` ist leer, ist aber im `bundle_config.json` als Einstieg für den ESP-Build vorgesehen.
- Das Profil `pybricks_firmware` in `bundle_config.json` verweist auf `./lib/display/pybricks_display.py`, die im aktuellen Stand fehlt.
- `src/pybricks/main.py` nutzt die Namen `PyBricksDisplay` und `PyBricksInterceptor` aus `pybricks_bundle`, während der aktuelle Client die Klasse `Display` verwendet.
- `doc/Com.md` und `doc/uml/architecute_class.puml` beschreiben das frühere `send`- und `pull`-Design und nicht das aktuelle `call`- und `ack`-Modell.
- Unter `src/old/` liegen ältere Stände.

**Auswirkung.** Build und Dokumentation laufen auseinander, was Einarbeitung und Reproduzierbarkeit erschwert.

**Vorschlag.** Die Build-Profile an den aktuellen Code angleichen, fehlende Einstiegsdateien ergänzen oder entfernen, die alten Diagramme durch die neuen unter `doc/uml` ersetzen und veraltete Dokumente als historisch kennzeichnen oder archivieren.

**Bezug.** Implementierung, Anhang.

## Priorisierte Übersicht

| Nr | Thema | Priorität | Bezug Kapitel |
|----|-------|-----------|---------------|
| 2  | Ende-zu-Ende-Fehlerbehandlung | P1 | Limitierungen, Zuverlässigkeit |
| 3  | Timeouts und Retry | P1 | Zuverlässigkeit, Limitierungen |
| 4  | Speicherlecks Server | P1 | Ressourcenverbrauch |
| 6  | Identitätsvergleich | P1 | Implementierung |
| 13 | Display- und Touch-Loop deaktiviert | P1 | Implementierung, Evaluation |
| 1  | Framing-Overhead | P2 | Evaluation, Ausblick |
| 5  | Nebenläufigkeitsmodell | P2 | Implementierung |
| 7  | Rekonstruktion der Nutzlast | P2 | Fragmentierung |
| 8  | eval-Bindung | P2 | Implementierung |
| 9  | Transportabstraktion schärfen | P2 | Architektur, Ausblick, Paper |
| 10 | Ereignismodell | P2 | Objektmodell, Evaluation |
| 11 | Objektlebenszyklus | P2 | Objektmodell |
| 14 | Tests | P2 | Evaluation |
| 12 | Kleinere Korrektheitspunkte | P3 | Implementierung |
| 15 | Veraltete Artefakte | P3 | Implementierung, Anhang |

## Hinweis zur Verwendung in der Arbeit

Die P1-Punkte lassen sich gut als ehrliche Limitierungen darstellen und zeigen ein reflektiertes Verständnis des eigenen Systems. Die P2-Punkte zu Transportabstraktion, Serialisierung und Nebenläufigkeit eignen sich als Ausblick und stützen zugleich den Anspruch des geplanten Papers. Eine offene Darstellung dieser Punkte wertet die Arbeit eher auf, als dass sie sie schwächt.
