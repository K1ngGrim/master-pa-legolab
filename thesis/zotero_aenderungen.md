# Änderungen für Zotero

Stand: 2026-10-02. `biblio.bib` ist bereits korrigiert. Ein Export aus Zotero
überschreibt die Datei aber, deshalb müssen dieselben Werte auch in Zotero
stehen. Die Citation-Keys bleiben überall unverändert.

Allgemein:

- Personennamen im Zwei-Feld-Modus eintragen (Nachname | Vorname). Im
  Ein-Feld-Modus exportiert Zotero sie in doppelten Klammern, etwa
  `{{Yigit, Ozan}}`.
- Organisationen als Autor im Ein-Feld-Modus eintragen, dann exportiert Zotero
  sie korrekt als `{{…}}`.
- Alte ResearchGate-Anhänge und Abstracts mitlöschen, sonst kommen sie über das
  Feld „Abstract“ zurück.

---

## A. Neue Einträge

Diese beiden gibt es in Zotero noch nicht.

### nextionInstructionSet

- Item Type: Web Page
- Titel: Instruction Set
- Autor (Ein-Feld): Nextion
- URL: https://nextion.tech/instruction-set/
- Accessed: 2026-10-02

### microROSAgent

- Item Type: Web Page
- Titel: micro-ROS-Agent: ROS 2 Package Using Micro XRCE-DDS Agent
- Autor (Ein-Feld): micro-ROS
- URL: https://github.com/micro-ROS/micro-ROS-Agent
- Accessed: 2026-10-02

---

## B. Korrigierte Einträge

### Konferenzbeiträge (Item Type „Conference Paper“)

**PDFSystemArchitecture**
- Titel: System Architecture Directions for Networked Sensors
- Autoren: Hill | Jason; Szewczyk | Robert; Woo | Alec; Hollar | Seth; Culler | David; Pister | Kristofer
- Datum: 2000-11
- Proceedings Title: Proceedings of the Ninth International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS-IX)
- Publisher: ACM
- Place: Cambridge, MA, USA
- Pages: 93–104
- DOI: 10.1145/378993.379006
- URL: leer

**MateTinyVirtual2026**
- Titel: Maté: A Tiny Virtual Machine for Sensor Networks
- Autoren: Levis | Philip; Culler | David
- Datum: 2002-10
- Proceedings Title: Proceedings of the 10th International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS-X)
- Publisher: ACM
- Place: San Jose, CA, USA
- Pages: 85–95
- DOI: 10.1145/605397.605407
- URL: leer

