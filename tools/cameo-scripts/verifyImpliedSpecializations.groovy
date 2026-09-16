// READ-ONLY verification of specializations implied by UML3 semantic-metadata keywords.
// Reads hypotheses from uml3-implied-specializations.txt in the harness scripts directory, written
// by tools/cameo_check.py from tests/cameo/implied-specializations.json. One case per line:
//   id|kind|subject::path|general::path-or-featureName|expected(true/false)
// Returns one line per case: RESULT|id|PASS/FAIL|expected|observed|detail
// No groovy.json here: MagicDraw's GroovyShell classpath does not include groovy-json.
// API (discovered by probeKermlTypeApi.groovy): Type.specializes(Type), Type.allSupertypes(),
// Type.getFeature(); RootNamespaces are unnamed and own the packages.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def scriptsDir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def spec = new File(scriptsDir, "uml3-implied-specializations.txt")
if (!spec.exists()) return "ERROR|hypotheses file not found: " + spec.getAbsolutePath()

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"

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
def clean = { String t -> t == null ? "" : t.replace("|", "/").replace("\n", " ") }

def out = new StringBuilder()
int total = 0, passed = 0
spec.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.each { line ->
    def f = line.split(java.util.regex.Pattern.quote("|"), -1)
    String id = f[0], kind = f[1]
    def subject = f[2].split("::") as List
    boolean expected = f[4].trim() == "true"
    String observed = "null"
    String detail = ""
    boolean ok = false
    def s = findPath(subject)
    try {
        if (s == null) {
            detail = "not found: " + f[2]
        } else if (kind == "specializes") {
            def g = findPath(f[3].split("::") as List)
            if (g == null) {
                detail = "not found: " + f[3]
            } else if (!s.respondsTo("specializes", g)) {
                detail = "specializes(Type) not available on " + s.getClass().getSimpleName()
            } else {
                boolean obs = s.specializes(g)
                observed = String.valueOf(obs)
                ok = (obs == expected)
                if (!ok) {
                    try { detail = "allSupertypes=" + s.allSupertypes().collect { nameOf(it) }.findAll { it != null }.join(",") } catch (x) {}
                }
            }
        } else if (kind == "inheritsFeature") {
            def feats = s.respondsTo("getFeature") ? (s.getFeature() ?: []) : []
            boolean obs = feats.any { nameOf(it) == f[3] }
            observed = String.valueOf(obs)
            ok = (obs == expected)
        } else {
            detail = "unknown kind " + kind
        }
    } catch (Throwable t) {
        detail = "exception " + t
    }
    total++
    if (ok) passed++
    out.append("RESULT|" + id + "|" + (ok ? "PASS" : "FAIL") + "|" + expected + "|" + observed + "|" + clean(detail) + "\n")
}
out.append("SUMMARY|total=" + total + "|passed=" + passed + "|failed=" + (total - passed) + "\n")
return out.toString()
