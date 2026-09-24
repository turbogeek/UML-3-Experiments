// Makes sure a project is open in CATIA Magic, so a test run does not depend on someone having opened one
// (harness step --open). Request: uml3-open-request.txt next to this script:
//     mode=report                  report what is open, change nothing (default when no source is named)
//     mode=create                  create an empty project from template= (nothing is read from disk but the
//                                  template, nothing is ever saved): the repeatable choice for tests
//     mode=open                    open the local project file named by project=
//     mode=close                   close the projects named by closeProject= lines, freeing their memory. Only
//                                  exact names are closed, never a pattern: a run must not guess which project
//                                  someone is working in. Nothing is saved, so name only projects you created.
//     template=auto                 find the stock SysML v2 template in this installation (templates/SysML v2/),
//                                  so no machine-specific path is written down anywhere
//     template=<path to a .mdszip/.mdzip project template>
//     project=<path to a local .mdzip/.mdxml project>
//     force=true                   with mode=create, create even when a project is already open (CATIA Magic
//                                  holds several at once, so the open one is not touched); an experiment that
//                                  needs an untouched project asks for this
//     timeoutSeconds=<n>           how long to wait for CATIA Magic (default 180)
// It never saves and never closes a project, and an already open project is left alone whatever the request
// says: a run must not discard someone's unsaved work.
//
// Why the bounded wait: project work runs on the event dispatch thread, and a modal dialog there (a failed
// load, a question) blocks it until someone clicks. The harness runs one script at a time, so an unbounded
// wait would block every later run, including the ones that could say what is on screen. This script therefore
// posts its work with invokeLater and waits with a timeout; on timeout it returns BLOCKED and the harness stays
// usable - run probeOpenWindows.groovy next to see the dialog.
//   Observed 2026-09-24: loadProject on a .mdszip (a Teamwork Cloud export, not a local project) showed a modal
//   error dialog and held the EDT for 14 minutes. E:\LocalConfigs\2026xR1\msosa.log named the cause.
// Output lines (no System.exit):
//   OPEN|<name>|<id>|dirty=<true/false>|<source>    source: already-open, created, opened, none
//   ROOTS|<root namespace count>                    FILE|<path>|exists=<true/false>
//   TEMPLATE|<how it was found>|<path>              (only with template=auto)
//   BLOCKED|<stage>|<seconds>                       ERROR|<stage>|<message>
//   RESULT|OK|<name> or RESULT|FAIL|<reason> or RESULT|BLOCKED|<reason>
import com.nomagic.magicdraw.core.Application
import com.nomagic.magicdraw.core.project.ProjectDescriptorsFactory
import com.dassault_systemes.modeler.kerml.model.RootNamespaces
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.swing.SwingUtilities

def app = Application.getInstance()
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }

def dir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
def reqFile = new File(dir, "uml3-open-request.txt")
String path = null, template = null, mode = null
int timeoutSeconds = 180
boolean force = false
List<String> closeNames = []
if (reqFile.exists()) {
    reqFile.readLines("UTF-8").each { l ->
        if (l.startsWith("project=")) path = l.substring(8).trim()
        else if (l.startsWith("template=")) template = l.substring(9).trim()
        else if (l.startsWith("mode=")) mode = l.substring(5).trim()
        else if (l.startsWith("closeProject=")) closeNames << l.substring(13).trim()
        else if (l.trim() == "force=true") force = true
        else if (l.startsWith("timeoutSeconds=")) timeoutSeconds = l.substring(15).trim() as int
    }
}
if (mode == null) mode = template ? "create" : (path ? "open" : "report")

def describe = { project, String source ->
    out.append("OPEN|" + clean(call0(project, "getName")) + "|" + clean(call0(project, "getID")) + "|dirty=" +
        clean(call0(project, "isDirty")) + "|" + source + "\n")
    // a SysML v2 project has KerML root namespaces; a plain UML project has none, which is what tells the two
    // apart after createProjectFromTemplate
    try {
        out.append("ROOTS|" + (RootNamespaces.getAllRoots(project)?.size()) + "\n")
    } catch (Throwable t) { out.append("ERROR|roots|" + clean(t) + "\n") }
}

