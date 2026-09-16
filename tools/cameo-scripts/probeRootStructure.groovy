// READ-ONLY diagnostic: describe the shape of RootNamespaces so name searches can be written correctly.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def sb = new StringBuilder()
def proj = Application.getInstance().getProject()
if (proj == null) return "NO_PROJECT"
def roots = RootNamespaces.getAllRoots(proj)
int i = 0
roots.each { r ->
    if (i++ >= 4) return
    String nm = null
    try { nm = r.respondsTo("getName") ? r.getName() : "(no getName)" } catch (x) { nm = "ERR " + x }
    def kids = []
    try { kids = r.respondsTo("getOwnedMember") ? r.getOwnedMember() : r.eContents() } catch (x) { sb.append("kidsErr " + x + "\n") }
    sb.append("root[" + (i - 1) + "] class=" + r.getClass().getSimpleName() + " name=" + nm + " kids=" + kids.size() + "\n")
    int k = 0
    kids.each { c ->
        if (k++ >= 3) return
        String cn = null
        try { cn = c.respondsTo("getName") ? c.getName() : "(no getName)" } catch (x) { cn = "ERR" }
        sb.append("    child class=" + c.getClass().getSimpleName() + " name=" + cn + "\n")
    }
}
return sb.toString()
