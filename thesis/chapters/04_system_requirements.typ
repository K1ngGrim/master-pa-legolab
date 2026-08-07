= Systemanalyse und Anforderungen

== Zielsystem und Hardwareumgebung

Ausgangspunkt der vorliegenden Arbeit ist eine bestehende Hardwareplattform aus dem LEGO-Education-Ökosystem. Die Plattform definiert die technischen Rahmenbedingungen, innerhalb derer die in @sec:einleitung motivierte Display-Integration realisiert werden muss. Im Folgenden wird zunächst die zentrale Hardwarekomponente vorgestellt, anschließend werden ihre Eigenschaften im Hinblick auf die Anbindung eines Touchscreen-Displays analysiert. Aus dieser Analyse heraus ergibt sich die Notwendigkeit einer externen Erweiterung, deren mögliche Ausprägungen im letzten Abschnitt skizziert werden.

=== Der LEGO Education SPIKE Prime Hub als Ausgangsplattform

Den Kern des Zielsystems bildet der LEGO Education SPIKE Prime Hub @HandlungsorientiertesLernen. Hierbei handelt es sich um einen programmierbaren Steuerbaustein, der primär für den Einsatz im Bildungsbereich konzipiert ist und über sechs Ein- und Ausgabeports zum Anschluss von LEGO-kompatiblen Sensoren und Aktoren verfügt. Zur Interaktion mit dem Nutzer stellt der Hub eine 5×5-LED-Matrix, drei Tasten sowie einen einfachen Lautsprecher bereit.

Intern basiert der Hub auf einem STM32F413-Mikrocontroller @STM32F413423STMicroelectronics mit einem ARM-Cortex-M4-Kern, einer Taktfrequenz von etwa 100 MHz, rund 1 bis 1,5 MB Flash-Speicher sowie 320 KB SRAM @LegoLabKarlsruhe. Die Programmierung kann grafisch über die offizielle LEGO-Software oder textbasiert mittels MicroPython erfolgen. Welche Firmware konkret zum Einsatz kommt und welche Auswirkungen diese Wahl auf die spätere Lösung hat, wird in @sec:einschraenkungen vertieft.

Für die vorliegende Arbeit sind drei Eigenschaften des Hubs von besonderer Bedeutung:

- Der Hub stellt ausschließlich passive, an die Sensor- und Motorports gebundene Erweiterungsmöglichkeiten bereit. Eine direkte Anbindung beliebiger Peripheriegeräte über offene Schnittstellen wie SPI @MctdeSPISerial2019 oder I2C @I2CBus ist nicht vorgesehen.
- Die verfügbaren Anzeige- und Eingabemöglichkeiten beschränken sich auf die genannte LED-Matrix sowie die Hub-Tasten.
- Die Rechenleistung und der Arbeitsspeicher sind für einen Mikrocontroller zwar typisch, im Hinblick auf grafische Benutzeroberflächen jedoch stark limitiert.

Diese Eigenschaften legen den Rahmen fest, innerhalb dessen die Display-Integration konzipiert werden muss.

=== Notwendigkeit einer externen Erweiterung

Aus den in @sec:problemstellung motivierten Anforderungen an eine grafische Benutzeroberfläche mit Touch-Funktionalität ergibt sich unmittelbar ein Konflikt mit der beschriebenen Plattform. Die im Hub integrierten Ausgabe- und Eingabemöglichkeiten beschränken sich auf eine niedrig auflösende LED-Matrix und einfache Tasten und sind damit für die Darstellung komplexer Inhalte sowie für eine differenzierte Benutzerinteraktion ungeeignet. Auch eine Erweiterung des Hubs selbst ist nicht vorgesehen, da der Hub als geschlossene Komponente konzipiert ist und keine Schnittstellen zum direkten Anschluss grafischer Peripheriegeräte bereitstellt.

Daraus folgt, dass die geforderte Display-Funktionalität nicht innerhalb des Hubs, sondern ausschließlich außerhalb davon realisiert werden kann. Die Aufgabe der Display-Ansteuerung muss demnach an eine externe Hardwarekomponente delegiert werden, die ihrerseits an einen der vorhandenen Sensorports des Hubs angebunden wird. Hieraus ergeben sich zwei eigenständige Teilprobleme, die in den folgenden Abschnitten weiter ausgearbeitet werden:

- die Wahl einer geeigneten externen Hardware zur Ansteuerung eines Displays sowie
- die Etablierung einer geeigneten Kommunikationsbeziehung zwischen Hub und dieser externen Komponente.

== Anforderungen an die Display-Integration

=== Anforderungen an ein externes Display

Bevor konkrete Hardwarekomponenten betrachtet werden, lassen sich aus der Zielsetzung der Arbeit allgemeine Anforderungen an ein externes Display ableiten. Das Display soll die Darstellung einfacher grafischer Elemente wie Schaltflächen, Beschriftungen und Anzeigen ermöglichen und zugleich Benutzereingaben über einen Touchscreen entgegennehmen. Hinsichtlich Auflösung, Größe und Energieaufnahme orientieren sich die Anforderungen an typischen Embedded-Anwendungen und liegen damit im Bereich kleiner TFT-Displays mit Auflösungen im Bereich von etwa 240 × 320 Pixeln.

