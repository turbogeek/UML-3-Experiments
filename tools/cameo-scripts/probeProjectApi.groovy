// Probes the CATIA Magic project API: what is open, and which methods exist for opening a project from a file.
// Read-only: it opens nothing and changes nothing. Used once to design openProject.groovy (harness step --open).
// Output lines (no System.exit):
//   PROJECT|<name or none>|<id>|<dirty>       ROOTS|<root namespace count>
//   MANAGER|<ProjectsManager class>           METHOD|ProjectsManager|<signature>
//   FACTORY|<class>|<found>                   FMETHOD|<class>|<signature>
//   RESULT|OK or RESULT|FAIL|<reason>
import com.nomagic.magicdraw.core.Application

def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\r", "").replace("\n", " ") }
def call0 = { Object o, String m -> try { (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { null } }

def app = Application.getInstance()
def project = app.getProject()
if (project == null) {
    out.append("PROJECT|none|-|-\n")
} else {
    out.append("PROJECT|" + clean(call0(project, "getName")) + "|" + clean(call0(project, "getID")) + "|" +
        clean(call0(project, "isDirty")) + "\n")
    try {
        def roots = Class.forName("com.dassault_systemes.modeler.kerml.model.RootNamespaces",
            true, Application.getInstance().getClass().getClassLoader())
        out.append("ROOTS|" + (roots.getAllRoots(project)?.size()) + "\n")
    } catch (Throwable t) { out.append("ROOTS|unavailable: " + clean(t) + "\n") }
}

def pm = app.getProjectsManager()
out.append("MANAGER|" + (pm == null ? "null" : pm.getClass().getName()) + "\n")
if (pm != null) {
    pm.getClass().getMethods()
        .findAll { it.name in ["loadProject", "createProject", "closeProject", "saveProject", "loadProjectFromFile",
                               "getProjects", "setActiveProject", "getActiveProject"] }
        .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
        .toSorted().unique().each { out.append("METHOD|ProjectsManager|" + it + "\n") }
}

// the factory that turns a File/URI into the ProjectDescriptor that loadProject wants, and the SysML v2 project type
def cl = Application.getInstance().getClass().getClassLoader()
["com.nomagic.magicdraw.core.project.ProjectDescriptorsFactory",
 "com.nomagic.magicdraw.core.ProjectUtilities",
 "com.dassault_systemes.modeler.sysml.project.SysMLProjectType",
 "com.nomagic.magicdraw.core.project.ProjectDescriptor"].each { String name ->
    try {
        Class c = Class.forName(name, true, cl)
        out.append("FACTORY|" + name + "|true\n")
        c.getMethods()
            .findAll { java.lang.reflect.Modifier.isStatic(it.modifiers) && it.name.toLowerCase().contains("descriptor") }
            .collect { m -> m.name + "(" + m.parameterTypes.collect { it.simpleName }.join(", ") + ") -> " + m.returnType.simpleName }
            .toSorted().unique().take(20).each { out.append("FMETHOD|" + name + "|" + it + "\n") }
    } catch (Throwable t) {
        out.append("FACTORY|" + name + "|false\n")
    }
}

return out.append("RESULT|OK\n").toString()
