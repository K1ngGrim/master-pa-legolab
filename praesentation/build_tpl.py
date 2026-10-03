import copy
from pptx import Presentation
from pptx.util import Emu, Pt, Inches
from pptx.dml.color import RGBColor
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE, XL_LEGEND_POSITION
from pptx.oxml.ns import qn
from lxml import etree

DARK=RGBColor(0x0F,0x2E,0x2E); GREY=RGBColor(0x5B,0x6B,0x6B); LIGHT=RGBColor(0xF3,0xF3,0xF3); WHITE=RGBColor(255,255,255)
A="http://schemas.openxmlformats.org/drawingml/2006/main"
prs=Presentation('template.pptx')
# alle Beispielfolien entfernen
sldIdLst=prs.slides._sldIdLst
for sldId in list(sldIdLst):
    prs.part.drop_rel(sldId.rId); sldIdLst.remove(sldId)
L_TITLE,L_SECTION,L_BODY,L_ONLY=prs.slide_layouts[0],prs.slide_layouts[1],prs.slide_layouts[2],prs.slide_layouts[4]
X0=311700; XR=8450000; W=XR-X0

def run_fmt(r,size,color,bold=False,italic=False,font="Calibri"):
    r.font.size=Pt(size); r.font.bold=bold; r.font.italic=italic; r.font.name=font; r.font.color.rgb=color

def set_title(slide,text,size=25):
    t=slide.shapes.title; tf=t.text_frame; tf.clear()
    r=tf.paragraphs[0].add_run(); r.text=text; run_fmt(r,size,DARK)

def ppr(par,marL,indent,bullet,spc=0):
    pPr=par._p.get_or_add_pPr()
    pPr.set('marL',str(marL)); pPr.set('indent',str(indent))
    for ch in list(pPr): pPr.remove(ch)
    sb=etree.SubElement(pPr,qn('a:spcBef')); etree.SubElement(sb,qn('a:spcPts')).set('val',str(spc))
    if bullet:
        c=etree.SubElement(pPr,qn('a:buClr')); etree.SubElement(c,qn('a:srgbClr')).set('val','0F2E2E')
        etree.SubElement(pPr,qn('a:buSzPts')).set('val','1400')
        etree.SubElement(pPr,qn('a:buFont')).set('typeface','Calibri')
        etree.SubElement(pPr,qn('a:buChar')).set('char','●')
    else:
        etree.SubElement(pPr,qn('a:buNone'))

def fill(tf,items,size=16,dsize=None):
    """items: ('h',Überschrift,Detail) | ('b',Text) | ('p',Text)"""
    dsize=dsize or size
    tf.clear(); tf.word_wrap=True
    first=True
    for it in items:
        par=tf.paragraphs[0] if first else tf.add_paragraph()
        spc=0 if first else (900 if it[0]!='d' else 100)
        first=False
        if it[0]=='h':
            ppr(par,457200,-330200,True,spc); r=par.add_run(); r.text=it[1]; run_fmt(r,size,DARK,bold=True)
            if len(it)>2 and it[2]:
                p2=tf.add_paragraph(); ppr(p2,457200,0,False,100); r2=p2.add_run(); r2.text=it[2]; run_fmt(r2,dsize,GREY)
        elif it[0]=='b':
            ppr(par,457200,-330200,True,spc); r=par.add_run(); r.text=it[1]; run_fmt(r,size,DARK)
        else:
            ppr(par,0,0,False,spc); r=par.add_run(); r.text=it[1]; run_fmt(r,size,GREY,italic=True)

def new(layout,title,notes=None,tsize=25):
    s=prs.slides.add_slide(layout)
    if title is not None: set_title(s,title,tsize)
    if notes: s.notes_slide.notes_text_frame.text=notes
    return s

def body(s,items,size=16,dsize=None,x=X0,y=1152475,w=W,h=3416400):
    b=s.placeholders[1]; b.left,b.top,b.width,b.height=x,y,w,h
    fill(b.text_frame,items,size,dsize); return b

def code(s,lines,x,y,w,h,size=11):
    tb=s.shapes.add_textbox(x,y,w,h); tb.fill.solid(); tb.fill.fore_color.rgb=LIGHT
    tf=tb.text_frame; tf.word_wrap=True
    tf.margin_left=tf.margin_right=Emu(91425); tf.margin_top=tf.margin_bottom=Emu(70000)
    for i,l in enumerate(lines):
        par=tf.paragraphs[0] if i==0 else tf.add_paragraph()
        r=par.add_run(); r.text=l if l else " "
        run_fmt(r,size,GREY if l.strip().startswith("#") else DARK,font="Courier New")
    return tb

def table(s,head,rows,x,y,w,colw,size=12,rowh=300000):
    gs=s.shapes.add_table(len(rows)+1,len(head),x,y,w,rowh*(len(rows)+1))
    tbl=gs.table
    tblPr=tbl._tbl.tblPr
    for a in ('firstRow','bandRow'): tblPr.set(a,'0')
    sid=tblPr.find(qn('a:tableStyleId'))
    if sid is None: sid=etree.SubElement(tblPr,qn('a:tableStyleId'))
    sid.text='{2D5ABB26-0587-4C30-8999-92F81FD0307C}'
    tot=sum(colw)
    for i,cw in enumerate(colw): tbl.columns[i].width=int(w*cw/tot)
    for r in range(len(rows)+1): tbl.rows[r].height=rowh
    for r,row in enumerate([head]+rows):
        for c,val in enumerate(row):
            cell=tbl.cell(r,c); cell.fill.solid()
            cell.fill.fore_color.rgb = DARK if r==0 else (LIGHT if r%2==0 else WHITE)
            cell.margin_left=cell.margin_right=Emu(70000); cell.margin_top=cell.margin_bottom=Emu(30000)
            tcPr=cell._tc.get_or_add_tcPr()
            for tag in ('a:lnL','a:lnR','a:lnT','a:lnB'):
                ln=etree.SubElement(tcPr,qn(tag)); ln.set('w','6350')
                sf=etree.SubElement(ln,qn('a:solidFill')); etree.SubElement(sf,qn('a:srgbClr')).set('val','D0D5D5')
            tcPr.insert(len(tcPr)-1,tcPr[-1]) if False else None
            tf=cell.text_frame; tf.word_wrap=True
            r_=tf.paragraphs[0].add_run(); r_.text=val
            run_fmt(r_,size,WHITE if r==0 else DARK,bold=(r==0 or c==0))
    return gs

def pic(s,path,x,y,w=None,h=None):
    return s.shapes.add_picture(path,x,y,width=w,height=h)

def section(title,sub=None,notes=None):
    s=new(L_SECTION,title,notes,tsize=36)
    return s

