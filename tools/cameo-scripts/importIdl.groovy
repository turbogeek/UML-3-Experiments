// UML3 IDL import: OMG IDL file -> SysML v2 (UML3IDL mapping) -> loaded into the open CATIA Magic project.
//
// Inside CATIA Magic (run via the SysMLv2 test harness /run-script, or from the Macro/Groovy console):
//   reads uml3-idl-request.txt next to this script (harness scripts dir):
//     idl=<path to .idl>   core=<path to tools/idl/UML3IdlCore.groovy>   sysmlOut=<path for generated .sysml>
//   converts with the UML3 IDL core, builds the SysML v2 text against the project's root namespaces and
//   copies the result into the project in ONE session named "UML3 IDL Import" (undoable; cancelled on error).
// Outside CATIA Magic (plain `groovy importIdl.groovy [file.idl] [core]`): detected by reflection; converts the
//   given or default test fixture and prints the SysML - no model is touched.
// Output lines: MODE|..  DIAG|severity|line|message  RESULT|OK|..  RESULT|FAIL|..   (no System.exit)

final String SESSION_NAME = "UML3 IDL Import"
def out = new StringBuilder()
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\n", " ").replace("\r", " ") }

// ---- environment detection (no static imports of CATIA Magic classes, so this also compiles standalone)
def loader = this.class.classLoader
Class appClass = null
try { appClass = loader.loadClass("com.nomagic.magicdraw.core.Application") } catch (Throwable ignored) {}
def project = null
if (appClass != null) {
    try { project = appClass.getMethod("getInstance").invoke(null).getProject() } catch (Throwable ignored) {}
}
boolean inCameo = appClass != null && project != null
// harness uses the returned text; the command line needs it printed
def finish = { String text -> if (!inCameo) println(text); return text }

// ---- request
def scriptDir = new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts")
Map<String, String> req = [:]
def reqFile = new File(scriptDir, "uml3-idl-request.txt")
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
out.append("MODE|" + (inCameo ? "catia-magic" : "standalone (no CATIA Magic project detected; model is not touched)") + "\n")
if (!req.idl || !req.core) return finish(out.append("RESULT|FAIL|request needs idl= and core= (" + reqFile + ")\n").toString())

// ---- convert with the pure core
String sysml
try {
    def gcl = new GroovyClassLoader(loader)
    gcl.parseClass(new File(req.core))
    def facade = gcl.loadClass("UML3Idl")
    def idlFile = new File(req.idl)
    def ast = facade.parse(idlFile.getText("UTF-8"), idlFile.name)
    ast.warnings.each { w -> out.append("DIAG|WARNING|0|" + clean(w) + "\n") }
    sysml = facade.toSysml(ast)
    if (req.sysmlOut) { new File(req.sysmlOut).parentFile?.mkdirs(); new File(req.sysmlOut).setText(sysml, "UTF-8") }
} catch (Throwable t) {
    return finish(out.append("RESULT|FAIL|conversion: " + clean(t.message ?: t.toString()) + "\n").toString())
}
if (!inCameo) {
    out.append(sysml)
    return finish(out.append("RESULT|OK|standalone conversion only\n").toString())
}

// ---- build and persist inside CATIA Magic (same API path as the SysMLv2 test harness /load-sysml)
def cls = { String n -> loader.loadClass(n) }
def staticCall = { Class c, String name, Object... a ->
    def m = c.methods.find { it.name == name && it.parameterCount == a.length }
    if (m == null) throw new IllegalStateException("no static " + c.simpleName + "." + name + "/" + a.length)
    return m.invoke(null, a)
}
def sessionManager = staticCall(cls("com.nomagic.magicdraw.openapi.uml.SessionManager"), "getInstance")
boolean committed = false
try {
    def namespaceClass = cls("com.dassault_systemes.modeler.kerml.model.kerml.Namespace")
    def roots = (staticCall(cls("com.dassault_systemes.modeler.kerml.model.RootNamespaces"), "getAllRoots", project) ?: [])
        .findAll { namespaceClass.isInstance(it) }
    sessionManager.createSession(project, SESSION_NAME)
    def builderClass = cls("com.dassault_systemes.modeler.sysml.textual.project.SysMLTransientModelBuilder")
    def builder = builderClass.constructors.find { it.parameterCount == 1 }.newInstance(project)
    def result = builder.build(sysml, roots)
    def diags = result.getDiagnostics() ?: []
    diags.each { d -> out.append("DIAG|" + clean(d.getSeverity()) + "|" + clean(d.getLine()) + "|" + clean(d.getMessage()) + "\n") }
    def errors = diags.findAll { String.valueOf(it.getSeverity()) == "ERROR" }
    def transientNs = result.getTransientRootNs()
    if (!errors.isEmpty() || transientNs == null) {
        out.append("RESULT|FAIL|" + errors.size() + " build errors" + (transientNs == null ? ", no root namespace" : "") + "\n")
    } else {
        def persistent = staticCall(cls("com.dassault_systemes.modeler.sysml.textual.project.SysMLTextualProjectModelBasedHelper"),
            "copyTransientModelToPersistent", project, transientNs)
        def feature = staticCall(cls("com.dassault_systemes.modeler.kerml.esi.feature.KerMLProjectFeature"), "getPrimaryProjectFeature", project)
        feature.addCommonData(persistent)
        sessionManager.closeSession(project)
        committed = true
        out.append("RESULT|OK|imported " + new File(req.idl).name + " (" + sysml.readLines().size() + " SysML lines)\n")
    }
} catch (Throwable t) {
    out.append("RESULT|FAIL|" + clean(t.toString()) + "\n")
} finally {
    if (!committed && sessionManager.isSessionCreated(project)) sessionManager.cancelSession(project)
}
return finish(out.toString())
