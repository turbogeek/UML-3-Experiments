// Command-line IDL -> SysML v2 importer (outside CATIA Magic).
// Usage: groovy tools/idl/idl2sysml.groovy <input.idl> <output.sysml> [<canonical-output.idl>]
// Prints machine-readable result lines for the test harness:
//   RESULT|OK|<output>            or   RESULT|FAIL|<message>
//   WARN|<message>                    ROUNDTRIP|STABLE or ROUNDTRIP|UNSTABLE
// Does not call System.exit (project rule); callers read the RESULT line.

def coreFile = new File(new File(getClass().protectionDomain.codeSource.location.toURI()).parentFile, "UML3IdlCore.groovy")
if (!coreFile.exists()) coreFile = new File("tools/idl/UML3IdlCore.groovy")
def loader = new GroovyClassLoader(getClass().classLoader)
loader.parseClass(coreFile)
def facade = loader.loadClass("UML3Idl")
def idlException = loader.loadClass("IdlException")

if (args.length < 2) {
    println "RESULT|FAIL|usage: idl2sysml.groovy <input.idl> <output.sysml> [<canonical-output.idl>]"
    return
}
def input = new File(args[0])
def output = new File(args[1])
try {
    def ast = facade.parse(input.getText("UTF-8"), input.name)
    ast.warnings.each { println "WARN|" + it }
    String sysml = facade.toSysml(ast)
    output.parentFile?.mkdirs()
    output.setText(sysml, "UTF-8")

    // canonical IDL round trip inside the core: write -> parse -> write must be stable
    String canonical1 = facade.toIdl(ast)
    String canonical2 = facade.toIdl(facade.parse(canonical1, input.name))
    println(canonical1 == canonical2 ? "ROUNDTRIP|STABLE" : "ROUNDTRIP|UNSTABLE")
    if (args.length > 2) {
        def canon = new File(args[2])
        canon.parentFile?.mkdirs()
        canon.setText(canonical1, "UTF-8")
    }
    println "RESULT|OK|" + output.path
} catch (Throwable t) {
    String msg = idlException.isInstance(t) ? t.message : (t.class.simpleName + ": " + t.message)
    println "RESULT|FAIL|" + msg.replace("\n", " ")
}
