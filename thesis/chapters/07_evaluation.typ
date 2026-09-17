= Evaluation <sec:evaluation>

// ANSPRUCH: funktionaler Nachweis plus eine sauber belegte quantitative
// Aussage. Keine systematische Messreihe - der Umfang der Arbeit traegt das
// nicht, und der Nutzen waere gering.
// Berechnete und gemessene Werte durchgehend getrennt ausweisen.

== Funktionaler Nachweis

== Übertragungsaufwand

// Traegt die These aus Kap. 5.4.3 und ist die Belegstelle der Entwurfsrevision
// aus Kap. 6.5.1. Zwei Faktoren getrennt ausweisen, das ist die eigentliche
// Aussage:
// - Wirkung der Rahmung allein (8-Byte- gegen 3-Byte-Header, Format konstant)
// - Wirkung der Serialisierung allein (JSON gegen MessagePack, Header konstant)
// Erwartung: die Rahmung wiegt schwerer als das Format, weil bei kleiner MTU
// die Aufrundung auf ganze Pakete dominiert.
// Masseinheit sind Uebertragungen je Aufruf, nicht Bytes - Kap. 3.4.4 hat
// begruendet, warum die Anzahl der Uebertragungen und nicht die Bandbreite
// zaehlt.
// ACHTUNG: Zahlen muessen reproduzierbar sein, Rechenweg oder Messaufbau
// angeben.

== Ressourcenverbrauch

== Bewertung des Hardwareaufbaus

// Kurz halten, ein bis zwei Absaetze - passend zum Umfang von Kap. 6.2:
// - Funktioniert der Aufbau unter realen Bedingungen (Stecken, Handhabung)?
// - Was die Steckverbinder praktisch kosten (haeufigste Fehlerquelle)
// - Was man anders machen wuerde

== Diskussion der Ergebnisse
