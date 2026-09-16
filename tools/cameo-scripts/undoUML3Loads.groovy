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
        sb.append("myPackagesBefore=" + countMine() + "\n")
        int n = 0
        // SAFETY GUARD (added after an audit found 'General View' / 'Multiple add' commands interleaved
        // with harness loads): only undo commands created by the harness load endpoint. Anything else on
        // top of the undo stack may be the user's work, so stop and report it instead of undoing it.
        final Set<String> HARNESS_COMMANDS = ["SysMLv2TestHarness: REST Load SysML", "UML3 IDL Import"] as Set
        def history = app.getProject().getCommandHistory()
        while (n < 25) {
            if (countMine() <= 0) { sb.append("clean -- none of my packages remain\n"); break }
            def top = history.getCommandForUndo()
            String topName = null
            try { topName = top == null ? null : top.getName() } catch (x) { topName = String.valueOf(top) }
            if (top == null) { sb.append("no further undo available\n"); break }
            if (!HARNESS_COMMANDS.contains(topName)) {
                sb.append("STOPPED foreignCommandOnTop=" + topName + " -- not undone; resolve manually\n")
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
