// READ-ONLY diagnostic for experiment E22 P5: the public API of the SysML v2 expression and requirement evaluators,
// so that a later probe can evaluate a satisfy requirement usage from a script.
// Output: CLASS|name|modifiers|superclass   CTOR|name|parameters   FIELD|name|static field : type
//         METHOD|name|[static] returnType method(parameters)   RESULT|OK   (also written to uml3-evaluation-api2.txt)
// Must run inside CATIA Magic through the harness; outside it reports that no application is running. No System.exit.
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import java.lang.reflect.Modifier

def out = new StringBuilder()
def cl = null
try { cl = RootNamespaces.getClassLoader() } catch (Throwable t) { return "RESULT|FAIL|not inside CATIA Magic: " + t }
def names = [
    "com.dassault_systemes.modeler.kerml.model.evaluation.ModelLevelExpressionEvaluator",
    "com.dassault_systemes.modeler.kerml.model.evaluation.ModelLevelExpressionEvaluatorContext",
    "com.dassault_systemes.modeler.kerml.evaluation.EvaluationServices",
    "com.dassault_systemes.modeler.kerml.evaluation.Evaluator",
    "com.dassault_systemes.modeler.kerml.evaluation.ModelEvaluation",
    "com.dassault_systemes.modeler.kerml.evaluation.ModelLevelExpressionEvaluation",
    "com.dassault_systemes.modeler.kerml.evaluation.EvaluationUtils",
    "com.dassault_systemes.modeler.kerml.evaluation.EvaluationConfig",
    "com.dassault_systemes.modeler.sysml.evaluation.SysMLEvaluationServices",
    "com.dassault_systemes.modeler.sysml.evaluation.SysMLEvaluationUtils",
]
def simple = { Class c -> c == null ? "null" : c.getSimpleName() }
names.each { n ->
    try {
        Class c = Class.forName(n, false, cl)
        out.append("CLASS|" + n + "|" + Modifier.toString(c.getModifiers()) + "|" + simple(c.getSuperclass()) +
            "|interfaces=" + c.getInterfaces().collect { simple(it) }.join(",") + "\n")
        c.getConstructors().each { k -> out.append("CTOR|" + c.getSimpleName() + "|" + k.getParameterTypes().collect { simple(it) }.join(", ") + "\n") }
        c.getFields().findAll { Modifier.isStatic(it.getModifiers()) }.each { f ->
            out.append("FIELD|" + c.getSimpleName() + "|static " + f.getName() + " : " + simple(f.getType()) + "\n")
        }
        c.getMethods().findAll { it.getDeclaringClass() == c }.sort { it.getName() }.each { m ->
            out.append("METHOD|" + c.getSimpleName() + "|" + (Modifier.isStatic(m.getModifiers()) ? "static " : "") +
                simple(m.getReturnType()) + " " + m.getName() + "(" + m.getParameterTypes().collect { simple(it) }.join(", ") + ")\n")
        }
    } catch (Throwable t) {
        out.append("CLASS|" + n + "|FAIL|" + t.toString().replace("|", "/") + "\n")
    }
}
out.append("RESULT|OK\n")
try {
    new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-evaluation-api2.txt").setText(out.toString(), "UTF-8")
} catch (Throwable ignored) { }
return out.toString()
