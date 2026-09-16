// READ-ONLY diagnostic: list undo/redo command names so the undo script's effect can be audited.
// Uses the MagicDraw project command history via reflection (respondsTo) because method names vary.
import com.nomagic.magicdraw.core.Application

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\n", " ") }
def history = null
["getCommandHistory"].each { m -> if (history == null && proj.respondsTo(m)) history = proj."$m"() }
if (history == null) return "ERROR|no command history accessor on " + proj.getClass().getName()
out.append("HISTORY|" + history.getClass().getName() + "\n")
def methods = history.getClass().getMethods().collect { it.getName() + "/" + it.getParameterCount() }.unique().sort()
out.append("METHODS|" + methods.findAll { it =~ /(?i)undo|redo|command|size|current|index/ }.join(" ") + "\n")
def nameOfCmd = { c ->
    try { c.respondsTo("getName") ? c.getName() : (c.respondsTo("getDescription") ? c.getDescription() : c.toString()) }
    catch (x) { c.toString() }
}
["getCommands", "getUndoCommands", "getRedoCommands", "getCommandsForUndo", "getCommandsForRedo"].each { m ->
    if (history.respondsTo(m)) {
        try {
            def cmds = history."$m"() ?: []
            out.append("LIST|" + m + "|" + cmds.size() + "|" + cmds.collect { clean(nameOfCmd(it)) }.takeRight(25).join(" ;; ") + "\n")
        } catch (Throwable t) {
            out.append("LIST|" + m + "|EXC " + clean(t) + "\n")
        }
    }
}
["getCurrentCommandIndex", "getUndoPresentationName", "getRedoPresentationName", "canUndo", "canRedo"].each { m ->
    if (history.respondsTo(m)) {
        try { out.append("VALUE|" + m + "|" + clean(history."$m"()) + "\n") } catch (Throwable t) { out.append("VALUE|" + m + "|EXC " + clean(t) + "\n") }
    }
}
return out.toString()
