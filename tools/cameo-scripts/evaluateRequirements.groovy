// Evaluates satisfy requirement usages and assert constraints with CATIA Magic's SysML v2 evaluation engine and
// reports each verdict. Read-only (the engine may cache results; the model is not changed).
// Input:  <harness scripts dir>/uml3-evaluate-request.txt, one case per line:  id|Pkg::Owner::feature|expected
// Output: TRY|id|strategy|result classes and texts|errors   (every attempt, for diagnosis)
//         EVAL|id|observed(true/false/none)|strategy|detail  (the verdict used for the comparison)
//         RESULT|OK|n cases   or   RESULT|FAIL|reason
// Strategies: 'evaluator' = kerml.evaluation.Evaluator.evaluate(feature), what the Model Evaluation console uses;
// 'modelLevel' = ModelLevelExpressionEvaluator.INSTANCE.evaluate(feature, owner), the evaluator of model-level
// expressions such as '(pkg meta KerML::Package).ownedElement'. Experiment E22 P5 introduced this script.
// Must run inside CATIA Magic through the harness (/run-script); outside it reports that. No System.exit.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def app = null
try { app = Application.getInstance() } catch (Throwable t) { return "RESULT|FAIL|not inside CATIA Magic: " + t }
def proj = app?.getProject()
if (proj == null) return "RESULT|FAIL|no open project (run inside CATIA Magic through the SysMLv2 test harness)"
def req = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-evaluate-request.txt")
if (!req.exists()) return "RESULT|FAIL|missing " + req

def clean = { Object o -> o == null ? "null" : o.toString().replace("|", "/").replace("\n", " ").take(300) }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def nameOf = { e -> call0(e, "getDeclaredName") ?: call0(e, "getName") }
def membersOf = { e -> def m = call0(e, "getOwnedMember"); m == null ? [] : new ArrayList(m) }
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
// a verdict from an evaluation result: a Boolean, a value object holding one, or the literal text of one
def verdictOf = { List values ->
    if (values == null || values.isEmpty()) return null
    for (v in values) {
        if (v instanceof Boolean) return v
        for (m in ["getValue", "getBooleanValue", "booleanValue", "isValue"]) {
            def x = call0(v, m)
            if (x instanceof Boolean) return x
        }
        String s = v.toString().trim().toLowerCase()
        if (s == "true" || s.endsWith("=true") || s.endsWith("(true)") || s.endsWith("[true]")) return true
        if (s == "false" || s.endsWith("=false") || s.endsWith("(false)") || s.endsWith("[false]")) return false
    }
    return null
}
def describe = { List values -> values == null ? "null" : values.collect { (it == null ? "null" : it.getClass().getSimpleName()) + ":" + clean(it) }.join("; ") }

// The evaluator returns a requirement as a StructuredValue (an instance of the requirement), not a Boolean. The
// verdict is the value of its 'result' feature (RequirementCheck is a constraint check whose result is Boolean).
// dumpValue lists the zero-argument getters of a value and their results, so an unknown value API can be read
// from the TRY lines; resultOf looks for the Boolean of a feature named 'result' or of the value itself.
def getters = { Object v ->
    v == null ? [] : v.getClass().getMethods().findAll {
        it.getParameterCount() == 0 && it.getReturnType() != void.class && it.getDeclaringClass() != Object.class &&
            (it.getName().startsWith("get") || it.getName().startsWith("is") || it.getName().startsWith("has"))
    }.sort { it.getName() }
}
def dumpValue = { Object v ->
    getters(v).collect { m ->
        String r
        try { def x = m.invoke(v); r = x instanceof Collection ? ("[" + x.take(6).collect { clean(it) }.join(", ") + (x.size() > 6 ? ", ..." : "") + "]") : clean(x) }
        catch (Throwable t) { r = "threw " + clean(t.getCause() ?: t) }
        m.getName() + "=" + r
    }.join("; ")
}
// CATIA Magic's StructuredValue (kerml.evaluation.values): getFeatureValuesKeys() lists the features, and
// getFeatureValueWrappers() holds one FeatureValueWrapper per feature in the same order (E22 P5 attempt 2).
def wrapperValues = { Object w ->
    for (m in ["getValues", "getValue", "getFeatureValues", "getValueList"]) {
        def x = call0(w, m)
        if (x instanceof Collection) return new ArrayList(x)
        if (x != null) return [x]
    }
    return []
}
def keyed = { Object v ->
    def keys = call0(v, "getFeatureValuesKeys")
    def wrappers = call0(v, "getFeatureValueWrappers")
    if (!(keys instanceof Collection) || !(wrappers instanceof Collection)) return []
    List k = new ArrayList(keys), w = new ArrayList(wrappers)
    (0..<Math.min(k.size(), w.size())).collect { i -> [name: clean(nameOf(k[i]) ?: k[i]), key: k[i], wrapper: w[i]] }
}
def resultOf
resultOf = { Object v, int depth ->
    if (v == null || depth > 3) return null
    if (v instanceof Boolean) return v
    for (e in keyed(v)) {
        if (e.name == "result") {
            def b = verdictOf(wrapperValues(e.wrapper))
            if (b != null) return b
        }
    }
    // a value tree: children by feature; try the common accessor shapes
    for (m in ["getChildren", "getValues", "getFeatureValues", "getSubValues", "getOwnedValues"]) {
        def kids = call0(v, m)
        if (kids instanceof Map) kids = kids.entrySet().collect { it }
        if (kids instanceof Collection) {
            for (k in kids) {
                def kv = k instanceof Map.Entry ? k.getValue() : k
                def kf = k instanceof Map.Entry ? k.getKey() : (call0(k, "getFeature") ?: call0(k, "getDefinition"))
                String kname = kf == null ? clean(call0(kv, "getName")) : clean(nameOf(kf) ?: kf)
                if (kname == "result" || kname.endsWith(": result") || kname.endsWith("::result")) {
                    def b = verdictOf(kv instanceof Collection ? new ArrayList(kv) : [kv])
                    if (b != null) return b
                }
            }
        }
    }
    return null
}

