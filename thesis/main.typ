#import "template/template.typ": *
#import "@preview/wrap-it:0.1.1"
#import "@preview/glossarium:0.5.10": make-glossary, register-glossary, print-glossary, gls, glspl
#import "chapters/00_0_abkürzungen.typ": *
#import "chapters/00_01_abstract.typ": *

#import "chapters/00_01_abstract.typ": AbstractGerman

#show: make-glossary
#register-glossary(entry-list)

#show: project.with(
   title: "Projektarbeit",
   subtitle: "lego::lab Karlsruhe: Schnittstellen zu externen Displays",
   authors: (
         (
         name: "Florian Kaiser", 
         matriculation_number: "79728", 
         email: "kafl1018@h-ka.de"
         ),
      ),
   date: datetime.today().display("[day].[month].[year]"),
   company_logo: {},
   logo_left: "logo_left.png",
   logo_right: "logo_right.png",
   abstract: [],
   institution: "Hochschule Karlsruhe",
   study_program: "Informatik Master",
   custom_front_page: [],
   examiner: "Prof. Dr. Uwe Haneke, Matthias Mruzek-Vering",
   zusammenfassung: [#AbstractGerman],
   ai_usage_disclosure: true,
   front_matter: [
      #heading(numbering: none, level: 1, outlined: true)[Abbildungs- und Tabellenverzeichnis]
      #heading(numbering: none, level: 2, outlined: false)[Abbildungen]
      #outline(title: none, target: figure.where(kind: image))
      #heading(numbering: none, level: 2, outlined: false)[Tabellen]
      #outline(title: none, target: figure.where(kind: table))
      #heading(numbering: none, level: 2, outlined: false)[Code-Listings]
      #outline(title: none, target: figure.where(kind: raw))

      #pagebreak()
      #heading(numbering: none, level: 1, outlined: true)[Abkürzungsverzeichnis]
      #print-glossary(entry-list, disable-back-references: true)
   ],
   statutory_declaration: [Hiermit erkläre ich, dass ich die vorliegende Arbeit eigenständig und ohne unerlaubte fremde Hilfe angefertigt habe. Textpassagen, die wörtlich oder dem Sinn nach auf Publikationen oder Vorträgen anderer Autoren beruhen, sind als solche kenntlich gemacht. Der Einsatz von KI-Werkzeugen erfolgte ausschließlich im Rahmen der nachstehenden Erklärung zur Nutzung von KI-Werkzeugen. Die Arbeit wurde bisher keiner anderen Prüfungsbehörde vorgelegt und auch noch nicht veröffentlicht.],
)

// Jedes Kapitel beginnt auf einer neuen Seite. Der Umbruch steht vor der
// Überschrift und nicht in ihr, sonst verzeichnet Typst die Überschrift auf der
// vorigen Seite, und Inhaltsverzeichnis und Kopfzeile nennen eine Seite zu früh.
#pagebreak(weak: true)
#include "chapters/01_introduction.typ"
#pagebreak(weak: true)
#include "chapters/02_related_work.typ"
#pagebreak(weak: true)
#include "chapters/03_system_requirements.typ"
#pagebreak(weak: true)
#include "chapters/04_architektur.typ"
#pagebreak(weak: true)
#include "chapters/05_entwurf.typ"
#pagebreak(weak: true)
#include "chapters/06_referenzimplementierung.typ"
#pagebreak(weak: true)
#include "chapters/07_evaluation.typ"
#pagebreak(weak: true)
#include "chapters/08_fazit.typ"

#pagebreak()
#bibliography("biblio.bib")

#pagebreak(weak: true)
#include "chapters/0100_anhang.typ"