IN=914400
# ---------------------------------------------------------------- 1 Titel
s=prs.slides.add_slide(L_TITLE)
s.notes_slide.notes_text_frame.text="Begrüßung. Thema in einem Satz: Wie bringt man ein Touch-Display an den SPIKE Prime Hub, obwohl die Verbindung dafür nicht gedacht ist? Kurz den Aufbau nennen: Problem, Architektur, Entwurf, Referenzimplementierung, Evaluation, Nutzung. (1 min)"
tf=s.shapes.title.text_frame; tf.clear(); r=tf.paragraphs[0].add_run(); r.text="Entfernte Objekte über einen 16-Byte-Bus"; run_fmt(r,40,DARK)
sub=s.placeholders[1]; sub.text_frame.clear(); r=sub.text_frame.paragraphs[0].add_run(); r.text="Eine Middleware für ein Touchscreen-Display am LEGO SPIKE Prime Hub"; run_fmt(r,20,GREY)
tb=s.shapes.add_textbox(Emu(143250),Emu(4528625),Emu(8857500),Emu(397500)); r=tb.text_frame.paragraphs[0].add_run(); r.text="[Name]            [Datum]"; run_fmt(r,16,GREY,italic=True)
tb=s.shapes.add_textbox(Emu(5418100),Emu(175675),Emu(3578100),Emu(480900)); p_=tb.text_frame.paragraphs[0]; p_.alignment=3; r=p_.add_run(); r.text="Projektarbeit"; run_fmt(r,18,GREY)
# ---------------------------------------------------------------- 2 Agenda
s=new(L_BODY,"Agenda","Überblick über die sechs Teile. Schwerpunkt auf Entwurf und Referenzimplementierung.")
body(s,[('h',"Problem und Anforderungen","Ausgangslage, Einschränkungen, Ziel, K1–K6"),('h',"Architektur","Schichten, Rollen, Kommunikationsmodell"),('h',"Entwurf","Transportschicht und Kommunikationsschicht"),('h',"Referenzimplementierung","Bus, Frame, Codec, Objektmodell, Anzeige, Ablauf"),('h',"Evaluation","Funktion, Übertragungsaufwand, Reaktionszeit"),('h',"Nutzung und Ausblick","Display in zukünftigen Projekten verwenden")],size=14,dsize=12)
# ---------------------------------------------------------------- 3 Ausgangslage
s=new(L_BODY,"Ausgangslage","LEGO Education als niedrigschwelliger Einstieg. Der Wunsch nach Display und Touch. Der Hub ist geschlossen; Pybricks ersetzt die Firmware und erlaubt externe Geräte über LPF2/PUPRemote. (1,5 min)")
body(s,[('h',"SPIKE Prime Hub","Lernplattform für Programmierung und Robotik, läuft mit Pybricks (reduziertes MicroPython)."),('h',"Wunsch","Touch-Display für Anzeige und Bedienung direkt am Roboter, ohne Rechner."),('h',"Hindernis","Nur LED-Matrix und Tasten. Erweiterungen sind nur über die Sensorports möglich, keine offenen Schnittstellen wie SPI oder I²C."),('h',"Leitfrage","Wie bindet man Peripherie über eine Verbindung an, die dafür nur eingeschränkt geeignet ist?")])
# ---------------------------------------------------------------- 4 Problem
s=new(L_BODY,"Problemstellung - drei Einschränkungen zugleich","Jede für sich wäre handhabbar, zusammen verstärken sie sich: Der Server kann nichts von sich aus senden, also Polling. Nachrichten passen nicht in ein Paket, also Fragmentierung. Kein Threading, also blockiert der Client. (1,5 min)")
body(s,[('h',"Anfragegetrieben","Nur der Hub stößt Übertragungen an, das Display kann ausschließlich antworten."),('h',"16 Byte je Paket","Feste, sehr kleine Blockgröße. Übliche Nachrichten müssen zerlegt werden."),('h',"Beschränkte Laufzeit","Pybricks: keine Threads, kein Netzwerkstack, Ganzzahlen nur bis 2³⁰−1."),('p',"Interaktive Oberflächen brauchen das Gegenteil: strukturierte Daten und schnelle Rückmeldung.")])
# ---------------------------------------------------------------- 5 Ziel
s=new(L_BODY,"Zielsetzung","Zentrale Frage aus der Einleitung. Nicht ein einzelnes Display, sondern eine Softwareschicht, die auf andere Verbindungen derselben Klasse übertragbar ist. Drei Bewertungskriterien am Ende wieder aufgreifen. (1,5 min)")
body(s,[('h',"Forschungsfrage","Wie lässt sich eine Middleware entwerfen, die entfernte Objekte über eine anfragegetriebene Verbindung mit sehr kleiner Paketgröße auf beschränkten Laufzeitumgebungen transparent nutzbar macht?"),('h',"Entwurf","Einschränkungen auf wenige Schichten begrenzen, vom Übertragungsweg lösen."),('h',"Umsetzung","Referenzimplementierung: Touch-Display am SPIKE Prime Hub."),('h',"Bewertung","Funktionaler Nachweis, Übertragungsaufwand je Aufruf, Ressourcenverbrauch.")],size=15)
# ---------------------------------------------------------------- 6 Anforderungen
s=new(L_BODY,"Anforderungen an die Kommunikation","Sechs Anforderungen aus dem Anwendungsfall einer interaktiven Oberfläche, nicht aus dem Bus. K1–K3 betreffen den Inhalt, K4 und K5 die Bedingungen, K6 den Aufbau. K4 (100 ms nach Miller und Card) wird später der spannende Punkt. (2 min)")
body(s,[('h',"K1 - Strukturierte Nachrichten unbestimmter Länge","Ein Button besteht aus Position, Größe und Text."),('h',"K2 - Aufrufe mit zuordenbarem Ergebnis","Zu jeder Anfrage gehört erkennbar eine Antwort."),('h',"K3 - Rückfluss von Ereignissen","Touch ohne Verlust, oder der Verlust ist erkennbar."),('h',"K4 - Antwortzeit unter 100 ms","Grenze direkter Manipulation."),('h',"K5 - Begrenzter Speicherbedarf","Feste Obergrenzen der Puffer."),('h',"K6 - Unabhängigkeit vom Übertragungsweg","Wegabhängiges liegt an einer Stelle.")],size=14,dsize=12)
# ---------------------------------------------------------------- 7 Hardware
s=new(L_BODY,"Hardwareaufbau","Bewusst handelsübliche Baugruppen: LMS-ESP32 am Sensorport, ILI9341-Display mit kapazitivem Touch, eigene Adapterplatine ohne aktive Bauteile (KiCad). Der ESP32 gibt sich dem Hub gegenüber als Ultraschallsensor aus und fordert die 8-V-Versorgung an. Hardware ist Träger, nicht Beitrag. (1 min)")
body(s,[('h',"LMS-ESP32","MicroPython + LVGL, am Sensorport des Hubs"),('h',"Display","ILI9341 (SPI), Touchcontroller (I²C)"),('h',"Adapterplatine","Nur Steckverbinder, Baugruppen ohne Löten tauschbar")],size=14,dsize=12,h=1700000)
w=int(6.2*IN); pic(s,"img/3d_render.png",X0,3050000,w=w)
# ---------------------------------------------------------------- Section Architektur
section("Architektur",notes="Überleitung.")
# ---------------------------------------------------------------- Schichtenmodell
s=new(L_ONLY,"Schichtenmodell - fünf Schichten, zwei Seiten","Kernidee: Alles, was vom Übertragungsweg abhängt, steckt in der untersten Schicht. Symmetrisch: Client = Hub ruft auf, Server = ESP32 führt aus. Streng geschichtet. (2 min)")
table(s,["Client (Hub, Pybricks)","Server (ESP32, MicroPython)"],[["Anwendung","Anzeige und Eingabe"],["Objektmodell","Objektmodell"],["Kommunikationsschicht","Kommunikationsschicht"],["Transportschicht","Transportschicht"],["Busanbindung","Busanbindung"],["Bus: feste Blockgröße (16 Byte), anfragegetrieben",""]],X0,1250000,W,[1,1],size=15,rowh=380000)
tb=s.shapes.add_textbox(X0,3950000,W,500000); tb.text_frame.word_wrap=True; r=tb.text_frame.paragraphs[0].add_run(); r.text="Symmetrisch aufgebaut, streng geschichtet: jede Schicht spricht nur mit der direkt darunterliegenden."; run_fmt(r,14,GREY,italic=True)
# ---------------------------------------------------------------- Aufgaben
s=new(L_ONLY,"Aufgaben der Schichten","Zu jeder Schicht: Aufgabe und was sie nach oben verbirgt. Transportschicht: Paketgröße. Kommunikationsschicht: der Rückkanal, ein Aufruf erscheint als synchroner Methodenaufruf. Objektmodell: Aufrufstransparenz. (2 min)")
table(s,["Schicht","Aufgabe","Verbirgt nach oben"],[["Busanbindung","Block fester Größe befördern","den Übertragungsweg"],["Transport","Serialisierung, Rahmung, Fragmentierung","die Paketgröße"],["Kommunikation","Aufruf als Nachricht, Ergebnis zuordnen, Rückkanal","Übertragung und Warten"],["Objektmodell","Entfernte Objekte, Stellvertreter, Referenzen","dass das Objekt entfernt ist"],["Anwendung / Anzeige","Programm des Hubs / Darstellung und Touch","-"]],X0,1250000,W,[1.6,3.4,2.2],size=13,rowh=480000)
# ---------------------------------------------------------------- Rollen
s=new(L_BODY,"Drei wiederkehrende Rollen","Interceptor: einziger Ansatzpunkt für den Übertragungsweg (angelehnt an POSA, aber hier wird ein Weg ausgetauscht, kein Dienst ergänzt). Dispatcher: Scope wählt den Empfänger. Stellvertreter und Adapter erfüllen dieselbe Schnittstelle, daraus folgt die Aufrufstransparenz. (2 min)")
body(s,[('h',"Interceptor","Schnittstelle zwischen Kommunikationsschicht und Busanbindung. Client: verpackt Aufruf, sendet Pakete, holt Ergebnis. Server: nimmt Pakete an, setzt zusammen, stellt Ergebnis bereit. Ansatzpunkt für K6."),('h',"Dispatcher","Ordnet eine Nachricht der Methode zu: der Scope wählt den Empfänger, dort wird die Methode aufgerufen. Ein Empfänger je Objekttyp."),('h',"Stellvertreter und Adapter","Zwei Seiten desselben Objekttyps. Der Stellvertreter (Client) leitet jeden Aufruf weiter, der Adapter (Server) enthält die Logik. Gemeinsame Schnittstelle = Aufrufstransparenz.")],size=16,dsize=14)
# ---------------------------------------------------------------- Kommunikationsmodell
s=new(L_BODY,"Kommunikationsmodell - zwei Kanäle","Aus Sicht der Anwendung synchron, intern anfragegetrieben. Kanal 1: Client sendet Pakete, Server bestätigt jedes. Kanal 2: Client fragt Ergebnis oder Ereignisse ab. Ereignisse folgen demselben Prinzip, daher hängt die zeitliche Auflösung am Abfragetakt. (2 min)")
body(s,[('h',"Aus Sicht der Anwendung synchron","Ein Aufruf kehrt zurück, sobald das Ergebnis vorliegt."),('h',"Kanal 1 - Aufruf senden","Client sendet die Pakete eines Aufrufs, der Server bestätigt jedes Paket."),('h',"Kanal 2 - Zustand abfragen","Client prüft, ob ein Ergebnis bereitliegt, und holt es Paket für Paket ab."),('h',"Ereignisse","Server puffert Berührungen, Client fragt bei Bedarf ab. Die zeitliche Auflösung ist damit an den Takt des Clients gebunden.")],size=16,dsize=14)
# ---------------------------------------------------------------- Section Entwurf
section("Entwurf",notes="Erster Schwerpunkt. Jede Entscheidung mit ihrer Begründung zeigen. (ca. 10 min für den Abschnitt)")
# ---------------------------------------------------------------- Interceptor
s=new(L_BODY,"Interceptor - eine einzige Operation","Der Client sendet einen Block und bekommt im selben Vorgang einen Block zurück. Ob Nutzlast, Bestätigung oder Anfrage, ist der Schnittstelle egal. Bewusst die Schnittmenge dessen, was alle Verbindungen der Klasse können. Beide Seiten erfüllen dieselbe Schnittstelle. (2 min)")
body(s,[('h',"Block rein, Block raus","Die Schnittstelle befördert nur, sie liest den Inhalt nicht."),('h',"Schnittmenge der Verbindungsklasse","Kein Senden ohne Anfrage, kein Warten auf eine Meldung des Servers."),('h',"Symmetrisch","Beide Seiten unterscheiden sich nur in der Richtung, aus der ein Block eintrifft."),('h',"Erfüllt K6","Ein anderer Weg heißt: eine neue Umsetzung dieser einen Operation.")],size=15,dsize=13,w=4900000)
h=int(3.3*IN); pic(s,"img/interceptor_ablauf.png",5450000,1100000,h=h)
# ---------------------------------------------------------------- Frame-Struktur
s=new(L_BODY,"Frame-Struktur - fünf notwendige Felder","Aus unabhängigen Blöcken wird eine Nachricht beliebiger Länge. Kennung: veraltete Antworten erkennen, denn direkt nach dem Senden wird gelesen. Position: Reihenfolge und Wiederholungen. Art: Nutzlast und Steuerinformationen laufen über denselben Kanal. Ende: sonst wartet der Empfänger bei exaktem Vielfachen auf einen Block, der nie kommt. Größen bewusst offen. (2 min)")
body(s,[('h',"Zugehörigkeit","Kennung der Nachricht, macht veraltete Antworten erkennbar."),('h',"Position","Reihenfolge und Erkennung von Wiederholungen."),('h',"Art","Nutzlast, Bestätigung, Anfrage oder Fehler."),('h',"Länge der Nutzlast","Wie viele Bytes des Blocks wirklich Nutzlast sind."),('h',"Ende der Nachricht","Explizit markiert; ein nicht voller Block genügt nicht als Kennzeichen."),('p',"Größe und Format der Felder sind im Entwurf bewusst offen.")],size=15,dsize=13)
# ---------------------------------------------------------------- Längenfeld + Kosten
s=new(L_BODY,"Längenfeld und Kosten der Rahmung","Ohne Längenfeld ist man an textbasierte Formate gebunden, weil Füllbytes nur dort eindeutig erkennbar sind. Binäre Formate wie MessagePack oder CBOR enthalten Nullbytes. Kosten: jedes Header-Byte fehlt der Nutzlast; ein Byte weniger verschiebt alle Blockgrenzen. Erwartung: Rahmung wiegt schwerer als das Format, wird in der Evaluation geprüft. (2,5 min)")
body(s,[('h',"Warum ein Längenfeld?","Textformate: Füllbytes am Blockende erkennbar. Binäre Formate enthalten Nullbytes, Abschneiden zerstört Nutzlast. Längenfeld = Formatunabhängigkeit."),('h',"Kosten der Rahmung","Jedes Header-Byte fehlt der Nutzlast. Ein Byte weniger verschiebt alle Blockgrenzen und kann einen ganzen Round Trip sparen."),('h',"Erwartung","Die Rahmung wirkt stärker auf die Zahl der Übertragungen als das Format.")],size=15,dsize=13,w=4700000)
code(s,["P = MTU - H","b = ceil(log2(P + 1))","","N = ceil(L / P)","eta = L / (N * MTU)","","P: Nutzlast je Frame","b: Breite des Längenfelds","N: Anzahl der Frames"],5200000,1250000,3250000,2700000,size=12)
# ---------------------------------------------------------------- Fragmentierung
s=new(L_BODY,"Fragmentierung und Rekonstruktion","Zerlegung eindeutig: gleiche Position gibt gleichen Block, also idempotent. Vollständig, wenn jede Position von 0 bis n eingetroffen ist, n trägt die Endmarkierung. Abbruch wird an Position 0 einer neuen Nachricht erkannt, nicht an der Kennung. Entscheidung: unvollständige Nachricht verwerfen, weil nur eine Nachricht gleichzeitig unterwegs ist. Speicher: L_max = 2^b_pos · P. (2,5 min)")
body(s,[('h',"Wann ist eine Nachricht vollständig?","Endmarkierung an Position n bedeutet n+1 Blöcke. Vollständig, sobald jede Position 0..n mindestens einmal eingetroffen ist."),('h',"Wiederholungen","Ein wiederholter Block hat denselben Inhalt; die Rekonstruktion verwirft Blöcke, deren Position schon vorliegt (idempotent)."),('h',"Abgebrochene Übertragung","Erkennbar erst an Position 0 einer neuen Nachricht. Entscheidung: Reste verwerfen, es ist ohnehin nur eine Nachricht unterwegs."),('h',"Speicher (K5)","Obergrenze L_max = 2^b_pos · P folgt aus der Positionsbreite und ist die Puffergröße der Gegenseite.")],size=15,dsize=13)
# ---------------------------------------------------------------- Serialisierung
s=new(L_BODY,"Serialisierung - drei Kriterien","Drei Kriterien aus den bisherigen Abschnitten. Kompakt: Länge bestimmt die Blockzahl. Ohne Schema: Objekte und Methoden ändern sich während der Entwicklung, ein Schema würde einen Übersetzungsschritt einführen. Kleiner Decoder: läuft auf beiden Mikrocontrollern. (1,5 min)")
body(s,[('h',"Kompakt","Die Länge der Nutzlast bestimmt nach N = ⌈L/P⌉ die Anzahl der Übertragungen."),('h',"Schemafrei","Objekte und Methoden ändern sich während der Entwicklung; ein Schema würde einen Übersetzungsschritt einführen."),('h',"Kleiner Decoder","Er läuft auf beiden Seiten, beide sind Mikrocontroller (K5 gilt auch für die Bibliothek)."),('p',"Welches Format die Bedingungen erfüllt, zeigt die Referenzimplementierung.")])
# ---------------------------------------------------------------- Zuverlässigkeit
s=new(L_BODY,"Zuverlässigkeit - Stop-and-Wait","Stop-and-Wait, weil ohnehin nie mehr als ein Block unterwegs ist; Fenster-Verfahren setzen mehrere Blöcke und Bestätigungen ohne Anfrage voraus. Obergrenzen für Wiederholungen und Abholen, sonst Stillstand. At-most-once: eine doppelt ausgeführte Änderung wäre nicht rückgängig zu machen, ein gescheiterter Aufruf ist wiederholbar. (2,5 min)")
body(s,[('h',"Stop-and-Wait","Block senden, auf Bestätigung warten, sonst wiederholen. Fenster-Verfahren sind nicht möglich: nie mehr als ein Block unterwegs."),('h',"Obergrenzen","Für Wiederholungen und für das Abholen des Ergebnisses, sonst wartet der Client endlos."),('h',"Jeder Aufruf hinterlässt etwas","Ein Ergebnis oder eine Fehlermeldung, auch wenn die Ausführung scheitert."),('h',"At-most-once","Wiederholter Block wird verworfen, wiederholter letzter Block löst keine zweite Ausführung aus.")],size=15,dsize=13)
# ---------------------------------------------------------------- Kommunikationsschicht
s=new(L_BODY,"Kommunikationsschicht - der entfernte Aufruf","Aufrufnachricht: Methodenkennung, Argumente in Parameterreihenfolge ohne Namen, Scope. Keine Typen, weil das Format schemafrei ist; die Vereinbarung ist die gemeinsame Schnittstelle. Zuordnung: Kennung aus dem Frame-Header (Abwägung zwischen doppelten Steuerinformationen und strenger Trennung). Verteilung analog zu REST-Routing. Rückkanal: Ergebnis kann nur bereitgehalten werden. (3 min)")
body(s,[('h',"Aufrufnachricht","Methodenkennung fester Länge (aus dem Namen berechnet), Argumente nach Position, Scope. Keine Typangaben: Fehler zeigen sich erst zur Laufzeit."),('h',"Anfrage und Antwort","Ein Aufruf ist eine Nachricht; die Kennung stammt aus dem Frame-Header, das spart Übertragungen."),('h',"Verteilung","Zweistufig: Scope wählt den Empfänger, dann die Methode. Referenz des Objekts reist als Argument. Unbekannter Scope wird mit Fehlermeldung beantwortet."),('h',"Rückkanal","Der Server kann ein Ergebnis nur bereithalten. Ereignisse muss der Client regelmäßig abfragen; häufiger abfragen verkürzt die Verzögerung, kostet aber Übertragungen.")],size=14,dsize=12)
# ---------------------------------------------------------------- Section Referenz
section("Referenzimplementierung",notes="Zweiter Schwerpunkt. An konkretem Code zeigen, wie der Entwurf abgebildet wurde und was die Laufzeit erzwungen hat. (ca. 12 min)")
# ---------------------------------------------------------------- Laufzeit
s=new(L_BODY,"Laufzeitumgebungen und Module","Client und Server laufen beide unter MicroPython, aber sehr verschieden. Gemeinsamer Code richtet sich nach der engeren Umgebung, also Pybricks. Der Hub nimmt nur einzelne Dateien an: der Bundler fasst alle Module zu pybricks_bundle.py zusammen. Rechts die Zuordnung der Module zu Schichten. (2 min)")
body(s,[('h',"Hub - Pybricks","Ganzzahlen < 2³⁰, keine Threads, nur einzelne Dateien."),('h',"ESP32 - MicroPython + LVGL","Umfangreich, aber Heap knapp. Gemeinsamer Code richtet sich nach Pybricks."),('h',"Bundler","tools/bundler.py erzeugt pybricks_bundle.py.")],size=15,dsize=13,w=3700000)
table(s,["Schicht","Module"],[["Anwendung/Anzeige","hub/main.py, display/server/driver/"],["Objektmodell","display/protocol, client, server, registry.py"],["Kommunikation","dispatcher.py, names.py, errors.py"],["Transport","frame.py, message.py, codec.py"],["Busanbindung","transport/base.py, pupremote/binding.py"]],4150000,1250000,4300000,[1.4,2.6],size=11,rowh=420000)
# ---------------------------------------------------------------- Bus
s=new(L_BODY,"Busanbindung - PUPRemote, ein Kommando","Die Busanbindung wird vorgefunden. PUPRemote 1.6 setzt LPF2 um; der ESP32 gibt sich als Ultraschallsensor aus. Handshake bei 2400 Baud, danach 115200 Baud. PUPRemote hat eine eigene Aufrufsemantik, die nicht genutzt wird: nur ein Kommando xfer mit 16 Byte in beide Richtungen. Ein Austausch ist remote.call: schreiben, dann sofort lesen; ist der ESP noch nicht fertig, kommt die vorige Antwort. (2,5 min)")
body(s,[('h',"PUPRemote 1.6","Client: PUPRemoteHub, Server: PUPRemoteSensor. Der ESP32 gibt sich als Ultraschallsensor aus."),('h',"Ein Kommando","xfer: 16 Byte in beide Richtungen, ohne Struktur für PUPRemote."),('h',"Grenzen","Blockgröße max. 16 Byte, Kommandonamen höchstens 5 Zeichen."),('h',"Veraltete Antwort","Lesen ohne Wartezeit liefert ggf. die vorige Antwort. Erkennung über Position und Art des Frames.")],size=14,dsize=12,w=4300000)
code(s,['COMMAND = "xfer"','','def register_interceptor(self):','    self.remote.add_command(','        self.COMMAND,','        from_hub_fmt=f"{FRAME_SIZE}s",','        to_hub_fmt=f"{FRAME_SIZE}s",','    )'],4800000,1250000,3650000,2300000,size=10)
# ---------------------------------------------------------------- Frame
s=new(L_BODY,"Frame - 3 Byte Header, 13 Byte Nutzlast","Blockgröße 16 fest. Header drei Byte: Kennung 8 Bit, Position 8 Bit, Art 4 Bit und Länge 4 Bit teilen sich ein Byte. Aus P = 13 folgt b = ceil(log2 14) = 4. Gültig bis Nutzlast 15 Byte, also MTU höchstens 18. Position 0xFF reserviert: 255 Positionen · 13 Byte = 3315 Byte maximale Nachricht, zugleich Puffergrenze (K5). (2,5 min)")
table(s,["Byte","Bits","Inhalt"],[["0","8","Kennung der Nachricht"],["1","8","Position innerhalb der Nachricht"],["2","4 obere","Art des Frames"],["2","4 untere","Länge der Nutzlast"],["3-15","13 Byte","Nutzlast"]],X0,1250000,W,[1,1.2,4],size=14,rowh=400000)
tb=s.shapes.add_textbox(X0,3950000,W,800000); tb.text_frame.word_wrap=True
fill(tb.text_frame,[('b',"255 Positionen × 13 Byte = 3315 Byte je Nachricht; diese Obergrenze ist der Puffer nach K5."),('b',"Art: 8 von 16 Werten belegt, ein Bit sparen brächte nichts.")],size=14)
# ---------------------------------------------------------------- Opcodes
s=new(L_ONLY,"Art des Frames","Acht Arten. DATA und DATA_LAST tragen Nutzlast, ACK und NACK bestätigen, READY und NEXT sind die Abfragen des Rückkanals, DONE ist die Antwort auf READY, ERR ist die Fehlermeldung. (1 min)")
table(s,["Wert","Name","Bedeutung"],[["0x0","DATA","Nutzlastframe, weitere folgen"],["0x1","DATA_LAST","Nutzlastframe, letzter der Nachricht"],["0x2","ACK","Bestätigung eines empfangenen Frames"],["0x3","NACK","Ergebnis noch nicht bereit / nichts weiter vorhanden"],["0x4","ERR","Fehlermeldung, kann kurze Beschreibung tragen"],["0x5","READY","Anfrage, ob ein Ergebnis bereitliegt"],["0x6","NEXT","Anfrage nach dem Ergebnisframe an der Position"],["0x7","DONE","Antwort auf READY: Ergebnis liegt bereit"]],X0,1200000,W,[0.8,1.4,4.5],size=13,rowh=380000)
# ---------------------------------------------------------------- Message
s=new(L_BODY,"Message - Frames aus dem Index","frame_at berechnet den Frame direkt aus dem Index, ohne Fortschritt: gleiche Position gleicher Frame. Ein früherer Generator wurde verworfen, weil er Wiederholungen erschwerte. Rückkanal nutzt collect_frame (sammelt und sortiert), der Hinweg append_frame (spart Speicher, setzt Reihenfolge voraus). (2 min)")
code(s,["def frame_at(self, index):","    start = index * PAYLOAD_SIZE","    if start >= len(self.payload) and \\","       not (index == 0 and not self.payload):","        return None","    chunk = self.payload[start:start+PAYLOAD_SIZE]","    last = start + PAYLOAD_SIZE >= len(self.payload)","    return Frame(self.g_id, index % 256,","        OP_DATA_LAST if last else OP_DATA, chunk)"],X0,1200000,4700000,2700000,size=10)
body(s,[('h',"Gleiche Position, gleicher Frame","Wiederholte Anfragen im Rückkanal sind unkritisch."),('h',"Generator verworfen","Er erschwerte das Wiederholen einzelner Frames."),('h',"Zwei Wege zum Einsammeln","collect_frame (Rückkanal) sortiert, append_frame (Hinweg) setzt die Reihenfolge voraus.")],size=14,dsize=12,x=5200000,w=3250000)
# ---------------------------------------------------------------- Codec
s=new(L_BODY,"Codec - Serialisierung an einer Stelle","Eine einzige Zuweisung legt das Format fest. MessagePack-Teilmenge: Wahrheitswerte, Ganzzahlen bis 16 Bit, Strings, Bytes, Listen, Maps; keine Floats. 16 Bit wegen 2^30 auf dem Hub. JSON war die erste Umsetzung (lesbar) und bleibt für Mitschnitte erhalten. Der Wechsel ist nur möglich, weil die Rahmung die Länge mitführt. (2 min)")
body(s,[('h',"Schnittstelle","encode: Objekt zu Bytes, decode: Bytes zu Objekt. Eine Zuweisung wählt den Codec."),('h',"MessagePack-Teilmenge","Nur die tatsächlich genutzten Typen, Ganzzahlen bis 16 Bit (Hub: Konstanten < 2³⁰). Ein kleiner Decoder auf beiden Seiten."),('h',"JSON","Erste Umsetzung, im Klartext lesbar, bleibt für Mitschnitte erhalten."),('h',"Voraussetzung","Binär nur möglich, weil die Rahmung die Länge der Nutzlast mitführt.")],size=14,dsize=12,w=5000000)
pic(s,"img/codec.png",5650000,1150000,h=int(3.2*IN))
# ---------------------------------------------------------------- Aufrufnachricht
s=new(L_BODY,"Aufrufnachricht und Methodenkennung","Drei Ausprägungen der Nutzlast mit einbuchstabigen Schlüsseln. Methodenkennung: djb2 auf 16 Bit begrenzt, nicht das eingebaute hash (CPython randomisiert, MicroPython rechnet anders). Maskierung hält Zwischenwerte unter 2^30, ein 32-Bit-Hash wie FNV würde die Grenze des Hubs reißen. 16 Bit: drei Byte statt 13 für den Namen create_label; 8 Bit hätten bei zehn Methoden etwa 16 % Kollisionswahrscheinlichkeit. Kollision wird beim Start erkannt. (3 min)")
table(s,["Nutzlast","Schlüssel","Inhalt"],[["CommandPayload","s, c, a","Scope, Methodenkennung, Argumente"],["DataPayload","d","Rückgabewert"],["ErrorPayload","e, k","Fehlerbeschreibung, Fehlerart"]],X0,1200000,W,[1.6,1,3.6],size=13,rowh=360000)
code(s,["def name_hash(name):","    h = 5381","    for ch in name:","        h = ((h * 33) ^ ord(ch)) & 0xFFFF","    return h"],X0,2850000,3900000,1500000,size=11)
body(s,[('b',"djb2 auf 16 Bit, eingebautes hash() ungeeignet"),('b',"Maskierung hält Werte < 2³⁰"),('b',"Kollision bei 10 Methoden: 0,069 % (16 Bit) statt 16,3 % (8 Bit)"),('b',"Kollision wird beim Start erkannt")],size=13,x=4350000,y=2800000,w=4100000,h=1700000)
# ---------------------------------------------------------------- Verteilung+Rückkanal
s=new(L_BODY,"Verteilung und Rückkanal","Dispatcher-Pool: ein Dispatcher je Scope, doppelte Belegung wirft beim Start eine Ausnahme. Rückkanal: READY fragt, ob das Ergebnis da ist, DONE oder NACK; NEXT holt Frame für Frame über die Position, wiederholte Anfrage liefert denselben Frame. Konstanten begrenzen den Speicher. Ereignisse: je Objekt zehn, ältestes wird bei Überlauf verworfen und gezählt. (3 min)")
code(s,["if frame.opcode == OP_READY:","    if self.__is_result_ready__(frame.g_id):","        return Frame.create_done(...)","    return Frame.create_no_ack(...)","","if frame.opcode == OP_NEXT:","    msg = self.outgoing.get(frame.g_id)","    res = msg.frame_at(frame.frame_nr)","    return res.to_bytes()"],X0,1200000,4400000,2500000,size=10)
table(s,["Konstante","Wert"],[["RESULT_POLL_MS","50 ms"],["MAX_RESULT_WAIT_MS","5000 ms"],["MAX_FRAME_ATTEMPTS","8"],["MAX_KEPT_RESULTS","4"],["MAX_EVENTS","10"]],4950000,1200000,3500000,[2.4,1],size=12,rowh=380000)
tb=s.shapes.add_textbox(X0,3900000,W,600000); tb.text_frame.word_wrap=True
fill(tb.text_frame,[('b',"Ereignisse: höchstens 10 je Objekt, ältestes wird bei Überlauf verworfen und gezählt."),('b',"Eine Abfrage leert den Puffer.")],size=13)
# ---------------------------------------------------------------- Objektmodell
s=new(L_BODY,"Objektmodell - Stellvertreter und Adapter","Je Objekttyp eine Basisklasse in display/protocol. Client: Stellvertreter hält ein RemoteObject (Referenz wird jedem Aufruf vorangestellt), erbt nicht davon, weil Pybricks keine Mehrfachvererbung hat. Server: Adapter erbt zusätzlich von RPCDispatcher und ist über seinen Scope erreichbar. Ein Button besteht auf dem Server aus zwei Objekten. (2 min)")
body(s,[('b',"Basisklasse je Typ in display/protocol"),('b',"Client: Stellvertreter, Server: Adapter"),('b',"Stellvertreter hält ein RemoteObject (keine Mehrfachvererbung in Pybricks)"),('b',"Adapter erbt von RPCDispatcher, erreichbar über den Scope"),('b',"Button = zwei Objekte (Button und Label)")],size=14,x=5000000,w=3450000)
h=int(3.4*IN); pic(s,"img/objektmodell.png",X0,1150000,h=h)
# ---------------------------------------------------------------- Referenzen
s=new(L_BODY,"Referenzen und veraltete Stellvertreter","Referenz = 16 Bit: untere 10 Bit Slot, obere 6 Bit Generation, die bei jeder Freigabe steigt (Generational Handle). Slot speichert Objekt, Generation, Art, Parent. Zwei Prüfungen gegen veraltete Referenzen: Server in der Registratur, Client über eine Session, die bei clear() und Verbindungsabbruch endet. Fehlerart bestimmt die Ausnahme (StaleReferenceError, WrongKindError, RemoteError). Restrisiko: Generation wiederholt sich nach 64 Freigaben. (3 min)")
code(s,["def _slot(self, ref):","    index = ref & SLOT_MASK","    slot = self._slots[index]","    if slot[2] is None or \\","       slot[0] != ref >> SLOT_BITS:","        return None","    return slot"],X0,1200000,3900000,1900000,size=11)
body(s,[('h',"Referenz: 16 Bit","10 Bit Slot, 6 Bit Generation (steigt bei jeder Freigabe)."),('h',"Zwei Prüfungen","Server prüft Generation und Art. Client: Session endet bei clear() und Verbindungsabbruch."),('h',"Ausnahmen","StaleReferenceError, WrongKindError, RemoteError."),('h',"Restrisiko","Generation wiederholt sich nach 64 Freigaben.")],size=14,dsize=12,x=4400000,w=4050000)
tb=s.shapes.add_textbox(X0,3250000,3900000,1200000); tb.text_frame.word_wrap=True
fill(tb.text_frame,[('b',"release_tree: Objekt samt Kindern freigeben"),('b',"clear(): leerer Screen laden, dann alle Screens löschen")],size=12)
# ---------------------------------------------------------------- Ansteuerung
s=new(L_BODY,"Ansteuerung der Anzeige und Bindings","LVGL zeichnet in eigenem Takt (40 ms gemessen); ein Adapter ändert nur den Zustand. Ereignisse: on_event legt sie im Puffer des Objekts ab. Zwei Fragen in einem Aufruf: aktueller Zustand und was seit der letzten Abfrage geschah. Ohne Trennung ginge eine kurze Berührung verloren. Bindings: Ereignis auf einem Objekt löst Aktion auf einem anderen aus, direkt auf dem Server, ohne Übertragung. Aktionen bewusst klein und ohne Logik. (3 min)")
body(s,[('h',"Darstellung","LVGL in MicroPython, ILI9341-Treiber. Zeichnen im festen Takt (40 ms); Adapter ändern nur den Zustand. Touch per Abfrage, Interrupt ungenutzt."),('h',"Ereignisse","Ein Aufruf liefert den aktuellen Zustand und die Drucke seit der letzten Abfrage. Ohne diese Trennung ginge ein kurzer Tipp verloren."),('h',"Bindings","Ein Ereignis auf Objekt A löst direkt auf dem Server eine Aktion auf Objekt B aus, ohne Übertragung. Aktionen: SHOW_SCREEN, SHOW, HIDE, TOGGLE.")],size=15,dsize=13)
# ---------------------------------------------------------------- Ablauf
s=new(L_BODY,"Ablauf eines Aufrufs - label.set_text(...)","Beispiel counter_label.set_text(\"Counter: 42\"). Stellvertreter prüft Session, übergibt an call(); Referenz wird vorangestellt. MessagePack kodiert 32 Byte, bei 13 Byte Nutzlast drei Frames. Jeder Frame ein Round Trip. Der letzte Frame wird bestätigt, bevor ausgeführt wird; die Ausführung läuft als eigener Task. Danach READY, dann NEXT für Position 0. Fünf Round Trips, drei tragen Nutzlast, zwei nur Steuerinformationen. (3 min)")
table(s,["Round Trip","Frame","Inhalt"],[["1","DATA","Nutzlast, Frame 0"],["2","DATA","Nutzlast, Frame 1"],["3","DATA_LAST","Nutzlast, letzte 6 Byte"],["4","READY","Ergebnis bereit? (Antwort DONE)"],["5","NEXT 0","Ergebnisframe abholen"]],X0,1200000,W,[1,1.4,3.6],size=13,rowh=360000)
tb=s.shapes.add_textbox(X0,3700000,W,1000000); tb.text_frame.word_wrap=True
fill(tb.text_frame,[('b',"Nachricht: 32 Byte MessagePack, also ⌈32/13⌉ = 3 Frames"),('b',"Nach Frame 3 bestätigt der Server, dann läuft die Ausführung als eigener Task"),('b',"Minimum: 5 Round Trips, davon zwei nur zum Abholen")],size=14)
# ---------------------------------------------------------------- Automat client
s=new(L_ONLY,"Zustände eines Aufrufs - Client","Automat für den Client: Senden, Warten, Abholen, Fehler. Jeder der drei Zustände hat eine eigene Obergrenze; danach Fehler und Ausnahme in der Anwendung. Zwischen Senden und DONE ist die Anwendung blockiert, es ist nur ein Aufruf unterwegs. (1,5 min)")
h=int(3.9*IN); w=int(h*1800/1086); pic(s,"img/automat_client.png",X0,1150000,w=w,h=h)
# ---------------------------------------------------------------- Automat server
s=new(L_BODY,"Zustände eines Aufrufs - Server","Server je Nachrichtenkennung. Zwei Kanten sind die eigentlichen Zusicherungen: bekannte Position wird bestätigt, aber nicht erneut abgelegt; wiederholter letzter Frame wird bestätigt, ohne ein zweites Mal auszuführen. Ergibt At-most-once. (1,5 min)")
h=int(3.7*IN); w=int(h*1400/1041); pic(s,"img/automat_server.png",X0,1150000,w=w,h=h)
body(s,[('b',"Bekannte Position: bestätigen, nicht erneut ablegen"),('b',"Wiederholter letzter Frame: nicht erneut ausführen"),('b',"Ergibt At-most-once"),('b',"Kennung wiederverwendet: alter Eintrag wird verworfen")],size=13,x=X0+w+150000,w=XR-(X0+w+150000))
# ---------------------------------------------------------------- Nebenläufigkeit
s=new(L_BODY,"Nebenläufigkeit auf dem Server","Client: keine Nebenläufigkeit, ein Aufruf blockiert, dafür keine Sperren. Server: drei Tasks in einer uasyncio-Schleife. Frühere Version: Aufrufe in eigenem Thread. Zwei Fehler: Thread-Stack wird vom Heap genommen, den LVGL fast aufbraucht; LVGL ist nicht reentrant, der Stack lief im Touch-Rückruf über. Lösung: gemeinsame Ereignisschleife. Preis: während der Ausführung wird nichts beantwortet und nicht gezeichnet. (2,5 min)")
body(s,[('h',"Client","Keine Nebenläufigkeit. Ein Aufruf blockiert bis zum Ergebnis oder zur Obergrenze, dafür sind keine Sperren nötig."),('h',"Server: drei Tasks, ein Thread","PUPRemote-process (etwa jede Millisekunde), LVGL-Task-Handler, je ein Task pro Aufruf, alle in einer uasyncio-Schleife."),('h',"Warum kein eigener Thread?","Der Stack kommt vom Heap, den LVGL fast aufbraucht, und LVGL ist nicht reentrant. Preis der Lösung: Die Schleife ist während eines Aufrufs belegt.")],size=15,dsize=13)
# ---------------------------------------------------------------- Fehler
s=new(L_ONLY,"Fehlerbehandlung je Schicht","Fehler werden in der Schicht behandelt, in der sie entstehen. In der Transportschicht sind Fehler der Normalfall: der Client liest direkt nach dem Schreiben und bekommt oft die Antwort auf die vorige Anfrage. Server: jede Ausnahme wird abgefangen und als ErrorPayload abgelegt. Der Touch-Rückruf von LVGL darf nie eine Ausnahme weitergeben. (2 min)")
table(s,["Fehler","Schicht","Behandlung"],[["Veraltete Antwort, verlorene Bestätigung","Transport","Frame erneut senden, max. 8 Versuche"],["Wiederholter Frame (Server)","Transport","bestätigen, nicht erneut ablegen"],["Abgebrochene Übertragung","Transport","Reste verwerfen bei Frame Nr. 0"],["Ergebnis bleibt aus","Kommunikation","nach 5000 ms Ausnahme"],["Unbekannter Scope / Methode","Kommunikation","Fehlermeldung, RemoteError"],["Veraltete Referenz, falsche Art","Objektmodell","StaleReferenceError, WrongKindError"],["Verbindungsabbruch","Bus","Session beenden, OSError"],["Touch-Lesefehler","Anzeige","als keine Berührung werten"]],X0,1150000,W,[3.2,1.6,3.2],size=12,rowh=380000)
# ---------------------------------------------------------------- Section Evaluation
section("Evaluation",notes="Die Messungen bestätigen die Annahme, auf der der Entwurf beruht. (ca. 5 min)")
# ---------------------------------------------------------------- Nachweis
s=new(L_BODY,"Funktionaler Nachweis und Testumgebung","Funktional: Beispielprogramm nutzt alle Bestandteile des Objektmodells, 640 aufeinanderfolgende Aufrufe ohne Wiederholung und Fehler. Die Testumgebung (CPython, gleiche Adapter und Interceptoren) belegt, was am echten Aufbau schwer zu zeigen ist: zweite Busanbindung für K6, künstlich erzeugte Fehler, Ereignisüberlauf. Grenze: kein zweiter realer Bus. (2 min)")
body(s,[('h',"Am Aufbau","Das Beispielprogramm nutzt alle Teile des Objektmodells. 640 Aufrufe in Folge: keine Wiederholung, kein Fehler."),('h',"Testumgebung unter CPython","Gleiche Adapter, Stellvertreter und Interceptoren; ersetzt sind nur Hardware, LVGL und Laufzeit. Zweite Busanbindung: derselbe Code über zwei Wege (K6)."),('h',"Gezielt erzeugte Fehler","Jede n-te Antwort veraltet, Verbindungsabbruch, Ereignispuffer über die Grenze gefüllt. Grenze: kein zweiter realer Bus.")],size=15,dsize=13)
# ---------------------------------------------------------------- Chart
s=new(L_BODY,"Übertragungsaufwand - Round Trips je Aufruf","Vier Konfigurationen: 13 oder 7 Byte Nutzlast und MessagePack oder JSON. 20 Aufrufe je Textlänge, Median. Round Trips = N + 2. Ein Round Trip kostet in jeder Konfiguration 114,2 ms (Standardabweichung 0,3 ms über 640 Aufrufe); die Dauer ist das Produkt aus beidem. Faktoren gegenüber heute: 7 Byte 1,59-fach, JSON 1,21-fach, beides 2,09-fach. Rahmung wiegt schwerer als Format. (3 min)")
cd=CategoryChartData(); cd.categories=['0','10','20','40','60','80','100','120']
cd.add_series('13 B, MessagePack (heute)',(4,5,6,7,9,10,12,13))
cd.add_series('13 B, JSON',(6,7,7,9,10,12,14,15))
cd.add_series('7 B, MessagePack',(5,7,8,11,14,17,20,23))
cd.add_series('7 B, JSON (erste Fassung)',(10,11,12,15,18,21,24,27))
gf=s.shapes.add_chart(XL_CHART_TYPE.LINE_MARKERS,X0,1050000,5200000,3500000,cd); ch=gf.chart
ch.has_legend=True; ch.legend.position=XL_LEGEND_POSITION.BOTTOM; ch.legend.include_in_layout=False; ch.legend.font.size=Pt(10); ch.legend.font.name="Calibri"
ch.category_axis.tick_labels.font.size=Pt(10); ch.value_axis.tick_labels.font.size=Pt(10)
ch.category_axis.has_title=True; ch.category_axis.axis_title.text_frame.text="Textlänge in Zeichen"; ch.category_axis.axis_title.text_frame.paragraphs[0].runs[0].font.size=Pt(10)
ch.value_axis.has_title=True; ch.value_axis.axis_title.text_frame.text="Round Trips"; ch.value_axis.axis_title.text_frame.paragraphs[0].runs[0].font.size=Pt(10)
ch.value_axis.major_gridlines.format.line.color.rgb=RGBColor(0xE0,0xE0,0xE0)
for ser,col in zip(ch.plots[0].series,[RGBColor(0x15,0x81,0x58),RGBColor(0x8A,0x96,0x96),RGBColor(0x05,0x8D,0xC7),RGBColor(0xED,0x56,0x1B)]):
    ser.format.line.color.rgb=col; ser.format.line.width=Pt(2); ser.smooth=False
    ser.marker.format.fill.solid(); ser.marker.format.fill.fore_color.rgb=col; ser.marker.format.line.color.rgb=col; ser.marker.size=5
