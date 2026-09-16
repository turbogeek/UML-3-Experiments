// READ-ONLY diagnostic: list diagrams in the project (name, type, owner) and the last commands of the
// undo history, to find out whether/when CATIA Magic materializes SysML v2 views as diagrams.
// Output: HIST|size|last commands   DIAG|name|type|ownerName|ownerClass
import com.nomagic.magicdraw.core.Application

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\n", " ") }
def nameOf = { e -> try { e != null && e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }

try {
    def h = proj.getCommandHistory()
    def cmds = h.getCommands() ?: []
    def names = cmds.collect { c -> try { c.getName() } catch (x) { c.toString() } }
    out.append("HIST|" + cmds.size() + "|" + names.takeRight(6).collect { clean(it) }.join(" ;; ") + "\n")
} catch (Throwable t) {
    out.append("HIST|EXC|" + clean(t) + "\n")
}

def diagrams = []
try { diagrams = proj.getDiagrams() ?: [] } catch (Throwable t) { out.append("DIAG|EXC|" + clean(t) + "||\n") }
out.append("DIAGCOUNT|" + diagrams.size() + "\n")
diagrams.each { d ->
    String type = null
    def owner = null
    try { type = d.getDiagramType()?.getType() } catch (x) { type = "?" }
    try { owner = d.getDiagram()?.getOwner() } catch (x) {}
    String ownerName = nameOf(owner)
    try { if (ownerName == null && owner != null && owner.respondsTo("getHumanName")) ownerName = owner.getHumanName() } catch (x) {}
    out.append("DIAG|" + clean(d.getName()) + "|" + clean(type) + "|" + clean(ownerName) + "|" +
               clean(owner == null ? null : owner.getClass().getSimpleName()) + "\n")
}
return out.toString()
