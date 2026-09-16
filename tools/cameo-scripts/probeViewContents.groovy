// READ-ONLY: what CATIA Magic computes as the content of SysML v2 view usages.
// Reads view paths (A::B::view) from uml3-view-subjects.txt in the harness scripts dir.
// SysML v2: ViewUsage::exposedElement is derived from 'expose' + all owned/inherited 'filter'
// conditions. Several accessor names are tried (respondsTo) because the Dassault API naming is
// not documented; the first that answers is reported.
// Output: VIEW|path|class|accessor|count|name1,name2,...   or   VIEW|path|NOT_FOUND|||
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace(",", ";").replace("\n", " ") }
def nameOf = { e -> try { e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def membersOf = { e -> try { e.respondsTo("getOwnedMember") ? (e.getOwnedMember() ?: []) : [] } catch (x) { [] } }
def roots = RootNamespaces.getAllRoots(proj) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) {
        def hit = membersOf(r).find { nameOf(it) == path[0] }
        if (hit != null) { cur = hit; break }
    }
    for (int i = 1; i < path.size() && cur != null; i++) {
        def want = path[i]
        cur = membersOf(cur).find { nameOf(it) == want }
    }
    return cur
}

def subjects = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-view-subjects.txt")
if (!subjects.exists()) return "ERROR|subjects file missing: " + subjects
def ACCESSORS = ["getExposedElement", "getExposedElements", "exposedElement"]

subjects.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.each { line ->
    def v = findPath(line.trim().split("::") as List)
    if (v == null) { out.append("VIEW|" + line + "|NOT_FOUND|||\n"); return }
    String accessor = null
    def elements = null
    String problem = ""
    for (a in ACCESSORS) {
        if (v.respondsTo(a)) {
            try { elements = v."$a"(); accessor = a; break }
            catch (Throwable t) { problem += a + " threw " + clean(t) + "; " }
        }
    }
    if (accessor == null) {
        def candidates = v.getClass().getMethods().collect { it.getName() }.findAll { it =~ /(?i)expos|filter|render|viewCondition/ }.unique().sort()
        out.append("VIEW|" + line + "|" + v.getClass().getSimpleName() + "|NONE|0|" + clean(problem + "methods=" + candidates.join(" ")) + "\n")
        return
    }
    def names = (elements ?: []).collect { nameOf(it) ?: it.getClass().getSimpleName() }
    out.append("VIEW|" + line + "|" + v.getClass().getSimpleName() + "|" + accessor + "|" + names.size() + "|" + names.collect { clean(it) }.join(",") + "\n")
}
return out.toString()
