#import "template/template.typ": *
#import "@preview/wrap-it:0.1.1"
#import "@preview/glossarium:0.5.10": make-glossary, register-glossary, print-glossary, gls, glspl
#import "chapters/00_0_abkürzungen.typ": *
#import "chapters/00_01_abstract.typ": *

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
   statutory_declaration: [Hiermit erkläre ich, dass ich die vorliegende Arbeit eigenständig und ohne unerlaubte fremde Hilfe angefertigt habe. Textpassagen, die wörtlich oder dem Sinn nach auf Publikationen oder Vorträgen anderer Autoren beruhen, sind als solche kenntlich gemacht. Der Einsatz von KI-Werkzeugen erfolgte ausschließlich im Rahmen der nachstehenden Erklärung zur Nutzung von KI-Werkzeugen. Die Arbeit wurde bisher keiner anderen Prüfungsbehörde vorgelegt und auch noch nicht veröffentlicht.],
)

#include "chapters/01_introduction.typ"
#include "chapters/02_related_work.typ"
#include "chapters/03_system_requirements.typ"
#include "chapters/04_architektur.typ"
#include "chapters/05_entwurf.typ"
#include "chapters/06_referenzimplementierung.typ"
#include "chapters/07_evaluation.typ"
#include "chapters/08_fazit.typ"

#pagebreak()

#page(
  grid(
    [= Abbildungs- und Tabellenverzeichnis],
    inset: (x: 0pt, y: 20pt),
    outline(
      title: [Abbildungsverzeichnis],
      target: figure.where(kind: image),
    ),
    outline(
      title: [Tabellenverzeichnis],
      target: figure.where(kind: table),
    ),
    outline(
      title: [Code-Listings],

      target: figure.where(kind: raw),
    ),
  ),
)

#pagebreak()
= Abkürzungsverzeichnis

#print-glossary(entry-list, disable-back-references: true)

#pagebreak()
#bibliography("biblio.bib")

#include "chapters/0100_anhang.typ"