body(s,[('h',"114,2 ms je Round Trip","Unabhängig von Format und Länge (σ = 0,3 ms)."),('h',"Round Trips = N + 2","Frames, READY, Ergebnisframe."),('h',"Rahmung vor Format","7 Byte: 1,59×, JSON: 1,21×, beides: 2,09×.")],size=13,dsize=11,x=5650000,w=2800000)
# ---------------------------------------------------------------- Reaktion
s=new(L_BODY,"Reaktionszeit einer Berührung (K4)","Vergleich der beiden Wege. Binding: Server führt die Reaktion selbst aus, 13 ms von erkannter Berührung bis fertigem Bild, mit Erkennung im Mittel 33 ms, höchstens 57 ms. Über den Client: zwei Aufrufe mit je 5 Round Trips = 1161 ms, dazu Warten auf die nächste Abfrage, im Mittel etwa 1490 ms. Abfrage kostet jetzt 5 statt 4 Round Trips, weil die Antwort Zustand, Drucke und Verworfene trägt. Test mit 20 kurzen Tippern je Pause: keiner verloren, K3 erfüllt. (3 min)")
table(s,["Teilstrecke","Binding","über Client"],[["Erkennung (LVGL, 40 ms Takt)","Ø 20 ms","Ø 20 ms"],["Verarbeitung des Ereignisses","4 ms","4 ms"],["Warten auf nächste Abfrage","entfällt","Ø 296 ms"],["Abfrage und Reaktion","entfällt","1161 ms"],["Neuzeichnen","6 ms","7 ms"],["Summe im Mittel","33 ms","≈ 1490 ms"],["Summe ungünstigster Fall","57 ms","≈ 1800 ms"]],X0,1150000,W,[3.2,1.4,1.6],size=13,rowh=370000)
tb=s.shapes.add_textbox(X0,4250000,W,500000); tb.text_frame.word_wrap=True
fill(tb.text_frame,[('b',"K3: 20 von 20 kurzen Tippern erkannt, keiner verloren (Pausen 0, 20, 1000 ms)")],size=13)
# ---------------------------------------------------------------- Ergebnis
s=new(L_BODY,"Ergebnis - Anforderungen und Ressourcen","Fünf von sechs erfüllt bzw. teilweise: K4 nur über Bindings, K5 teilweise, da auf dem Server nicht gemessen. Ressourcen auf dem Hub: eine Oberfläche aus zwei Screens, zwei Labels, zwei Buttons kostet 144 Byte (16272 gegenüber 16128), unabhängig von Format und Frame-Größe. Gebündelter Hub-Quelltext 68 KB. (2 min)")
table(s,["Nr.","Anforderung","Stand"],[["K1","Strukturierte Nachrichten (bis 3315 Byte)","erfüllt"],["K2","Zuordenbares Ergebnis (640 Aufrufe)","erfüllt"],["K3","Rückfluss von Ereignissen","erfüllt"],["K4","Antwortzeit < 100 ms (nur über Binding: 57 ms)","teilweise"],["K5","Begrenzter Speicher (Server nicht gemessen)","teilweise"],["K6","Unabhängigkeit vom Übertragungsweg","erfüllt"]],X0,1150000,W,[0.6,5,1.3],size=13,rowh=380000)
tb=s.shapes.add_textbox(X0,4100000,W,600000); tb.text_frame.word_wrap=True
fill(tb.text_frame,[('b',"Hub: 144 Byte für eine Oberfläche mit 2 Screens, 2 Labels, 2 Buttons; gebündelter Quelltext 68 KB")],size=13)
# ---------------------------------------------------------------- Section Nutzung
section("Nutzung und Ausblick",notes="Überleitung zum Punkt, den der Professor ausdrücklich wollte: wie sieht die Nutzung für zukünftige Projekte aus?")
# ---------------------------------------------------------------- Nutzung
s=new(L_BODY,"Nutzung in zukünftigen Projekten","WICHTIG: Schritte gegen das Repo prüfen und ergänzen (genaue Befehle, Versionen, Flash-Werkzeuge), bevor die Folie gezeigt wird. Ziel: zeigen, dass jemand anderes das Display in wenigen Schritten nutzen kann. Live-Demo hier möglich. (3 min)")
body(s,[('h',"1. Hub vorbereiten","Pybricks-Firmware auf den SPIKE Prime Hub flashen."),('h',"2. Display aufbauen","LMS-ESP32 auf die Adapterplatine, Display aufstecken, an einen Sensorport des Hubs."),('h',"3. Server flashen","MicroPython mit LVGL und den Server-Code auf den ESP32 laden."),('h',"4. Client bündeln","Bundler erzeugt pybricks_bundle.py (eine Datei)."),('h',"5. Programm schreiben","Display(interceptor) anlegen, Screens, Labels und Buttons erzeugen, Bindings setzen."),('p',"Quelltext: github.com/mat-mv/legolab-tft-display (Stand: stand-projektarbeit)")],size=14,dsize=12)
# ---------------------------------------------------------------- Beispiel
s=new(L_BODY,"Beispielprogramm auf dem Hub","Zwei Screens, zwei Buttons, Bindings: nach der Deklaration läuft der Screenwechsel lokal auf dem Display, ohne weiteren Aufwand für den Client. Zeigen, wie wenig Protokollwissen nötig ist. Ggf. Live-Demo. (2 min)")
code(s,['main = display.create_screen(set_active=True)','menu = display.create_screen(name="menu")','','label = main.create_label(10, 10, 230, 20, "...")','to_menu = main.create_button(','    10, 60, 100, 40, "Menue")','to_main = menu.create_button(','    10, 60, 100, 40, "Zurueck")','','# einmal deklarieren, danach lokal','to_menu.on_press(ACT_SHOW_SCREEN, menu)','to_main.on_press(ACT_SHOW_SCREEN, main)','','while True:','    label.set_text("Counter: {}".format(i))','    wait(1000)'],X0,1150000,4900000,3400000,size=10)
body(s,[('h',"Bindings","Screenwechsel direkt auf dem Display, ohne Übertragung."),('h',"Wenig Protokollwissen","Aussehen wie gewöhnliches Python."),('h',"Erweiterbar","Neuer Objekttyp: Basisklasse, Stellvertreter, Adapter.")],size=14,dsize=12,x=5450000,w=3000000)
# ---------------------------------------------------------------- Grenzen
s=new(L_BODY,"Grenzen","Größte Einschränkung: der Client blockiert während eines Aufrufs (Motorregelung!). Transparenz ist syntaktisch, nicht zeitlich. Kein Typcheck vor der Laufzeit, schemafreies Format. (2 min)")
body(s,[('h',"Client blockiert","Ein Aufruf dauert etwa 570 ms, in dieser Zeit steht alles still, etwa Motorregelung."),('h',"Reaktion über den Client","Etwa 1,5 s; unter 100 ms nur über Bindings."),('h',"Ereignisse","Jeder Button wird einzeln abgefragt, die Zahl der Aufrufe wächst mit den Bedienelementen."),('h',"Abstraktion","Transparenz ist syntaktisch, nicht zeitlich. Kein Typcheck vor der Laufzeit.")],size=15,dsize=13)
# ---------------------------------------------------------------- Ausblick
s=new(L_BODY,"Ausblick","Erweiterungen: Ergebnis mit der Bestätigung (5 auf 3 Round Trips, etwa 340 ms), gemeinsamer Ereignispuffer, async/await auf dem Hub, integrierte Platine, weitere Geräteklassen. Übertragbarkeit: alles Wegabhängige liegt unter der Interceptor-Schnittstelle; I²C, Modbus RTU und BLE wären denkbar. (2 min)")
body(s,[('h',"Ergebnis mit der Bestätigung","Kurzer Aufruf von 5 auf 3 Round Trips, etwa 340 statt 570 ms."),('h',"Gemeinsamer Ereignispuffer","Eine Abfrage für alle Bedienelemente, danach Rückrufe je Button."),('h',"async/await auf dem Hub","Warten auf ein Ergebnis, ohne die übrige Anwendung anzuhalten."),('h',"Übertragbarkeit","Andere Verbindungen (I²C, Modbus RTU, BLE): nur die Interceptor-Operation neu umsetzen."),('h',"Integrierte Platine, weitere Geräteklassen")],size=15,dsize=13)
# ---------------------------------------------------------------- Fazit
s=new(L_BODY,"Fazit","Drei Kernaussagen. Dann Fragen. (1,5 min)")
body(s,[('h',"Middleware statt Einzellösung","Fünf Schichten, alles Wegabhängige in der untersten."),('h',"Übertragungen zählen","114 ms je Round Trip; der Aufwand sank gegenüber der ersten Fassung auf die Hälfte."),('h',"Nutzbar, mit bekannten Grenzen","Eine interaktive Oberfläche läuft, Schwächen sind gemessen und mit Weg zur Lösung benannt."),('p',"Vielen Dank. Fragen?")],size=18,dsize=15)
# ---------------------------------------------------------------- Quellen
s=new(L_BODY,"Quellen","Quellenfolie als Backup. Vollständige Literatur in der Arbeit.")
body(s,[('b',"Quelltext: github.com/mat-mv/legolab-tft-display"),('b',"Pybricks (Firmware des SPIKE Prime Hubs)"),('b',"PUPRemote 1.6 und LMS-ESP32 (Busanbindung, Hardware)"),('b',"LVGL und lv_binding_micropython (Anzeige)"),('b',"MessagePack (Serialisierung)"),('p',"Vollständige Literaturangaben: siehe Thesis.")],size=16)

prs.save('praesentation_hka.pptx'); print(len(prs.slides))
