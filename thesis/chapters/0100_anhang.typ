#heading(numbering: none, level: 1)[Anhang]

#heading(numbering: none, level: 2)[Quelltext und Testumgebung]

Der vollständige Quelltext liegt unter
#link("https://github.com/mat-mv/legolab-tft-display")[github.com/mat-mv/legolab-tft-display].
Die Angaben in @sec:referenzimplementierung und @sec:evaluation beziehen sich, sofern nicht anders vermerkt, auf den Stand, der dort mit `stand-projektarbeit` markiert ist. Spätere Stände
setzen die Erweiterungen aus @sec:fazit um und verändern dabei das Protokoll.
Die folgenden Ordner sind für das Nachvollziehen der Arbeit die wichtigsten.

#figure(
  caption: [Aufbau des Quelltextes],
  table(
    columns: (auto, 1fr),
    align: left + top,
    table.header([*Pfad*], [*Inhalt*]),
    [`src/middleware/`], [Transport- und Kommunikationsschicht, Registratur, Codec],
    [`src/display/`], [Objektmodell, getrennt nach `protocol`, `client` und `server`],
    [`src/hub/`], [Beispielprogramm der Steuereinheit],
    [`src/tests/`], [Testumgebung aus @sec:testumgebung],
    [`src/tools/`], [Bundler und Auswertung der Messungen],
    [`src/measurements/`], [Rohdaten aller Messläufe],
    [`pcb/`], [Entwurf der Adapterplatine],
  ),
) <tab:quelltext>

Die Testumgebung wird mit `python3 tests/test_all.py` und
`tests/test_events.py` ausgeführt und benötigt weder Hardware noch zusätzliche
Pakete. `tests/fake_env.py` enthält die zweite Umsetzung der
Interceptor-Schnittstelle sowie die Attrappen für Anzeigebibliothek und
Laufzeitumgebungen. Spätere Stände ergänzen `tests/test_poll.py` für die Erweiterungen aus @sec:bestaetigung und @sec:rueckkanal-ereignisse und `tests/test_bindung.py`, das alle
Testläufe über eine zweite Busanbindung wiederholt, wie @sec:trennung beschreibt.

Für das Nachvollziehen der Messungen ist die Kopie der Bibliothek PUPRemote zu
beachten. Im Stand `stand-projektarbeit` liegen zwei Kopien der Version 1.6 bei, `src/hub/pupremote.py` und `src/vendor/pupremote/pupremote.py`, deren Funktion `call` ohne Angabe 0 ms wartet. Auf dem Hub lief dagegen eine
Fassung, in der dieser Wert nach @sec:busanbindung auf 100 ms angehoben ist.
Spätere Stände enthalten diese Fassung unter `src/hub/pupremote.py` und
dieselbe Datei mit Paketpfaden unter `src/vendor/pupremote/pupremote.py`. Seit
die Middleware die Wartezeit ausdrücklich übergibt, hängen die Messwerte nicht
mehr davon ab, welche Kopie installiert ist.

Nach dem Stand `stand-projektarbeit` ist die Middleware ohne die Anteile von
Display und Bus in ein eigenes Repository ausgelagert,
#link("https://github.com/K1ngGrim/micro-rpc")[github.com/K1ngGrim/micro-rpc].
Das Repository dieser Arbeit bindet es als Submodul ein.

#figure(
  caption: [Beispielprogramm auf dem Hub],
  ```python
from pybricks.parameters import Button, Color, Direction, Port, Side, Stop
from pupremote import PUPRemoteHub
from pybricks.tools import wait, StopWatch

from pybricks_bundle import *

p = PUPRemoteHub(Port.B)

interceptor = PyBricksInterceptor(p)
interceptor.register_interceptor()

display = Display(interceptor)

display.clear()

info = display.display_info()
print(info)

# --- Aufbau -----------------------------------------------------------------
# Display elements live on a screen, so one has to exist and be shown before
# anything can be placed on it. The second screen is created but not shown.
main_screen = display.create_screen(set_active=True, name="main")
menu_screen = display.create_screen(name="menu")

counter_label = main_screen.create_label(10, 10, 230, 20, "Counter: 0")
menu_label = menu_screen.create_label(10, 10, 230, 20, "Menue")

# Captions without umlauts: the default font of the display library carries a
# reduced set of glyphs, and a missing one is drawn as a placeholder box.
to_menu = main_screen.create_button(10, 60, 100, 40, "Menue")
to_main = menu_screen.create_button(10, 60, 100, 40, "Zurueck")

# --- Bindings --------------------------------------------------------------
# Declared once, here. From now on a press switches the screen on the display
# unit itself. Each of these two calls costs the usual number of transfers -
# once. Every switch afterwards costs none.
to_menu.on_press(ACT_SHOW_SCREEN, menu_screen)
to_main.on_press(ACT_SHOW_SCREEN, main_screen)

print("bindings declared")

# --- Ablauf -----------------------------------------------------------------
counter = 0

while True:
    counter_label.set_text("Counter: {}".format(counter))
    counter += 1

    # The screen has already changed by the time this query happens - the
    # binding did that. What arrives here is the notification, not the trigger.
    # Polling both buttons costs one full call each; leaving it out would not
    # affect the switching at all.
    if to_menu.is_button_pressed():
        print("menu opened")

    if to_main.is_button_pressed():
        print("back on the main screen")

    wait(1000)
```
)<lst:beispielprogramm>

#figure(
  caption: [Schaltplan der Adapterplatine],
  rotate(90deg, reflow: true)[
    #image("../figures/pcb_schematic.png", width: 100%)
  ]
)<abb:schematic>
