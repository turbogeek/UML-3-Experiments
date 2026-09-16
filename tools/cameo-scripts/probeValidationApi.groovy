// READ-ONLY diagnostic: discover the validation API and installed suites in this CATIA Magic version.
import com.nomagic.magicdraw.core.Application

def sb = new StringBuilder()
def proj = Application.getInstance().getProject()
if (proj == null) return "NO_PROJECT"
def loader = Application.getInstance().getClass().getClassLoader()

def candidates = [
    "com.nomagic.magicdraw.validation.ValidationHelper",
    "com.nomagic.magicdraw.validation.ValidationRunData",
    "com.nomagic.magicdraw.validation.ValidationSuiteHelper",
    "com.nomagic.magicdraw.validation.RuleViolationResult",
    "com.nomagic.magicdraw.validation.ValidationConstants",
    "com.nomagic.magicdraw.validation.ValidationHelperInternal"
]
def found = [:]
candidates.each { cn ->
    try {
        def c = Class.forName(cn, true, loader)
        found[cn] = c
        sb.append("CLASS " + cn + "\n")
        c.getDeclaredMethods().findAll { java.lang.reflect.Modifier.isPublic(it.getModifiers()) }
            .collect { (java.lang.reflect.Modifier.isStatic(it.getModifiers()) ? "static " : "") + it.getName() + "(" + it.getParameterTypes().collect { p -> p.getSimpleName() }.join(",") + ") -> " + it.getReturnType().getSimpleName() }
            .unique().sort().each { sb.append("    " + it + "\n") }
    } catch (Throwable t) {
        sb.append("MISSING " + cn + " (" + t.getClass().getSimpleName() + ")\n")
    }
}

// Installed suites: try ValidationSuiteHelper.getInstance(project).getValidationSuites()
try {
    def helperClass = found["com.nomagic.magicdraw.validation.ValidationSuiteHelper"]
    if (helperClass != null) {
        def helper = helperClass.getMethod("getInstance", com.nomagic.magicdraw.core.Project).invoke(null, proj)
        def suites = []
        ["getValidationSuites", "getSuites", "getAllSuites"].each { m ->
            if (suites.isEmpty() && helper.respondsTo(m)) {
                try { suites = helper."$m"() ?: [] ; sb.append("suites via " + m + ": " + suites.size() + "\n") } catch (Throwable t) { sb.append(m + " threw " + t + "\n") }
            }
        }
        suites.each { s ->
            def n = null
            try { n = s.respondsTo("getName") ? s.getName() : s.toString() } catch (x) { n = s.toString() }
            sb.append("  SUITE " + n + "\n")
        }
    }
} catch (Throwable t) {
    sb.append("suite listing failed: " + t + "\n")
}
return sb.toString()
