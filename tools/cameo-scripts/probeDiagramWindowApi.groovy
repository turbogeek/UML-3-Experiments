// Probes how a SysML v2 diagram window is brought to the front. captureDiagramWindow.groovy called only
// diagram.open(), which opens a tab without activating it: two views in one run produced byte-identical
// screenshots of whichever tab was already in front (2026-09-24).
// Read-only: it opens no diagram and changes nothing. Request: reuses uml3-capture-request.txt (view= lines).
// Output lines (no System.exit):
//   DIAGRAM|<view>|<class>            METHOD|<owner>|<signature>
//   MANAGER|<class>|<found>           MMETHOD|<class>|<signature>
//   RESULT|OK or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import com.dassault_systemes.modeler.sysml.diagram.Diagrams

def app = Application.getInstance()
def project = app.getProject()
if (project == null) return "RESULT|FAIL|no open project"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def nameOf = { e -> call0(e, "getDeclaredName") ?: call0(e, "getName") }

def dir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def reqFile = new File(dir, "uml3-capture-request.txt")
List<String> views = []
if (reqFile.exists()) reqFile.readLines("UTF-8").each { l -> if (l.startsWith("view=")) views << l.substring(5).trim() }
if (views.isEmpty()) return "RESULT|FAIL|no view= in " + reqFile

def roots = RootNamespaces.getAllRoots(project) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) { def hit = (call0(r, "getOwnedMember") ?: []).find { nameOf(it) == path[0] }; if (hit != null) { cur = hit; break } }
    for (int i = 1; i < path.size() && cur != null; i++) { def want = path[i]; cur = (call0(cur, "getOwnedMember") ?: []).find { nameOf(it) == want } }
    return cur
}

def view = findPath(views[0].split("::") as List)
def diagram = view == null ? null : Diagrams.getDiagram(view)
if (diagram == null) return "RESULT|FAIL|no diagram for " + views[0] + " (run exportViewDiagrams first)"
out.append("DIAGRAM|" + views[0] + "|" + diagram.getClass().getName() + "\n")

// anything on the diagram presentation element that could front, focus or select it
diagram.getClass().getMethods()
    .findAll { it.name ==~ /(?i).*(activate|active|front|focus|select|open|show|visible).*/ }
    .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
    .toSorted().unique().each { out.append("METHOD|diagram|" + it + "\n") }

// and the window managers that own the tabs
def cl = RootNamespaces.getClassLoader()
["com.nomagic.magicdraw.ui.ProjectWindowsManager",
 "com.nomagic.magicdraw.ui.DiagramWindowsManager",
 "com.nomagic.magicdraw.ui.WindowsManager",
 "com.dassault_systemes.modeler.sysml.diagram.Diagrams"].each { String n ->
    try {
        Class c = Class.forName(n, true, cl)
        out.append("MANAGER|" + n + "|true\n")
        c.getMethods()
            .findAll { it.name ==~ /(?i).*(activate|front|focus|open|show|select|getInstance).*/ }
            .collect { m -> (java.lang.reflect.Modifier.isStatic(m.modifiers) ? "static " : "") + m.name +
                "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
            .toSorted().unique().take(20).each { out.append("MMETHOD|" + c.getSimpleName() + "|" + it + "\n") }
    } catch (Throwable t) { out.append("MANAGER|" + n + "|false\n") }
}

return out.append("RESULT|OK\n").toString()
