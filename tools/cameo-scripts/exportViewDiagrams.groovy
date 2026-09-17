// Renders SysML v2 views as diagrams in CATIA Magic and exports them to SVG (experiment E13, harness step --svg).
// Request: uml3-svg-request.txt next to this script:
//     outDir=<directory for the .svg files>
//     view=<Qualified::path::of::viewUsage>        (one line per view)
// For each view: find the ViewUsage, create its diagram (Diagrams.createDiagram with the view's definition) unless
// one exists, show the exposed elements (DisplayExposedElements), then export the diagram (ImageExporter.SVG).
// All model changes happen in ONE session named "UML3 View Diagrams", so the guarded undo can remove them.
// Output lines (no System.exit):
//   VIEW|path|found|hadDiagram|definition     CREATED|path|diagram class|diagram type
//   DISPLAY|path|shown elements               ELEM|path|element name|element class
//   SVG|path|file|bytes                       ERROR|path|stage|message
//   TOP|<undo command name after the session>  RESULT|OK|<views exported> or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application
import com.nomagic.magicdraw.openapi.uml.SessionManager
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import javax.swing.SwingUtilities

def app = Application.getInstance()
def project = app.getProject()
if (project == null) return "RESULT|FAIL|no open project (run inside CATIA Magic through the SysMLv2 test harness)"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def nameOf = { e -> call0(e, "getName") ?: call0(e, "getDeclaredName") }

def dir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def reqFile = new File(dir, "uml3-svg-request.txt")
if (!reqFile.exists()) return "RESULT|FAIL|missing " + reqFile
String outDir = null
List<String> views = []
reqFile.readLines("UTF-8").each { l ->
    if (l.startsWith("outDir=")) outDir = l.substring(7).trim()
    else if (l.startsWith("view=")) views << l.substring(5).trim()
}
if (!outDir || views.isEmpty()) return "RESULT|FAIL|request needs outDir= and at least one view="
new File(outDir).mkdirs()

def cl = RootNamespaces.getClassLoader()
Class diagramsClass, displayClass, adpeClass, exporterClass
try {
    diagramsClass = Class.forName("com.dassault_systemes.modeler.sysml.diagram.Diagrams", true, cl)
    displayClass = Class.forName("com.dassault_systemes.modeler.sysml.diagram.refactoring.DisplayExposedElements", true, cl)
    adpeClass = Class.forName("com.nomagic.magicdraw.uml.symbols.AbstractDiagramPresentationElement", true, cl)
    exporterClass = Class.forName("com.nomagic.magicdraw.export.image.ImageExporter", true, cl)
} catch (Throwable t) {
    return "RESULT|FAIL|cannot load diagram API: " + clean(t)
}

def roots = RootNamespaces.getAllRoots(project) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) { def hit = (call0(r, "getOwnedMember") ?: []).find { nameOf(it) == path[0] }; if (hit != null) { cur = hit; break } }
    for (int i = 1; i < path.size() && cur != null; i++) { def want = path[i]; cur = (call0(cur, "getOwnedMember") ?: []).find { nameOf(it) == want } }
    return cur
}
// depth-first over presentation elements; the model element of a KerML shape is getKerMLElement / getElement
def collect
collect = { Object pe, List acc ->
    (call0(pe, "getPresentationElements") ?: []).each { child ->
        def el = call0(child, "getKerMLElement") ?: call0(child, "getElement") ?: call0(child, "getModelElement")
        acc << [child, el]
        collect(child, acc)
    }
    return acc
}

Map<String, Object> diagrams = [:]
SwingUtilities.invokeAndWait({
    def sm = SessionManager.getInstance()
    try {
        sm.createSession(project, "UML3 View Diagrams")
        views.each { path ->
            def view = findPath(path.split("::") as List)
            if (view == null) { out.append("VIEW|" + path + "|false|false|-\n"); return }
            try {
                def existing = diagramsClass.getDiagram(view)
                def definition = diagramsClass.getViewDefinition(view)
                out.append("VIEW|" + path + "|true|" + (existing != null) + "|" + clean(nameOf(definition)) + "\n")
                def diagram = existing
                if (diagram == null) {
                    diagram = diagramsClass.createDiagram(view, definition, false)
                    out.append("CREATED|" + path + "|" + (diagram == null ? "null" : diagram.getClass().getSimpleName()) + "|" +
                        clean(call0(diagram, "getDiagramTypeAsString")) + "\n")
                }
                if (diagram == null) { out.append("ERROR|" + path + "|create|createDiagram returned null\n"); return }
                def display = displayClass.getConstructor(adpeClass).newInstance(diagram)
                display.display(java.util.stream.Stream.of(diagram))
                diagrams[path] = diagram
            } catch (Throwable t) {
                out.append("ERROR|" + path + "|create/display|" + clean(t) + "\n")
            }
        }
    } catch (Throwable t) {
        out.append("ERROR|-|session|" + clean(t) + "\n")
    } finally {
        try { if (sm.isSessionCreated(project)) sm.closeSession(project) } catch (Throwable t) { out.append("ERROR|-|closeSession|" + clean(t) + "\n") }
    }
    try { out.append("TOP|" + clean(call0(project.getCommandHistory().getCommandForUndo(), "getName")) + "\n") } catch (Throwable ignored) {}
} as Runnable)

int exported = 0
diagrams.each { path, diagram ->
    def shown = collect(diagram, [])
    out.append("DISPLAY|" + path + "|" + shown.size() + "\n")
    shown.each { pair ->
        def el = pair[1]
        if (el != null) out.append("ELEM|" + path + "|" + clean(nameOf(el)) + "|" + el.getClass().getSimpleName() + "\n")
    }
    def file = new File(outDir, path.replace("::", ".") + ".svg")
    try {
        call0(diagram, "ensureLoaded")
        SwingUtilities.invokeAndWait({ exporterClass.export(diagram, exporterClass.getField("SVG").getInt(null), file) } as Runnable)
        out.append("SVG|" + path + "|" + file.path + "|" + (file.exists() ? file.length() : -1) + "\n")
        if (file.exists() && file.length() > 0) exported++
    } catch (Throwable t) {
        def cause = t
        while (cause.getCause() != null && cause.getCause() != cause) cause = cause.getCause()
        out.append("ERROR|" + path + "|export|" + clean(cause) + "\n")
    }
}
out.append(exported == views.size() ? "RESULT|OK|" + exported + "\n" : "RESULT|FAIL|exported " + exported + " of " + views.size() + "\n")
return out.toString()
