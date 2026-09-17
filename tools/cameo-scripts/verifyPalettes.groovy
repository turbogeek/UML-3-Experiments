// Experiment E17 (read-only): what CATIA Magic's model-based customization makes of the UML3 view definitions.
// For each requested view it asks the DSL service (com.dassault_systemes.modeler.sysml.dsl, found in E16) for the
// view's visualization and palette and lists every category, menu and button with its operation; a templated button
// is resolved to its template element, whose kind and keyword metadata are reported. With dialogs=true it also lists
// the model-based View Creation dialogs and the active one.
// Request: uml3-palette-request.txt next to this script:
//     view=<Qualified::path::of::viewUsage>     (one line per view)
//     resetCache=true                           (optional: DSLService/DialogService.resetCache() first)
//     dialogs=true                              (optional)
// Output lines (no System.exit, no session, no model change):
//   DSL|valid|<bool>                           VIEW|path|found|definition
//   VIS|path|visualization class|type|name     CAT|path|category label|collapsed|visibleLabels|items
//   BTN|path|category label|menu label|button name|button label|focused|representation|operations
//       operations: code:<action ids> or template:<element class>:<element name>:<keyword metaclasses>, ';'-separated
//   DLG|type|action name|active|categories     DLGITEM|type|category label|item label|operations
//   ERROR|path|stage|message                   RESULT|OK|<views read> or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def project = Application.getInstance().getProject()
if (project == null) return "RESULT|FAIL|no open project (run inside CATIA Magic through the SysMLv2 test harness)"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def trace = { Throwable t -> clean(t) + " at " + (t.getStackTrace().take(6).collect { it.toString() }.join(" < ")) }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def nameOf = { e -> call0(e, "getDeclaredName") ?: call0(e, "getName") }

def dir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def reqFile = new File(dir, "uml3-palette-request.txt")
if (!reqFile.exists()) return "RESULT|FAIL|missing " + reqFile
List<String> views = []
boolean resetCache = false
boolean dialogs = false
String printFile = null   // printDsl=<file>: write DSLService.print() (the DSL model CATIA Magic built) to this file
reqFile.readLines("UTF-8").each { l ->
    if (l.startsWith("view=")) views << l.substring(5).trim()
    else if (l.trim() == "resetCache=true") resetCache = true
    else if (l.trim() == "dialogs=true") dialogs = true
    else if (l.startsWith("printDsl=")) printFile = l.substring(9).trim()
}
if (views.isEmpty() && !dialogs) return "RESULT|FAIL|request needs at least one view= or dialogs=true"

def cl = RootNamespaces.getClassLoader()
Class dslClass, dialogClass, mepClass, baseElementClass
try {
    dslClass = Class.forName("com.dassault_systemes.modeler.sysml.dsl.DSLService", true, cl)
    dialogClass = Class.forName("com.dassault_systemes.modeler.sysml.dsl.DialogService", true, cl)
    mepClass = Class.forName("com.dassault_systemes.modeler.foundation.project.ModelElementProject", true, cl)
    baseElementClass = Class.forName("com.nomagic.magicdraw.uml.BaseElement", true, cl)
} catch (Throwable t) {
    return "RESULT|FAIL|cannot load the DSL API: " + clean(t)
}

def roots = RootNamespaces.getAllRoots(project) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) { def hit = (call0(r, "getOwnedMember") ?: []).find { nameOf(it) == path[0] }; if (hit != null) { cur = hit; break } }
    for (int i = 1; i < path.size() && cur != null; i++) { def want = path[i]; cur = (call0(cur, "getOwnedMember") ?: []).find { nameOf(it) == want } }
    return cur
}