def cl = RootNamespaces.getClassLoader()
Class evaluatorClass = null, mleClass = null
try { evaluatorClass = Class.forName("com.dassault_systemes.modeler.kerml.evaluation.Evaluator", true, cl) } catch (Throwable t) { }
try { mleClass = Class.forName("com.dassault_systemes.modeler.kerml.model.evaluation.ModelLevelExpressionEvaluator", true, cl) } catch (Throwable t) { }

def out = new StringBuilder()
int n = 0
req.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.each { line ->
    def f = line.split(java.util.regex.Pattern.quote("|"), -1)
    String id = f[0]
    def feature = findPath(f[1].split("::") as List)
    n++
    if (feature == null) { out.append("EVAL|" + id + "|none|-|not found: " + f[1] + "\n"); return }
    Boolean verdict = null
    String used = "-", detail = ""
    if (evaluatorClass != null) {
        try {
            def ev = evaluatorClass.getConstructor().newInstance()
            List values = ev.evaluate(feature)
            List errors = call0(ev, "getErrors") ?: []
            out.append("TRY|" + id + "|evaluator|" + describe(values) + "|" + errors.collect { clean(it) }.join("; ") + "\n")
            verdict = verdictOf(values)
            if (verdict == null) {
                for (v in (values ?: [])) {
                    out.append("VALUE|" + id + "|" + v.getClass().getName() + "|" + dumpValue(v) + "\n")
                    def entries = keyed(v)
                    out.append("KEYS|" + id + "|" + entries.collect { it.name + "=" + describe(wrapperValues(it.wrapper)).take(80) }.join(", ") + "\n")
                    if (entries) out.append("WRAPPER|" + id + "|" + entries[0].wrapper.getClass().getName() + "|" + dumpValue(entries[0].wrapper) + "\n")
                    verdict = resultOf(v, 0)
                    if (verdict != null) break
                }
            }
            if (verdict != null) { used = "evaluator"; detail = describe(values) }
            else detail = "evaluator gave no Boolean; errors: " + errors.collect { clean(it) }.join("; ")
        } catch (Throwable t) {
            out.append("TRY|" + id + "|evaluator|threw|" + clean(t) + "\n")
            detail = "evaluator threw " + clean(t)
        }
    }
    if (verdict == null && mleClass != null) {
        try {
            def mle = mleClass.getField("INSTANCE").get(null)
            def owner = call0(feature, "getOwner")
            List values = mle.evaluate(feature, owner)
            out.append("TRY|" + id + "|modelLevel|" + describe(values) + "|\n")
            verdict = verdictOf(values)
            if (verdict != null) { used = "modelLevel"; detail = describe(values) }
        } catch (Throwable t) {
            out.append("TRY|" + id + "|modelLevel|threw|" + clean(t) + "\n")
            detail += "; modelLevel threw " + clean(t)
        }
    }
    out.append("EVAL|" + id + "|" + (verdict == null ? "none" : verdict.toString()) + "|" + used + "|" + clean(detail) + "\n")
}
out.append("RESULT|OK|" + n + " cases\n")
return out.toString()
