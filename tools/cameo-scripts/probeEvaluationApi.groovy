// READ-ONLY diagnostic for experiment E22 P5: is the SysML v2 Evaluation Plugin installed, and which classes could
// evaluate a requirement or constraint (a satisfy requirement usage) from a script?
// Output: PLUGIN|id|name|version|loaded  for plugins whose id or name mentions evaluation or sysml;
//         CLASS|jar|class                  for classes in the SysML v2 plugin folders whose name contains
//                                          Evaluat, Evaluator or Satisf (at most 200);
//         RESULT|OK|...  or  RESULT|FAIL|reason
// Also written to <harness scripts dir>/uml3-evaluation-api.txt. Must run inside CATIA Magic through the harness
// (/run-script); outside it reports that no application is running. No System.exit.
import com.nomagic.magicdraw.core.Application
import java.util.zip.ZipFile

def out = new StringBuilder()
def app = null
try { app = Application.getInstance() } catch (Throwable t) { return "RESULT|FAIL|not inside CATIA Magic: " + t }
if (app == null) return "RESULT|FAIL|not inside CATIA Magic (no Application)"
def clean = { Object o -> o == null ? "null" : o.toString().replace("|", "/").replace("\n", " ") }

// 1. plugins as the plugin manager sees them
try {
    def pmClass = Class.forName("com.nomagic.magicdraw.plugins.PluginManager", true, app.getClass().getClassLoader())
    def pm = pmClass.getMethod("getInstance").invoke(null)
    def plugins = pm.respondsTo("getPlugins") ? pm.getPlugins() : []
    int shown = 0
    plugins.each { p ->
        def d = p.respondsTo("getDescriptor") ? p.getDescriptor() : null
        String id = clean(d?.respondsTo("getID") ? d.getID() : null)
        String name = clean(d?.respondsTo("getName") ? d.getName() : null)
        String version = clean(d?.respondsTo("getVersion") ? d.getVersion() : null)
        if ((id + " " + name).toLowerCase() =~ /(evaluat|sysml ?v?2|sysml2|simulation)/) {
            out.append("PLUGIN|" + id + "|" + name + "|" + version + "|" + clean(p.respondsTo("isLoaded") ? p.isLoaded() : "?") + "\n")
            shown++
        }
    }
    out.append("PLUGINS|" + plugins.size() + " total, " + shown + " matching\n")
} catch (Throwable t) {
    out.append("PLUGINS|FAIL|" + clean(t) + "\n")
}

// 2. classes whose names suggest evaluation, in the plugin folders that look like SysML v2 or evaluation plugins
File root = null
try {
    def env = Class.forName("com.nomagic.magicdraw.core.ApplicationEnvironment", true, app.getClass().getClassLoader())
    root = new File(env.getMethod("getInstallRoot").invoke(null).toString())
} catch (Throwable t) {
    out.append("ROOT|FAIL|" + clean(t) + "\n")
}
int classes = 0
if (root != null) {
    File pluginsDir = new File(root, "plugins")
    out.append("ROOT|" + root + "|plugins exists=" + pluginsDir.isDirectory() + "\n")
    (pluginsDir.listFiles() ?: []).findAll { it.isDirectory() && (it.name.toLowerCase() =~ /(sysml2|sysmlv2|evaluat)/) }.each { dir ->
        out.append("DIR|" + dir.name + "\n")
        dir.eachFileRecurse { f ->
            if (classes >= 200 || !f.name.endsWith(".jar")) return
            ZipFile z = null
            try {
                z = new ZipFile(f)
                z.entries().each { e ->
                    String n = e.getName()
                    if (classes < 200 && n.endsWith(".class") && !n.contains('$') && (n =~ /(Evaluat|Satisf)/)) {
                        out.append("CLASS|" + f.name + "|" + n.replace('/', '.').replace(".class", "") + "\n")
                        classes++
                    }
                }
            } catch (Throwable t) {
                out.append("JAR|FAIL|" + f.name + "|" + clean(t) + "\n")
            } finally {
                try { z?.close() } catch (Throwable ignored) { }
            }
        }
    }
}
out.append("RESULT|OK|classes=" + classes + "\n")
try {
    new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-evaluation-api.txt").setText(out.toString(), "UTF-8")
} catch (Throwable t) {
    out.append("WRITE|FAIL|" + clean(t) + "\n")
}
return out.toString()