// keyword metaclass names of an element: its owned metadata usages (prefix '#k' and body '@K' forms), deduplicated by
// identity (never unique()/sort() on KerML elements)
def keywordsOf = { e ->
    def seen = new IdentityHashMap()
    List<String> names = []
    // plain ArrayList: Groovy's '+' on these collections built a sorted collection of KerML elements and threw
    // UnsupportedOperationException (compareTo) in E17 run 1
    List owned = new ArrayList()
    owned.addAll(call0(e, "getOwnedElement") ?: [])
    owned.addAll(call0(e, "getOwnedMember") ?: [])
    owned.each { m ->
        if (m == null || seen.containsKey(m)) return
        seen.put(m, Boolean.TRUE)
        String cls = m.getClass().getSimpleName()
        if (!cls.contains("MetadataUsage") && !cls.contains("MetadataFeature")) return
        def mc = call0(m, "getMetadataDefinition") ?: call0(m, "getMetaclass")
        if (mc == null) { def types = call0(m, "getType"); mc = (types instanceof Collection && !types.isEmpty()) ? types.iterator().next() : null }
        names << (mc != null ? (nameOf(mc) ?: mc.getClass().getSimpleName()) : cls)
    }
    return names
}

def describeOperations = { item ->
    List<String> parts = []
    (call0(item, "getOperations") ?: []).each { op ->
        String cls = op.getClass().getSimpleName()
        if (op.respondsTo("getActionIds")) {
            parts << ("code:" + (call0(op, "getActionIds") ?: []).join(","))
        } else if (op.respondsTo("getTemplate")) {
            def tmpl = call0(op, "getTemplate")
            parts << (tmpl == null ? "template:null" :
                "template:" + tmpl.getClass().getSimpleName() + ":" + (nameOf(tmpl) ?: "") + ":" + keywordsOf(tmpl).join(","))
        } else {
            parts << ("other:" + cls)
        }
    }
    return parts.join(";")
}

def svc = null
try {
    def anyElement = views.collect { findPath(it.split("::") as List) }.find { it != null }
    if (anyElement == null) anyElement = (call0(roots[0], "getOwnedMember") ?: [])[0]
    svc = dslClass.getMethod("getInstance", baseElementClass).invoke(null, anyElement)
    if (resetCache) { svc.resetCache(); out.append("RESET|DSLService\n") }
    out.append("DSL|valid|" + call0(svc, "isDSLValid") + "\n")
    // every visualization the DSL model knows: name, type, class, the view definition it came from, palette size
    (call0(svc, "getVisualizations") ?: []).each { v ->
        def pal = call0(v, "getPalette")
        out.append("VISLIST|" + clean(call0(v, "getName")) + "|" + clean(call0(v, "getType")) + "|" + v.getClass().getSimpleName() + "|" +
            clean(nameOf(call0(v, "getViewDefinition"))) + "|" + clean(call0(call0(v, "getParent"), "getName")) + "|" +
            (pal == null ? "-" : (call0(pal, "getCategories") ?: []).size()) + "\n")
    }
    if (printFile != null) {
        def sb = new StringBuilder()
        svc.print({ String s -> sb.append(s).append("\n") } as java.util.function.Consumer)
        new File(printFile).write(sb.toString(), "UTF-8")
        out.append("PRINT|" + printFile + "|" + sb.length() + "\n")
    }
} catch (Throwable t) {
    return out.append("RESULT|FAIL|DSLService: " + trace(t) + "\n").toString()
}