Solche Displays sind in unterschiedlichen Ausführungen verfügbar. Eine im Embedded-Bereich weit verbreitete Variante stellen Module mit ILI9341-Display-Controller dar, die eine Auflösung von 240 × 320 Pixeln bei einer Farbtiefe von 18 Bit unterstützen und über die SPI-Schnittstelle angesteuert werden können. Für die Erkennung von Berührungen kommen typischerweise kapazitive Touch-Controller wie der FT6X36 zum Einsatz, die über I2C angebunden werden und neben Einzelberührungen auch Mehrfingergesten erfassen können. Solche Module sind kostengünstig verfügbar und werden in der Maker- und Embedded-Community häufig in Verbindung mit Mikrocontrollern der ESP32-Familie eingesetzt.

=== Anforderungen an eine externe Steuerungseinheit

Da der SPIKE Prime Hub selbst keine direkte Anbindung eines TFT-Displays über SPI ermöglicht, muss zwischen Hub und Display eine zusätzliche Steuerungseinheit vermitteln. Diese übernimmt die unmittelbare Ansteuerung des Displays sowie die Verarbeitung der Touch-Eingaben und stellt gleichzeitig die Kommunikation mit dem Hub sicher. Aus dieser Doppelrolle ergeben sich mehrere Anforderungen an die einzusetzende Hardware:

- Sie muss über geeignete Schnittstellen zur Ansteuerung typischer TFT-Displays verfügen, insbesondere SPI für die Bildschirmdaten und I2C für den Touch-Controller.
- Sie muss ausreichend Rechenleistung und Speicher bieten, um eine grafische Bibliothek wie etwa @LVGL @LVGLLightVersatile ausführen zu können.
- Sie muss über eine Schnittstelle verfügen, die kompatibel zu den Sensorports des SPIKE Prime Hubs ist, oder eine entsprechende Anbindung über das LEGO-Powered-Up-UART-Protokoll (LPF2) unterstützen.

Diese Anforderungen werden von im Bildungs- und Maker-Bereich verfügbaren Erweiterungsboards erfüllt, die speziell für die Anbindung an LEGO-Hubs entworfen wurden. Ein Beispiel hierfür sind ESP32-basierte Boards der LMS-ESP32-Reihe @LMSESP32V20Clever2023, die sich gegenüber dem Hub als LEGO-Sensor ausgeben und damit eine Kommunikation über das LPF2-Protokoll ermöglichen. Welche konkrete Hardware im Rahmen dieser Arbeit eingesetzt wird, sowie die zugehörige Softwarekonfiguration werden im Kapitel zur Referenzimplementierung dargestellt.

=== Resultierende Systemstruktur

Aus den genannten Überlegungen ergibt sich eine grundsätzliche Systemstruktur, die sich aus drei Teilen zusammensetzt: dem SPIKE Prime Hub als zentrale Steuereinheit, einer externen Steuerungseinheit zur unmittelbaren Ansteuerung des Displays sowie einem TFT-Touchscreen-Display als Anzeige- und Eingabeelement. Die Kopplung zwischen Hub und externer Steuerungseinheit erfolgt dabei über die vom Hub bereitgestellten Sensorports und das zugehörige LPF2-Protokoll. Die konkrete Ausgestaltung dieser Kommunikation und der damit verbundenen Einschränkungen wird in den folgenden Abschnitten dieses Kapitels detailliert betrachtet.

== Kommunikationsanforderungen

== Einschränkungen der Plattform <sec:einschraenkungen>

=== Eingeschränkte Kommunikationsrichtung

=== Begrenzte Paketgröße

=== Beschränkte Laufzeitumgebung

== Verallgemeinerung des Problemraums <sec:verallgemeinerung>

/*
Die im vorigen Abschnitt herausgearbeiteten Einschränkungen wurden am konkreten Zielsystem hergeleitet. Sie sind jedoch nicht an dieses System gebunden, und diese Feststellung ist für die weitere Arbeit von Bedeutung: Sie entscheidet darüber, ob der folgende Entwurf eine Einzellösung darstellt oder eine Klasse von Verbindungen adressiert.

Die drei Eigenschaften lassen sich von der Plattform ablösen und als allgemeine Merkmale einer Verbindung formulieren. Erstens ist die Übertragung anfragegetrieben, das heißt, nur eine der beiden Seiten kann eine Übertragung anstoßen. Zweitens ist die Nutzlast je Übertragung klein und fest vorgegeben. Drittens steht auf mindestens einer Seite eine Laufzeitumgebung zur Verfügung, die weder einen vollständigen Netzwerkstack noch die üblichen Mittel nebenläufiger Programmierung bereitstellt.

Diese Kombination tritt über den betrachteten Bus hinaus in verschiedenen Ausprägungen auf. Bei der Kommunikation über I2C treibt der Master den Bus, und ein Slave kann eine Übertragung nicht selbstständig beginnen. Modbus RTU folgt demselben Muster aus Anfrage und Antwort. Auch bei Bluetooth Low Energy ist der verbreitete Zugriff über lesende Anfragen des Clients organisiert, und die standardmäßig ausgehandelte Nutzlast liegt in derselben Größenordnung wie beim hier betrachteten Bus. In allen genannten Fällen stellen sich dieselben Fragen: Wie werden Nachrichten zerlegt und wieder zusammengesetzt, wie gelangen Ergebnisse und Ereignisse zur anfragenden Seite zurück, und wie lässt sich all das vor der Anwendung verbergen.

Die vorliegende Arbeit behandelt den betrachteten Bus daher als einen Vertreter dieser Klasse. Der in den folgenden Kapiteln entwickelte Entwurf wird so formuliert, dass er auf die genannten Merkmale Bezug nimmt und nicht auf Eigenschaften einer bestimmten Plattform. Inwieweit dies gelungen ist, greift die Diskussion am Ende der Arbeit erneut auf.
*/