**ProtothreadsSimplifyingEventdriven2026**
- Titel: Protothreads: Simplifying Event-Driven Programming of Memory-Constrained Embedded Systems
- Autoren: Dunkels | Adam; Schmidt | Oliver; Voigt | Thiemo; Ali | Muneeb
- Datum: 2006-10
- Proceedings Title: Proceedings of the 4th International Conference on Embedded Networked Sensor Systems (SenSys '06)
- Publisher: ACM
- Place: Boulder, CO, USA
- Pages: 29–42
- DOI: 10.1145/1182807.1182811
- URL: leer

**millerResponseTimeMancomputer1968**
- Item Type von Journal Article auf Conference Paper ändern
- Proceedings Title: Proceedings of the December 9–11, 1968, Fall Joint Computer Conference, Part I (AFIPS '68)
- alle anderen Felder bleiben

### Reports (Item Type „Report“)

**NoteDistributedComputing**
- Titel: A Note on Distributed Computing
- Autoren: Waldo | Jim; Wyant | Geoff; Wollrath | Ann; Kendall | Sam
- Report Type: Technical Report
- Report Number: SMLI TR-94-29
- Institution: Sun Microsystems Laboratories
- Place: Mountain View, CA
- Datum: 1994-11
- URL bleibt

**MODBUSApplicationProtocol** (Item Type von Web Page auf Report ändern)
- Titel: MODBUS Application Protocol Specification V1.1b3
- Autor (Ein-Feld): Modbus Organization
- Institution: Modbus Organization
- Datum: 2012-04-26
- URL: https://www.modbus.org/file/secure/modbusprotocolspecification.pdf
- Accessed: 2026-10-02
- Website Title „Studocu“ löschen

**microsystemsRPCRemoteProcedure1988**
- Autor auf Ein-Feld-Modus umstellen und „Sun Microsystems“ eintragen

**DINMediaStandards** (Item Type Report, nicht „Standard“: die Standard-Ausgabe zerlegt die Normnummer zu „ISO15765–2“)
- Titel: Road Vehicles — Diagnostic Communication over Controller Area Network (DoCAN) — Part 2: Transport Protocol and Network Layer Services
- Autor (Ein-Feld): International Organization for Standardization
- Institution: International Organization for Standardization
- Report Type: Norm ISO 15765-2:2024 (die Normnummer muss im Feld Report Type stehen, im Feld Report Number wird sie verstümmelt)
- Place: Genf
- Datum: 2024-04
- Report Number: leer
- URL: leer
- Falls doch die Ausgabe 2016 gewünscht ist: Report Type „Norm ISO 15765-2:2016“, Datum 2016-04 (3. Ausgabe, zurückgezogen)

**CANopen** (Item Type von Web Page auf Report ändern)
- Titel: CANopen Application Layer and Communication Profile
- Autor (Ein-Feld): CAN in Automation
- Institution: CAN in Automation e. V.
- Report Type: Spezifikation
- Report Number: CiA 301 Version 4.2.0
- Datum: 2011-02-21
- URL: https://www.can-cia.org/cia-groups/technical-documents
- Accessed: 2026-10-02

**RFC9110HTTP** (Item Type von Web Page auf Report ändern)
- Titel: HTTP Semantics
- Autoren: Fielding | R.; Nottingham | M.; Reschke | J.
- Report Type: Request for Comments
- Report Number: RFC 9110
- Institution: Internet Engineering Task Force
- Datum: 2022-06
- DOI im Feld Extra: `DOI: 10.17487/RFC9110`
- URL bleibt

### Bücher (Item Type „Book“)

**DistributedSystems3rd**
- Volume: leeren
- Edition: 3
- Publisher: distributed-systems.net

**PDFPatternorientedSoftware** (POSA 1)
- Publisher: Wiley
- Place: Chichester
- Datum: 1996
- URL und Accessed: leeren

**PDFPatternOrientedSoftware** (POSA 2)
- Publisher: Wiley
- Place: Chichester
- Datum: 2000
- URL und Accessed: leeren

**cardPsychologyHumancomputerInteraction1983**
- Publisher: L. Erlbaum Associates
- Place: Hillsdale, NJ

### Zeitschriftenartikel (Item Type „Journal Article“)

**MctdeSPISerial2019** (Inhalt komplett ersetzen)
- Titel: Introduction to SPI Interface
- Autor: Dhaker | Piyu
- Publication: Analog Dialogue
- Volume: 52
- Issue: 3
- Datum: 2018-09
- Publisher: Analog Devices
- URL: https://www.analog.com/en/resources/analog-dialogue/articles/introduction-to-spi-interface.html
- Accessed: 2026-10-02

**eugsterManyFacesPublish2003**
- Autoren: Eugster | Patrick Th.; Felber | Pascal A.; Guerraoui | Rachid; Kermarrec | Anne-Marie
- Datum: 2003-06
- Pages: 114–131
- URL: https://dl.acm.org/doi/10.1145/857076.857078

**ImplementingRemoteProcedure1984**
- URL: https://dl.acm.org/doi/10.1145/2080.357392

### Webseiten (Item Type „Web Page“)

**JavaDevelopmentKit**
- Titel: Java Remote Method Invocation Specification
- Autor (Ein-Feld): Oracle

**CICSTransactionServer2025**
- Titel: ONC RPC Concepts — CICS Transaction Server for z/OS 5.5
- Autor (Ein-Feld): IBM
- Hinweis: wird in der Arbeit nicht mehr zitiert, RFC 5531 (`thurlowRPCRemoteProcedure2009`) steht im selben Satz. Der Eintrag kann in Zotero bleiben, er erscheint nicht im Literaturverzeichnis.

**HandlungsorientiertesLernen**
- Titel: LEGO Education SPIKE Prime Set
- Autor (Ein-Feld): LEGO Education
- URL: https://education.lego.com/de-de/products/lego-education-spike-prime-set/45678/
- Accessed: 2026-10-02
- alten Abstract und Snapshot löschen

**CseyorkucaOzHashhtml**
- Autor auf Zwei-Feld-Modus umstellen: Yigit | Ozan

**niklasBitsquidDevelopmentBlog2011**
- Titel: Managing Decoupling Part 4 – The ID Lookup Table
- Autor: Frykholm | Niklas
- Website Title: bitsquid: development blog

**CoreSpecification2023**
- Titel: Core Specification 5.4
- Autor (Ein-Feld): Bluetooth SIG
- Datum: 2023

**CommonObjectRequest**
- Titel: Common Object Request Broker Architecture (CORBA), Version 3.4
- Autor (Ein-Feld): Object Management Group
- Datum: 2021-02

**DDSExtremelyResource**
- Autor (Ein-Feld): Object Management Group
- Datum: 2020-02

---

## C. Nicht mehr zitiert

Diese Einträge erscheinen nach den Änderungen nicht mehr im
Literaturverzeichnis. Sie können in Zotero bleiben.

- `CICSTransactionServer2025`, siehe oben
- `ILI9341LCDController` (LVGL-Treiberdoku). 6.2.1 belegt den ILI9341 jetzt mit
  dem Datenblatt `ilitekILI9341Datasheet2011`.

## D. Bewusst nicht geändert

- `gammaDesignPatternsElements1995` („Pearson Education 1995“ mit indischer ISBN):
  welche Ausgabe gemeint ist, ließ sich nicht klären.
- Miller [43]: Crossref und OpenAlex nennen nur Seite 267, die Endseite fehlt.
- Bluetooth Core 5.4: nur das Jahr, das genaue Freigabedatum ist nicht geprüft.
- Frykholm: Der Nachname ist nur über einen anderen Beitrag desselben Blogs
  belegt.
