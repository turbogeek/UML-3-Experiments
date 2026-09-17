// READ-ONLY E12 probe: documentation and comments as CATIA Magic stores them.
// Reads uml3-docs-subjects.txt (one A::B::C path per line) next to this script and reports, per element:
//   DOC|path|<n>|<body with line breaks as \n>          one line per owned Documentation
//   COMMENT|path|<name>|<annotated element names>|<body>  for Comment elements
// Introspection (respondsTo) is used because Comment, Documentation and Element classes differ by version.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", "\n") }
def nameOf = { e -> try { e != null && e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def membersOf = { e -> (call0(e, "getOwnedMember") ?: []) }
def roots = RootNamespaces.getAllRoots(proj) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) { def hit = membersOf(r).find { nameOf(it) == path[0] }; if (hit != null) { cur = hit; break } }
    for (int i = 1; i < path.size() && cur != null; i++) { def want = path[i]; cur = membersOf(cur).find { nameOf(it) == want } }
    if (cur == null && path.size() > 1) {
        // named comments and enum literals may not be in getOwnedMember: fall back to owned elements
        def owner = findPath.call(path.subList(0, path.size() - 1))
        cur = (call0(owner, "getOwnedElement") ?: []).find { nameOf(it) == path[-1] }
    }
    return cur
}
def subjects = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-docs-subjects.txt")
if (!subjects.exists()) return "ERROR|missing " + subjects
subjects.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.each { line ->
    String path = line.trim()
    def e = findPath(path.split("::") as List)
    if (e == null) { out.append("MISSING|" + path + "\n"); return }
    out.append("ELEM|" + path + "|" + e.getClass().getSimpleName() + "\n")
    def docs = call0(e, "getDocumentation") ?: []
    docs.eachWithIndex { d, i -> out.append("DOC|" + path + "|" + i + "|" + clean(call0(d, "getBody")) + "\n") }
    if (e.getClass().getSimpleName().contains("Comment")) {
        def annotated = (call0(e, "getAnnotatedElement") ?: []).collect { nameOf(it) }
        out.append("COMMENT|" + path + "|" + nameOf(e) + "|" + annotated.join(",") + "|" + clean(call0(e, "getBody")) + "\n")
    }
}
return out.toString()
