// READ-ONLY: run CATIA Magic's KerML/SysML validation engine (active + passive suites) on every
// loaded package whose name starts with UML3 or OnlineStore, and report failures per package.
// API (javap on com.dassault_systemes.modeler.kerml.validation jar, 2026x R1):
//   ValidationService.getInstance(BaseElement).createParams(Collection<Element>)
//     .addActiveSuites().addPassiveSuites();  validate(params) -> Collection<ValidationFailure>
//   ValidationFailure: getValidationRuleName(), getSeverityLevel(), getMessage(), getElement()
// Output lines:  SUITES|n|names   PKG|name|elements|failures   FAIL|pkg|severity|rule|element|message
// Validation classes are loaded reflectively from the KerML plugin class loader so a missing
// class is reported instead of failing script compilation.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def out = new StringBuilder()
def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"

def PREFIXES = ["UML3", "OnlineStore"]
def nameOf = { e -> try { e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def membersOf = { e -> try { e.respondsTo("getOwnedMember") ? (e.getOwnedMember() ?: []) : [] } catch (x) { [] } }
def clean = { Object t -> t == null ? "" : t.toString().replace("|", "/").replace("\n", " ").replace("\r", " ") }

Class serviceClass
try {
    serviceClass = Class.forName("com.dassault_systemes.modeler.kerml.validation.ValidationService", true, RootNamespaces.getClassLoader())
} catch (Throwable t) {
    return "ERROR|ValidationService not loadable: " + clean(t)
}

def packages = []
(RootNamespaces.getAllRoots(proj) ?: []).each { r ->
    membersOf(r).each { p ->
        def nm = nameOf(p)
        if (nm != null && PREFIXES.any { nm.startsWith(it) }) packages << p
    }
}
if (packages.isEmpty()) return "ERROR|no UML3/OnlineStore packages loaded"

def service = serviceClass.getMethod("getInstance", com.nomagic.magicdraw.uml.BaseElement).invoke(null, packages[0])
try {
    def probeParams = service.createParams(packages).addActiveSuites().addPassiveSuites()
    def suites = probeParams.getSuites() ?: []
    out.append("SUITES|" + suites.size() + "|" + clean(suites.collect { it.getName() }.join(", ")) + "\n")
} catch (Throwable t) {
    out.append("SUITES|?|" + clean(t) + "\n")
}

packages.each { p ->
    // all KerML elements owned (recursively) by the package, including the package itself
    def elements = [p]
    try {
        def it = p.eAllContents()
        while (it.hasNext()) {
            def e = it.next()
            if (e instanceof com.dassault_systemes.modeler.kerml.model.kerml.Element) elements << e
        }
    } catch (Throwable t) {
        out.append("WARN|" + nameOf(p) + "|eAllContents failed " + clean(t) + "\n")
    }
    try {
        def params = service.createParams(elements).addActiveSuites().addPassiveSuites()
        def failures = service.validate(params) ?: []
        out.append("PKG|" + nameOf(p) + "|" + elements.size() + "|" + failures.size() + "\n")
        failures.each { f ->
            def el = null
            try { el = f.getElement() } catch (x) {}
            String elName = nameOf(el) ?: (el == null ? "" : el.getClass().getSimpleName())
            out.append("FAIL|" + nameOf(p) + "|" + clean(f.getSeverityLevel()) + "|" + clean(f.getValidationRuleName()) +
                       "|" + clean(elName) + "|" + clean(f.getMessage()) + "\n")
        }
    } catch (Throwable t) {
        out.append("PKG|" + nameOf(p) + "|" + elements.size() + "|ERROR " + clean(t) + "\n")
    }
}
return out.toString()
