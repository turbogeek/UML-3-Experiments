// Removes leftover test packages from the open CATIA Magic project when the undo history no longer holds the
// commands that loaded them (the history has a maximum size). Only ROOT-LEVEL packages whose names are listed
// EXACTLY in uml3-clean-request.txt (one name per line) are removed; nothing else is touched.
// All removals happen in one session named "UML3 Clean Project", so the clean-up itself can be undone.
// Output: FOUND|name|class   REMOVED|name   SKIPPED|name|reason   RESULT|OK|n removed  or  RESULT|FAIL|reason
// Must run inside CATIA Magic (harness /run-script); outside it reports that no project is open. No System.exit.
import com.nomagic.magicdraw.core.Application
import com.nomagic.magicdraw.openapi.uml.ModelElementsManager
import com.nomagic.magicdraw.openapi.uml.SessionManager
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import javax.swing.SwingUtilities

def project = Application.getInstance().getProject()
if (project == null) return "RESULT|FAIL|no open project (run inside CATIA Magic through the SysMLv2 test harness)"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }

def req = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-clean-request.txt")
if (!req.exists()) return "RESULT|FAIL|missing " + req
Set<String> names = req.readLines("UTF-8").collect { it.trim() }.findAll { it && !it.startsWith("#") } as Set
if (names.isEmpty()) return "RESULT|FAIL|no package names in " + req

List targets = []
(RootNamespaces.getAllRoots(project) ?: []).each { root ->
    (call0(root, "getOwnedMember") ?: []).each { m ->
        String n = call0(m, "getName")
        if (n != null && names.contains(n)) {
            String cls = m.getClass().getSimpleName()
            out.append("FOUND|" + n + "|" + cls + "\n")
            if (cls.contains("Package")) targets << m else out.append("SKIPPED|" + n + "|not a package\n")
        }
    }
}
int removed = 0
SwingUtilities.invokeAndWait({
    def sm = SessionManager.getInstance()
    try {
        sm.createSession(project, "UML3 Clean Project")
        targets.each { pkg ->
            String n = call0(pkg, "getName")
            try {
                ModelElementsManager.getInstance().removeElement(pkg)
                out.append("REMOVED|" + n + "\n")
                removed++
            } catch (Throwable t) {
                out.append("SKIPPED|" + n + "|" + clean(t) + "\n")
            }
        }
        sm.closeSession(project)
    } catch (Throwable t) {
        out.append("RESULT|FAIL|session: " + clean(t) + "\n")
        try { if (sm.isSessionCreated(project)) sm.cancelSession(project) } catch (Throwable ignored) {}
    }
} as Runnable)
out.append("RESULT|OK|" + removed + " removed\n")
return out.toString()
