// Opens the diagram of a SysML v2 view in the CATIA Magic window and writes a screenshot of the window to a PNG,
// so a reviewer (or Claude) can see what the user sees, including the view palette (experiment E17).
// Request: uml3-capture-request.txt next to this script:
//     outDir=<directory for the .png files>
//     view=<Qualified::path::of::viewUsage>     (one line per view; the view must already have a diagram)
//     close=true                                (optional: close the diagram window again afterwards)
//     reopen=true                               (optional: close the window first, to rebuild it and its palette)
// The diagram must exist (exportViewDiagrams.groovy creates it). Opening and closing a diagram window changes no
// model element and creates no command. Output lines (no System.exit):
//   OPEN|path|diagram name       SHOT|path|file|bytes|width|height
//   ERROR|path|stage|message     RESULT|OK|<screenshots> or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import com.dassault_systemes.modeler.sysml.diagram.Diagrams
import java.awt.image.BufferedImage
import javax.imageio.ImageIO
import javax.swing.SwingUtilities

def app = Application.getInstance()
def project = app.getProject()
if (project == null) return "RESULT|FAIL|no open project (run inside CATIA Magic through the SysMLv2 test harness)"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def nameOf = { e -> call0(e, "getDeclaredName") ?: call0(e, "getName") }

def dir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def reqFile = new File(dir, "uml3-capture-request.txt")
if (!reqFile.exists()) return "RESULT|FAIL|missing " + reqFile
String outDir = null
List<String> views = []
boolean close = false
boolean reopen = false   // close the diagram window first, so the window and its palette are rebuilt
reqFile.readLines("UTF-8").each { l ->
    if (l.startsWith("outDir=")) outDir = l.substring(7).trim()
    else if (l.startsWith("view=")) views << l.substring(5).trim()
    else if (l.trim() == "close=true") close = true
    else if (l.trim() == "reopen=true") reopen = true
}
if (!outDir || views.isEmpty()) return "RESULT|FAIL|request needs outDir= and at least one view="
new File(outDir).mkdirs()

def roots = RootNamespaces.getAllRoots(project) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) { def hit = (call0(r, "getOwnedMember") ?: []).find { nameOf(it) == path[0] }; if (hit != null) { cur = hit; break } }
    for (int i = 1; i < path.size() && cur != null; i++) { def want = path[i]; cur = (call0(cur, "getOwnedMember") ?: []).find { nameOf(it) == want } }
    return cur
}

int shots = 0
views.each { String path ->
    def view = findPath(path.split("::") as List)
    if (view == null) { out.append("ERROR|" + path + "|find|view not found\n"); return }
    def diagram = null
    try { diagram = Diagrams.getDiagram(view) } catch (Throwable t) { out.append("ERROR|" + path + "|getDiagram|" + clean(t) + "\n"); return }
    if (diagram == null) { out.append("ERROR|" + path + "|getDiagram|no diagram (run exportViewDiagrams first)\n"); return }
    try {
        // the SysML v2 Diagram IS the presentation element (it extends AbstractDiagramPresentationElement), so it
        // opens and closes itself; reopening rebuilds the diagram window, including its palette
        SwingUtilities.invokeAndWait({
            try {
                if (reopen && diagram.respondsTo("close")) diagram.close()
                if (diagram.respondsTo("ensureLoaded")) diagram.ensureLoaded()
                if (diagram.respondsTo("open")) diagram.open()
                out.append("OPEN|" + path + "|" + clean(nameOf(diagram)) + "|" + diagram.getClass().getSimpleName() + "\n")
            } catch (Throwable inner) {
                out.append("ERROR|" + path + "|open|" + clean(inner) + " cause=" + clean(inner.getCause()) + "\n")
            }
        } as Runnable)
        // let the diagram and its palette paint before capturing
        Thread.sleep(1500)
        def holder = new Object[1]
        SwingUtilities.invokeAndWait({
            try {
                def frame = app.getMainFrame()
                def image = new BufferedImage(Math.max(1, frame.getWidth()), Math.max(1, frame.getHeight()), BufferedImage.TYPE_INT_RGB)
                def g = image.createGraphics()
                frame.paint(g)
                g.dispose()
                holder[0] = image
            } catch (Throwable inner) {
                out.append("ERROR|" + path + "|paint|" + clean(inner) + " cause=" + clean(inner.getCause()) + "\n")
            }
        } as Runnable)
        if (holder[0] == null) { out.append("ERROR|" + path + "|paint|no image\n"); return }
        def image = holder[0]
        def file = new File(outDir, path.replace("::", ".").replaceAll("[^A-Za-z0-9_.-]", "_") + ".png")
        ImageIO.write(image, "PNG", file)
        out.append("SHOT|" + path + "|" + file.getPath() + "|" + file.length() + "|" + image.getWidth() + "|" + image.getHeight() + "\n")
        shots++
        if (close) {
            SwingUtilities.invokeAndWait({
                if (diagram.respondsTo("close")) diagram.close()
            } as Runnable)
        }
    } catch (Throwable t) {
        out.append("ERROR|" + path + "|capture|" + clean(t) + "\n")
    }
}
out.append("RESULT|OK|" + shots + "\n")
return out.toString()
