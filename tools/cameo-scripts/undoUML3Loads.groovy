// SELF-LIMITING cleanup for UML-3-Experiments loads: undo recent commands ONLY until the
// packages loaded by tools/cameo_check.py are gone, then stop. Those loads are the most recent
// undo entries, so this undoes exactly them. Bounded to 25 undos. Run via /run-script.
import com.nomagic.magicdraw.core.Application
import com.nomagic.magicdraw.actions.ActionsProvider
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import javax.swing.SwingUtilities

def app = Application.getInstance()
def MINE = ["UML3Core", "UML3Types", "UML3Components", "UML3Messaging", "UML3Data",
            "OnlineStoreDomain", "OnlineStoreArchitecture", "OnlineStoreMessaging", "OnlineStoreDatabase"] as Set
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
            try { if (m.respondsTo("getName") && MINE.contains(m.getName())) cnt++ } catch (x) {}
        }
    }
    return cnt
}

SwingUtilities.invokeAndWait({
    try {
        def am = ActionsProvider.getInstance().getMainMenuActions()
        sb.append("myPackagesBefore=" + countMine() + "\n")
        int n = 0
        while (n < 25) {
            if (countMine() <= 0) { sb.append("clean -- none of my packages remain\n"); break }
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
