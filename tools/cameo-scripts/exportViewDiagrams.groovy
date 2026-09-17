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
boolean inspectOnly = false
reqFile.readLines("UTF-8").each { l ->
    if (l.startsWith("outDir=")) outDir = l.substring(7).trim()
    else if (l.startsWith("view=")) views << l.substring(5).trim()
    else if (l.trim() == "inspectOnly=true") inspectOnly = true   // report diagram presence only; no model change
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

if (inspectOnly) {
    views.each { path ->
        def view = findPath(path.split("::") as List)
        def existing = view == null ? null : diagramsClass.getDiagram(view)
        out.append("VIEW|" + path + "|" + (view != null) + "|" + (existing != null) + "|-\n")
    }
    return out.append("RESULT|OK|inspected " + views.size() + "\n").toString()
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
                // the view's rendering decides the display mode (render asTreeDiagram -> TREE,
                // asInterconnectionDiagram -> NESTED, none -> UNDEFINED); E14
                try {
                    def modeClass = Class.forName("com.dassault_systemes.modeler.sysml.dsl.rendering.DisplayMode", true, cl)
                    out.append("MODE|" + path + "|" + modeClass.toDisplayMode(view) + "\n")
                } catch (Throwable t) { out.append("ERROR|" + path + "|mode|" + clean(t) + "\n") }
                def display = displayClass.getConstructor(adpeClass).newInstance(diagram)
                def result = display.display(java.util.stream.Stream.of(diagram))
                out.append("RESULTMODE|" + path + "|" + clean(call0(result, "getDisplayMode")) + "|" + (call0(result, "getDisplayed")?.size()) + "\n")
                try { display.layout(result); out.append("LAYOUT|" + path + "|done\n") }
                catch (Throwable t) { out.append("ERROR|" + path + "|layout|" + clean(t) + "\n") }
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
    // overlap check: sibling shapes (same parent, not paths) whose bounds intersect; nested shapes are not siblings
    int overlaps = 0
    List<String> examples = []
    def checkSiblings
    checkSiblings = { Object parent ->
        def kids = (call0(parent, "getPresentationElements") ?: []).findAll { k ->
            !k.getClass().getSimpleName().toLowerCase().contains("path") && call0(k, "getBounds") != null
        }
        for (int i = 0; i < kids.size(); i++) {
            for (int j = i + 1; j < kids.size(); j++) {
                def a = call0(kids[i], "getBounds"), b = call0(kids[j], "getBounds")
                if (a != null && b != null && a.width > 0 && b.width > 0 && a.intersects(b)) {
                    overlaps++
                    if (examples.size() < 5) {
                        def ea = call0(kids[i], "getKerMLElement") ?: call0(kids[i], "getElement")
                        def eb = call0(kids[j], "getKerMLElement") ?: call0(kids[j], "getElement")
                        examples << (clean(nameOf(ea) ?: kids[i].getClass().getSimpleName()) + "~" + clean(nameOf(eb) ?: kids[j].getClass().getSimpleName()))
                    }
                }
            }
        }
        (call0(parent, "getPresentationElements") ?: []).each { checkSiblings(it) }
    }
    checkSiblings(diagram)
    out.append("OVERLAP|" + path + "|" + overlaps + "|" + examples.join(", ") + "\n")
    shown.each { pair ->
        def el = pair[1]
        if (el != null) out.append("ELEM|" + path + "|" + clean(nameOf(el)) + "|" + el.getClass().getSimpleName() + "\n")
    }
    def file = new File(outDir, path.replace("::", ".") + ".svg")
    if (file.exists()) file.delete()
    call0(diagram, "ensureLoaded")
    // Preferred: SVG with <text> elements (ExportParams.useSVGTextTag), so names can be verified in the file.
    // Fallback: ImageExporter.SVG, which draws text as outlines (E13 first run). EXPORT line says which one was used.
    String mode = null
    try {
        def foundationExporter = Class.forName("com.dassault_systemes.modeler.foundation.diagram.image.InternalImageExporter", true, cl)
        def factory = Class.forName("com.dassault_systemes.modeler.foundation.diagram.image.ExportParamsBuilderFactory", true, cl).getInstance()
        def builder = factory.create()
        builder.setImageType(foundationExporter.getField("SVG").getInt(null))
        builder.setPath(file.path)
        builder.setUseSVGTextTag(true)
        def params = builder.build()
        SwingUtilities.invokeAndWait({ foundationExporter.exportPaintableComponent(diagram, params) } as Runnable)
        if (file.exists() && file.length() > 0) mode = "svgTextTags"
    } catch (Throwable t) {
        def cause = t
        while (cause.getCause() != null && cause.getCause() != cause) cause = cause.getCause()
        out.append("ERROR|" + path + "|export-text|" + clean(cause) + "\n")
    }
    if (mode == null) {
        try {
            SwingUtilities.invokeAndWait({ exporterClass.export(diagram, exporterClass.getField("SVG").getInt(null), file) } as Runnable)
            if (file.exists() && file.length() > 0) mode = "svgOutlines"
        } catch (Throwable t) {
            def cause = t
            while (cause.getCause() != null && cause.getCause() != cause) cause = cause.getCause()
            out.append("ERROR|" + path + "|export|" + clean(cause) + "\n")
        }
    }
    out.append("SVG|" + path + "|" + file.path + "|" + (file.exists() ? file.length() : -1) + "|" + mode + "\n")
    if (mode != null) exported++
}
out.append(exported == views.size() ? "RESULT|OK|" + exported + "\n" : "RESULT|FAIL|exported " + exported + " of " + views.size() + "\n")
return out.toString()
