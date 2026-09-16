// UML3 IDL export: a SysML v2 package in the open CATIA Magic project -> OMG IDL file (canonical form).
//
// Inside CATIA Magic (harness /run-script or Macro console): reads uml3-idl-export-request.txt next to this script:
//     package=<name of a root package, e.g. the file package created by importIdl>
//     core=<path to tools/idl/UML3IdlCore.groovy>      idlOut=<path of the .idl to write>
//   READ-ONLY with respect to the model: it only reads elements (no session is opened).
// Outside CATIA Magic (plain `groovy exportIdl.groovy [file.idl] [core]`): detected by reflection; no model exists,
//   so it parses the given/default IDL fixture and prints the canonical IDL the writer produces.
// Output lines: MODE|..  WARN|..  RESULT|OK|..  RESULT|FAIL|..   (no System.exit)

def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\n", " ").replace("\r", " ") }

def loader = this.class.classLoader
Class appClass = null
try { appClass = loader.loadClass("com.nomagic.magicdraw.core.Application") } catch (Throwable ignored) {}
def project = null
if (appClass != null) {
    try { project = appClass.getMethod("getInstance").invoke(null).getProject() } catch (Throwable ignored) {}
}
boolean inCameo = appClass != null && project != null
def finish = { String text -> if (!inCameo) println(text); return text }

def scriptDir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
Map<String, String> req = [:]
def reqFile = new File(scriptDir, "uml3-idl-export-request.txt")
if (inCameo && reqFile.exists()) {
    reqFile.readLines("UTF-8").findAll { it.contains("=") && !it.startsWith("#") }.each { l ->
        int k = l.indexOf("="); req[l.substring(0, k).trim()] = l.substring(k + 1).trim()
    }
}
if (!inCameo) {
    def argv = binding.hasVariable("args") ? (binding.getVariable("args") as List) : []
    req.idl = argv.size() > 0 ? argv[0] : "tests/idl/shop_order.idl"
    req.core = argv.size() > 1 ? argv[1] : "tools/idl/UML3IdlCore.groovy"
}
out.append("MODE|" + (inCameo ? "catia-magic" : "standalone (no CATIA Magic project detected; writer demo on an IDL fixture)") + "\n")
if (!req.core) return finish(out.append("RESULT|FAIL|request needs core=\n").toString())

def facade
try {
    def gcl = new GroovyClassLoader(loader)
    gcl.parseClass(new File(req.core))
    facade = gcl.loadClass("UML3Idl")
} catch (Throwable t) {
    return finish(out.append("RESULT|FAIL|cannot load core: " + clean(t) + "\n").toString())
}

if (!inCameo) {
    try {
        def f = new File(req.idl)
        out.append(facade.toIdl(facade.parse(f.getText("UTF-8"), f.name)))
        return finish(out.append("RESULT|OK|standalone writer demo\n").toString())
    } catch (Throwable t) {
        return finish(out.append("RESULT|FAIL|" + clean(t.message ?: t) + "\n").toString())
    }
}

if (!req.package || !req.idlOut) return finish(out.append("RESULT|FAIL|request needs package= and idlOut= (" + reqFile + ")\n").toString())
try {
    def rootsClass = loader.loadClass("com.dassault_systemes.modeler.kerml.model.RootNamespaces")
    def roots = rootsClass.methods.find { it.name == "getAllRoots" && it.parameterCount == 1 }.invoke(null, project) ?: []
    def pkg = null
    for (r in roots) {
        def members = []
        try { members = r.respondsTo("getOwnedMember") ? (r.getOwnedMember() ?: []) : [] } catch (Throwable ignored) {}
        pkg = members.find { m -> try { m.respondsTo("getName") && m.getName() == req.package } catch (Throwable x) { false } }
        if (pkg != null) break
    }
    if (pkg == null) return finish(out.append("RESULT|FAIL|package '" + req.package + "' not found among root packages\n").toString())
    def ast = facade.fromModel(pkg)
    ast.warnings.each { w -> out.append("WARN|" + clean(w) + "\n") }
    String idl = facade.toIdl(ast)
    def target = new File(req.idlOut)
    target.parentFile?.mkdirs()
    target.setText(idl, "UTF-8")
    out.append("RESULT|OK|exported " + req.package + " to " + target.path + " (" + idl.readLines().size() + " lines)\n")
} catch (Throwable t) {
    def sw = new StringWriter(); t.printStackTrace(new PrintWriter(sw))
    out.append("RESULT|FAIL|" + clean(t) + "\n")
    out.append("TRACE|" + clean(sw.toString().take(1500)) + "\n")
}
return finish(out.toString())
