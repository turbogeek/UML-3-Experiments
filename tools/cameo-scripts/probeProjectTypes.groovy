// Probes how a project can be CREATED in CATIA Magic, to find out whether a test run can make its own empty
// SysML v2 project instead of depending on a project someone opened by hand (see openUML3Project.groovy).
// Read-only: it creates nothing. Used to design the --open step of cameo_check.py.
// Output lines (no System.exit):
//   METHOD|<owner>|<signature>          TYPE|<project type class>|<name>|<id>
//   TWC|session=<true/false>            RESULT|OK or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application

def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }
def cl = Application.getInstance().getClass().getClassLoader()

def app = Application.getInstance()
def pm = app.getProjectsManager()
pm.getClass().getMethods()
    .findAll { it.name.toLowerCase().contains("create") }
    .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
    .toSorted().unique().each { out.append("METHOD|ProjectsManager|" + it + "\n") }

// the registry of project types behind File > New Project
["com.nomagic.magicdraw.core.project.ProjectDescriptorsFactory",
 "com.nomagic.magicdraw.uml.project.ProjectTypeRegistry",
 "com.nomagic.magicdraw.core.project.ProjectsManager"].each { String n ->
    try {
        Class c = Class.forName(n, true, cl)
        c.getMethods().findAll { java.lang.reflect.Modifier.isStatic(it.modifiers) }
            .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
            .toSorted().unique().take(25).each { out.append("METHOD|" + c.getSimpleName() + "|" + it + "\n") }
    } catch (Throwable t) { out.append("METHOD|" + n + "|NOT FOUND\n") }
}

// project types the installation knows, so the SysML v2 one can be named exactly
["com.nomagic.magicdraw.core.project.ProjectType",
 "com.nomagic.magicdraw.core.project.ProjectTypes",
 "com.nomagic.magicdraw.uml.project.ProjectTypeManager"].each { String n ->
    try {
        Class c = Class.forName(n, true, cl)
        out.append("TYPE|" + n + "|found|-\n")
        c.getFields().findAll { java.lang.reflect.Modifier.isStatic(it.modifiers) }.take(25).each { f ->
            try { out.append("TYPE|" + c.getSimpleName() + "|" + f.name + "|" + clean(f.get(null)) + "\n") } catch (Throwable t) { }
        }
    } catch (Throwable t) { out.append("TYPE|" + n + "|NOT FOUND|-\n") }
}

// is a Teamwork Cloud session alive? the UML3 project is a server project, and .mdszip is only its export
try {
    Class esi = Class.forName("com.nomagic.magicdraw.esi.EsiUtils", true, cl)
    def session = esi.metaClass.respondsTo(esi, "getLoggedUserName") ? esi.getLoggedUserName() : null
    out.append("TWC|session=" + (session != null) + "|" + clean(session) + "\n")
} catch (Throwable t) {
    out.append("TWC|session=unknown|" + clean(t.getClass().getSimpleName()) + "\n")
}

return out.append("RESULT|OK\n").toString()