int read = 0
views.each { String path ->
    def view = findPath(path.split("::") as List)
    def definition = view == null ? null : ((call0(view, "getViewDefinition") ?: call0(view, "getDefinition")))
    String defName = definition instanceof Collection ? definition.collect { nameOf(it) }.join(",") : nameOf(definition)
    out.append("VIEW|" + path + "|" + (view != null) + "|" + defName + "\n")
    if (view == null) return
    try {
        def vis = svc.getVisualization(view)
        if (vis == null) { out.append("ERROR|" + path + "|visualization|null\n"); return }
        out.append("VIS|" + path + "|" + vis.getClass().getSimpleName() + "|" + call0(vis, "getType") + "|" + call0(vis, "getName") +
            "|definition=" + clean(nameOf(call0(vis, "getViewDefinition"))) + "\n")
        try { out.append("VISTYPE|" + path + "|" + clean(svc.getVisualizationType(view)) + "\n") } catch (Throwable t) { out.append("ERROR|" + path + "|type|" + trace(t) + "\n") }
        // the visualization of the view's own definition, asked directly (does the DSL know 'UML3 Class Diagram'?)
        try {
            def vdef = dslClass.getMethods().find { it.getName() == "getViewDefinition" && it.getParameterCount() == 1 }.invoke(null, view)
            def byDef = vdef == null ? null : svc.getVisualization(vdef)
            out.append("VISDEF|" + path + "|" + clean(nameOf(vdef)) + "|" + (byDef == null ? "null" : byDef.getClass().getSimpleName() + ":" + clean(call0(byDef, "getName"))) + "\n")
        } catch (Throwable t) { out.append("ERROR|" + path + "|visdef|" + trace(t) + "\n") }
        def palette = call0(vis, "getPalette")
        if (palette == null) { out.append("ERROR|" + path + "|palette|null\n"); return }
        (call0(palette, "getCategories") ?: []).each { cat ->
            List items = call0(cat, "getAbstractItems") ?: []
            String catLabel = clean(call0(cat, "getLabel"))
            out.append("CAT|" + path + "|" + catLabel + "|" + call0(cat, "isCollapsed") + "|" + call0(cat, "hasVisibleLabels") + "|" + items.size() + "\n")
            def walkItems
            walkItems = { List list, String menuLabel ->
                list.each { it2 ->
                    if (it2.respondsTo("getAbstractItems")) {
                        walkItems(call0(it2, "getAbstractItems") ?: [], clean(call0(it2, "getLabel") ?: call0(it2, "getName")))
                    } else {
                        out.append("BTN|" + path + "|" + catLabel + "|" + (menuLabel ?: "") + "|" + clean(call0(it2, "getName")) + "|" +
                            clean(call0(it2, "getLabel")) + "|" + call0(it2, "isFocused") + "|" + call0(it2, "getRepresentationKind") + "|" +
                            clean(describeOperations(it2)) + "\n")
                    }
                }
            }
            walkItems(items, null)
        }
        read++
    } catch (Throwable t) {
        out.append("ERROR|" + path + "|palette|" + trace(t) + "\n")
    }
}

if (dialogs) {
    try {
        def anyElement = (call0(roots[0], "getOwnedMember") ?: [])[0]
        def ds = dialogClass.getMethod("getInstance", baseElementClass).invoke(null, anyElement)
        if (resetCache) { ds.resetCache(); out.append("RESET|DialogService\n") }
        def mep = mepClass.getMethod("getProject", baseElementClass).invoke(null, anyElement)
        def active = dialogClass.getMethod("getActiveModelBasedViewCreationDialog", mepClass).invoke(null, mep)
        def activeType = active == null ? null : call0(active, "getType")
        (call0(ds, "getViewCreationDialogs") ?: [:]).each { type, dlg ->
            def cats = call0(dlg, "getCategories") ?: []
            out.append("DLG|" + clean(nameOf(type)) + "|" + clean(call0(dlg, "getActionName")) + "|" + (activeType != null && activeType.is(type)) + "|" + cats.size() + "\n")
            cats.each { cat ->
                String catLabel = clean(call0(cat, "getLabel"))
                (call0(cat, "getAbstractItems") ?: []).each { item ->
                    out.append("DLGITEM|" + clean(nameOf(type)) + "|" + catLabel + "|" + clean(call0(item, "getLabel")) + "|" + clean(describeOperations(item)) + "\n")
                }
            }
        }
        out.append("DLGACTIVE|" + clean(activeType == null ? null : nameOf(activeType)) + "\n")
    } catch (Throwable t) {
        out.append("ERROR|dialogs|read|" + clean(t) + "\n")
    }
}
out.append("RESULT|OK|" + read + "\n")
return out.toString()