// mode=close: free the projects a run created. Each project holds a whole SysML v2 template (101 root
// namespaces), so leaving them open costs real memory, and every open project keeps its documents registered
// with the window manager, which is what rots over a long session (I-45). Closed one at a time with a bounded
// wait, because a dirty project may ask whether to save and that question blocks the event thread.
if (mode == "close") {
    if (closeNames.isEmpty()) return out.append("RESULT|FAIL|mode=close needs closeProject=<name> lines\n").toString()
    int closed = 0
    for (String wanted : closeNames) {
        def match = (app.getProjectsManager().getProjects() ?: []).find { clean(call0(it, "getName")) == wanted }
        if (match == null) { out.append("CLOSE|" + wanted + "|not open\n"); continue }
        out.append("CLOSE|" + wanted + "|dirty=" + clean(call0(match, "isDirty")) + "\n")
        def problem = new java.util.concurrent.atomic.AtomicReference(null)
        def finished = new CountDownLatch(1)
        SwingUtilities.invokeLater({
            // closeProjectNoSave discards without asking; plain closeProject puts "The project X has been
            // modified. Save changes?" on screen and waits for a click, which no automated run can answer.
            // Only ever called on projects the caller named, and these are scratch projects made from the
            // stock template, so there is nothing to lose.
            try { app.getProjectsManager().closeProjectNoSave(match) } catch (Throwable t) { problem.set(t) }
            finally { finished.countDown() }
        } as Runnable)
        if (!finished.await(timeoutSeconds, TimeUnit.SECONDS)) {
            out.append("BLOCKED|close " + wanted + "|" + timeoutSeconds + "\n")
            return out.append("RESULT|BLOCKED|closing " + wanted + " did not finish; a save question is " +
                "probably on screen\n").toString()
        }
        if (problem.get() != null) out.append("ERROR|close " + wanted + "|" + clean(problem.get()) + "\n")
        else closed++
    }
    out.append("OPEN|" + clean(call0(app.getProject(), "getName")) + "|-|dirty=-|after-close\n")
    return out.append("RESULT|OK|closed " + closed + " of " + closeNames.size() + "\n").toString()
}

def project = app.getProject()
if (project != null && !(force && mode == "create")) {
    describe(project, "already-open")
    return out.append("RESULT|OK|" + clean(call0(project, "getName")) + "\n").toString()
}
if (mode == "report") {
    out.append("OPEN|none|-|dirty=-|none\n")
    return out.append("RESULT|FAIL|no project open and mode=report\n").toString()
}

// template=auto: ask the installation where it is, so no repository file has to name a path on this machine.
// MagicDraw runs with its install directory as the working directory, which is the reliable fallback.
if (mode == "create" && template == "auto") {
    def roots = []
    ["getInstallRoot", "getHomePath", "getApplicationHome"].each { String m ->
        try {
            Class env = Class.forName("com.nomagic.magicdraw.core.ApplicationEnvironment", true,
                app.getClass().getClassLoader())
            if (env.metaClass.respondsTo(env, m)) roots << [m, env."$m"()?.toString()]
        } catch (Throwable t) { }
    }
    roots << ["user.dir", System.getProperty("user.dir")]
    def hit = null
    for (r in roots) {
        if (r[1] == null || ((String) r[1]).isEmpty()) continue
        def candidate = new File(new File((String) r[1], "templates"), "SysML v2/SysML v2.mdszip")
        if (candidate.exists()) { hit = [r[0], candidate]; break }
    }
    if (hit == null) {
        out.append("TEMPLATE|not found|" + clean(roots.collect { it[1] }.findAll { it }.join(", ")) + "\n")
        return out.append("RESULT|FAIL|no templates/SysML v2/SysML v2.mdszip under this installation\n").toString()
    }
    out.append("TEMPLATE|" + hit[0] + "|" + clean(hit[1]) + "\n")
    template = ((File) hit[1]).getAbsolutePath()
}

def source = mode == "create" ? template : path
if (source == null || source.isEmpty()) {
    out.append("OPEN|none|-|dirty=-|none\n")
    return out.append("RESULT|FAIL|mode=" + mode + " needs " + (mode == "create" ? "template=<path>" : "project=<path>") + "\n").toString()
}
def file = new File(source)
out.append("FILE|" + clean(file) + "|exists=" + file.exists() + "\n")
if (!file.exists()) return out.append("RESULT|FAIL|not found: " + clean(file) + "\n").toString()

// post the work and wait with a timeout, so a modal dialog cannot hold the harness (see the note above)
def failure = new java.util.concurrent.atomic.AtomicReference(null)
def done = new CountDownLatch(1)
SwingUtilities.invokeLater({
    try {
        if (mode == "create") {
            app.getProjectsManager().createProjectFromTemplate(file.getAbsolutePath())
        } else {
            app.getProjectsManager().loadProject(ProjectDescriptorsFactory.createProjectDescriptor(file.toURI()), true)
        }
    } catch (Throwable t) { failure.set(t) } finally { done.countDown() }
} as Runnable)

if (!done.await(timeoutSeconds, TimeUnit.SECONDS)) {
    out.append("BLOCKED|" + mode + "|" + timeoutSeconds + "\n")
    return out.append("RESULT|BLOCKED|CATIA Magic did not finish in " + timeoutSeconds +
        "s; a modal dialog is likely open (run probeOpenWindows.groovy, and read msosa.log)\n").toString()
}
if (failure.get() != null) {
    out.append("ERROR|" + mode + "|" + clean(failure.get()) + "\n")
    return out.append("RESULT|FAIL|" + mode + " threw " + clean(failure.get().getClass().getSimpleName()) + "\n").toString()
}

project = app.getProject()
if (project == null) {
    out.append("OPEN|none|-|dirty=-|none\n")
    return out.append("RESULT|FAIL|" + mode + " returned but no project is active\n").toString()
}
describe(project, mode == "create" ? "created" : "opened")
return out.append("RESULT|OK|" + clean(call0(project, "getName")) + "\n").toString()
