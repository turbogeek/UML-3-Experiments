// READ-ONLY: report top-level packages (and their direct members) belonging to the UML3 experiment.
// RootNamespaces are unnamed Namespaces whose owned members are the packages (see probeRootStructure.groovy).
// Run via harness /run-script. Makes no model changes.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def PREFIXES = ["UML3", "OnlineStore", "N0"]
def sb = new StringBuilder()
def proj = Application.getInstance().getProject()
if (proj == null) return "NO_PROJECT"
sb.append("project=" + proj.getName() + "\n")

def nameOf = { e -> try { e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def membersOf = { e -> try { e.respondsTo("getOwnedMember") ? (e.getOwnedMember() ?: []) : [] } catch (x) { [] } }

def roots = RootNamespaces.getAllRoots(proj) ?: []
sb.append("rootCount=" + roots.size() + "\n")
def counts = [:]
boolean control = false
roots.each { r ->
    membersOf(r).each { pkg ->
        String nm = nameOf(pkg)
        if (nm == "ScalarValues") control = true
        if (nm != null && PREFIXES.any { nm.startsWith(it) }) {
            counts[nm] = (counts[nm] ?: 0) + 1
            sb.append("found " + nm + " (" + pkg.getClass().getSimpleName() + ") members=" + membersOf(pkg).size() + "\n")
        }
    }
}
counts.each { k, v -> if (v > 1) sb.append("DUPLICATE " + k + " x" + v + "\n") }
sb.append("matches=" + counts.size() + "\n")
// Positive control: a standard library package must be found, otherwise matches=0 proves nothing.
sb.append("controlScalarValuesVisible=" + control + "\n")
return sb.toString()
