// Experiment E18 (read-only): can a tool read the UML3 diagram-kind model? For every part of
// UML3DiagramKinds typed by DiagramKind it evaluates the shows, creates and views lists and reports the elements
// CATIA Magic gives back, which is what a palette generator or a report would consume (issue I-35).
// Request: uml3-diagram-kinds-request.txt next to this script (optional):
//     package=<root package name>      (default UML3DiagramKinds)
// Output lines (no System.exit, no session, no model change):
//   KIND|name|label|shows count|creates count|views count
//   LIST|name|role|element names, comma separated
//   ERROR|name|role|message        RESULT|OK|<kinds read> or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import com.dassault_systemes.modeler.kerml.model.FeatureValues

def project = Application.getInstance().getProject()
if (project == null) return "RESULT|FAIL|no open project (run inside CATIA Magic through the SysMLv2 test harness)"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def nameOf = { e -> call0(e, "getDeclaredName") ?: call0(e, "getName") }

def dir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def reqFile = new File(dir, "uml3-diagram-kinds-request.txt")
String pkgName = "UML3DiagramKinds"
if (reqFile.exists()) {
    reqFile.readLines("UTF-8").each { l -> if (l.startsWith("package=")) pkgName = l.substring(8).trim() }
}

def roots = RootNamespaces.getAllRoots(project) ?: []
def pkg = null
roots.each { r -> (call0(r, "getOwnedMember") ?: []).each { m -> if (nameOf(m) == pkgName) pkg = m } }
if (pkg == null) return "RESULT|FAIL|package " + pkgName + " not found (load library/UML3DiagramKinds.sysml first)"

// the elements a value expression evaluates to; a feature with no bound value yields an empty list
def valuesOf = { feature, owner ->
    List names = []
    def expr = null
    try { expr = FeatureValues.getOwnedFeatureValueExpression(feature) } catch (Throwable t) { expr = null }
    if (expr == null) return names
    def result = null
    try { result = expr.evaluate(owner) } catch (Throwable t) { result = null }
    if (result == null) return null
    result.each { v ->
        // a metaobject carries the element it stands for; fall back to its own name or class
        def element = call0(v, "getSyntaxElement") ?: call0(v, "getAnnotatedElement") ?: v
        if (element instanceof Collection) element = element.isEmpty() ? null : element.iterator().next()
        names << (nameOf(element) ?: nameOf(v) ?: v.getClass().getSimpleName())
    }
    return names
}

int kinds = 0
(call0(pkg, "getOwnedMember") ?: []).each { member ->
    String kindName = nameOf(member)
    def types = call0(member, "getType") ?: []
    boolean isKind = types.any { nameOf(it) == "DiagramKind" }
    if (!isKind) return
    def features = call0(member, "getOwnedFeature") ?: []
    Map lists = [:]
    String label = null
    features.each { f ->
        String fn = nameOf(f)
        if (fn == null) {
            // a redefinition is often unnamed; take the name of the feature it redefines
            def red = (call0(f, "getOwnedRedefinition") ?: []).collect { call0(it, "getRedefinedFeature") }.find { it != null }
            fn = nameOf(red)
        }
        if (fn == null) return
        if (fn == "label") {
            def v = valuesOf(f, member)
            label = (v == null || v.isEmpty()) ? null : v[0]
            return
        }
        if (!(fn in ["shows", "creates", "views"])) return
        def v = valuesOf(f, member)
        if (v == null) { out.append("ERROR|" + kindName + "|" + fn + "|could not evaluate the value expression\n"); return }
        lists.put(fn, v)
    }
    out.append("KIND|" + kindName + "|" + clean(label) + "|" + (lists.get("shows") ?: []).size() + "|" +
        (lists.get("creates") ?: []).size() + "|" + (lists.get("views") ?: []).size() + "\n")
    ["shows", "creates", "views"].each { role ->
        out.append("LIST|" + kindName + "|" + role + "|" + (lists.get(role) ?: []).collect { clean(it) }.join(",") + "\n")
    }
    kinds++
}
out.append("RESULT|OK|" + kinds + "\n")
return out.toString()
