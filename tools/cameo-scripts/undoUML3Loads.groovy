// SELF-LIMITING cleanup for UML-3-Experiments loads: undo recent commands ONLY until the
// packages loaded by tools/cameo_check.py are gone, then stop. Those loads are the most recent
// undo entries, so this undoes exactly them. Bounded to 25 undos. Run via /run-script.
import com.nomagic.magicdraw.core.Application
import com.nomagic.magicdraw.actions.ActionsProvider
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import javax.swing.SwingUtilities

def app = Application.getInstance()
// Prefixes cover the library (UML3*), probes (UML3Probe*) and examples (OnlineStore*).
def MINE_PREFIXES = ["UML3", "OnlineStore"]
// Exact package names of other test loads (e.g. IDL imports), one per line, written by the test tooling.
def extraFile = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-undo-extra.txt")
def MINE_NAMES = extraFile.exists() ? (extraFile.readLines("UTF-8").collect { it.trim() }.findAll { it && !it.startsWith("#") } as Set) : ([] as Set)
// Optional exact bound (uml3-undo-limit.txt, one integer): undo exactly that many harness commands, even if packages
// with UML3 names remain. Used when earlier loads (e.g. a model the user is reviewing) must survive. Deleted once read.
def limitFile = new File(extraFile.parentFile, "uml3-undo-limit.txt")
Integer LIMIT = null
if (limitFile.exists()) {
    try { LIMIT = Integer.valueOf(limitFile.getText("UTF-8").trim()) } catch (Throwable ignored) {}
    limitFile.delete()
}
// Optional (uml3-undo-only.txt, one command name per line): undo ONLY commands with these names, as long as one is on
// top (at most 50), e.g. the asynchronous 'Layout diagram' commands that follow a view-diagram run (E13). Deleted once read.
def onlyFile = new File(extraFile.parentFile, "uml3-undo-only.txt")
Set<String> ONLY = null
if (onlyFile.exists()) {
    ONLY = onlyFile.readLines("UTF-8").collect { it.trim() }.findAll { it && !it.startsWith("#") } as Set
    onlyFile.delete()
}
def sb = new StringBuilder()

// RootNamespaces are unnamed Namespaces; the packages are their owned members.
def countMine = {
    def proj = app.getProject()
    if (proj == null) return -1
    int cnt = 0
    (RootNamespaces.getAllRoots(proj) ?: []).each { r ->
        def members = []
        try { members = r.respondsTo("getOwnedMember") ? (r.getOwnedMember() ?: []) : [] } catch (x) {}
        members.each { m ->
            try {
                if (m.respondsTo("getName")) {
                    def nm = m.getName()
                    if (nm != null && (MINE_PREFIXES.any { nm.startsWith(it) } || MINE_NAMES.contains(nm))) cnt++
                }
            } catch (x) {}
        }
    }
    return cnt
}

SwingUtilities.invokeAndWait({
    try {
        def am = ActionsProvider.getInstance().getMainMenuActions()
        sb.append("myPackagesBefore=" + countMine() + (LIMIT != null ? " limit=" + LIMIT : "") + "\n")
        int n = 0
        // SAFETY GUARD (added after an audit found 'General View' / 'Multiple add' commands interleaved
        // with harness loads): only undo commands created by the harness load endpoint. Anything else on
        // top of the undo stack may be the user's work, so stop and report it instead of undoing it.
        final Set<String> HARNESS_COMMANDS = ONLY != null ? ONLY :
            (["SysMLv2TestHarness: REST Load SysML", "UML3 IDL Import", "UML3 View Diagrams"] as Set)
        if (ONLY != null) sb.append("only=" + ONLY + "\n")
        def history = app.getProject().getCommandHistory()
        while (n < (LIMIT != null ? LIMIT : (ONLY != null ? 50 : 25))) {
            if (LIMIT == null && ONLY == null && countMine() <= 0) { sb.append("clean -- none of my packages remain\n"); break }
            def top = history.getCommandForUndo()
            String topName = null
            try { topName = top == null ? null : top.getName() } catch (x) { topName = String.valueOf(top) }
            if (top == null) { sb.append("no further undo available\n"); break }
            if (!HARNESS_COMMANDS.contains(topName)) {
                // with an only-list, reaching a command outside the list is the normal end (e.g. the IDL import
                // below the view diagrams); without one, a foreign command means the user's work is on top
                sb.append(ONLY != null
                    ? "DONE nextCommand=" + topName + " -- not in the only-list, left for the caller\n"
                    : "STOPPED foreignCommandOnTop=" + topName + " -- not undone; resolve manually\n")
                break
            }
            def undo = am.getActionFor("UNDO")
            if (undo == null || !undo.isEnabled()) { sb.append("no further undo available\n"); break }
            undo.actionPerformed(null)
            n++
        }
        sb.append("undosPerformed=" + n + " myPackagesAfter=" + countMine() + "\n")
    } catch (Throwable t) {
        def w = new java.io.StringWriter(); t.printStackTrace(new java.io.PrintWriter(w))
        sb.append("ERR " + t + "\n" + w.toString() + "\n")
    }
} as Runnable)
return sb.toString()
