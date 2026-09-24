// Probes how a project can be closed WITHOUT the "has been modified. Save changes?" question. A test run that
// creates scratch projects has to free them again - eight of them took CATIA Magic from 3 GB to 11.5 GB - and a
// close that waits for a click cannot be part of an automated run (2026-09-24).
// Read-only: it closes nothing and changes nothing.
// Output lines (no System.exit):
//   PROJECTS|<count>|<names>                      METHOD|<owner>|<signature>
//   OPTION|<class>|<found>|<signature>            RESULT|OK or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application

def app = Application.getInstance()
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def cl = app.getClass().getClassLoader()

def projects = app.getProjectsManager().getProjects() ?: []
out.append("PROJECTS|" + projects.size() + "|" + clean(projects.collect { call0(it, "getName") }.join(", ")) + "\n")

// on the project itself: anything that clears the modified flag, so a close has nothing to ask about
def sample = app.getProject()
if (sample != null) {
    sample.getClass().getMethods()
        .findAll { it.name ==~ /(?i).*(dirty|modif|save|close|discard).*/ }
        .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
        .toSorted().unique().each { out.append("METHOD|Project|" + it + "\n") }
}

// on the manager: a close that takes a flag, or a silent variant
app.getProjectsManager().getClass().getMethods()
    .findAll { it.name ==~ /(?i).*(close|discard|silent|force).*/ }
    .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
    .toSorted().unique().each { out.append("METHOD|ProjectsManager|" + it + "\n") }

// and the environment switches that suppress questions
["com.nomagic.magicdraw.core.ApplicationEnvironment",
 "com.nomagic.magicdraw.core.options.EnvironmentOptions",
 "com.nomagic.magicdraw.core.options.GeneralOptions",
 "com.nomagic.magicdraw.core.project.ProjectsManager"].each { String n ->
    try {
        Class c = Class.forName(n, true, cl)
        out.append("OPTION|" + n + "|true|-\n")
        c.getMethods()
            .findAll { it.name ==~ /(?i).*(silent|question|ask|confirm|prompt|dialog|save).*/ }
            .collect { m -> (java.lang.reflect.Modifier.isStatic(m.modifiers) ? "static " : "") + m.name +
                "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
            .toSorted().unique().take(15).each { out.append("OPTION|" + c.getSimpleName() + "|-|" + it + "\n") }
    } catch (Throwable t) { out.append("OPTION|" + n + "|false|-\n") }
}

return out.append("RESULT|OK\n").toString()
