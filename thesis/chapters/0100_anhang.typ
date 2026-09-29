#heading(numbering: none, level: 1)[Anhang]

== Quelltext und Testumgebung

Der vollständige Quelltext liegt unter
#link("https://github.com/mat-mv/legolab-tft-display")[github.com/mat-mv/legolab-tft-display].
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
    [`src/tests/`], [Testumgebung aus @sec:testumgebung mit drei Testläufen],
    [`src/tools/`], [Bundler, Konfigurationsprüfung, Auswertung der Messungen],
    [`src/measurements/`], [Rohdaten aller Messläufe als CSV],
    [`pcb/`], [Entwurf der Adapterplatine],
  ),
) <tab:quelltext>

Die Testumgebung wird mit `python3 tests/test_all.py`, `tests/test_events.py`
und `tests/test_poll.py` ausgeführt und benötigt weder Hardware noch
zusätzliche Pakete. `tests/fake_env.py` enthält die zweite Umsetzung der
Interceptor-Schnittstelle sowie die Attrappen für Anzeigebibliothek und
Laufzeitumgebungen.

#figure(
  caption: [Beispielprogramm auf dem Hub],
  ```python
from pybricks.parameters import Button, Color, Direction, Port, Side, Stop
from pupremote import PUPRemoteHub
from pybricks.tools import wait, StopWatch

from pybricks_bundle import *

p = PUPRemoteHub(Port.A)

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
    # Polling both buttons costs one round trip each; leaving it out would not
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
