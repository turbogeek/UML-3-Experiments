// Command-line IDL -> Java / Rust generator (outside CATIA Magic).
// Usage: groovy tools/idl/idl2code.groovy <input.idl> <outDir> [java] [rust] [compile]
//   java     writes <outDir>/java/<package dirs>/*.java  (OMG IDL4 to Java 1.0)
//   rust     writes <outDir>/rust/lib.rs
//   compile  compiles the generated Java in-process (javax.tools) into <outDir>/classes;
//            compiles lib.rs with rustc when rustc is on PATH (otherwise RUSTC|SKIPPED)
// Result lines: RESULT|OK|..  RESULT|FAIL|..  JAVA|OK|<n files>  JAVAC|OK / JAVAC|FAIL|<diagnostic>  RUST|OK
//               RUSTC|OK / RUSTC|FAIL|<diagnostic> / RUSTC|SKIPPED   WARN|..   (no System.exit)
import javax.tools.*

def here = new File(getClass().protectionDomain.codeSource.location.toURI()).parentFile
def loader = new GroovyClassLoader(getClass().classLoader)
["UML3IdlCore.groovy", "UML3IdlCodegen.groovy"].each { n ->
    def f = new File(here, n); if (!f.exists()) f = new File("tools/idl/" + n)
    loader.parseClass(f)
}
def core = loader.loadClass("UML3Idl")
def gen = loader.loadClass("UML3IdlCodegen")
def idlException = loader.loadClass("IdlException")

if (args.length < 2) { println "RESULT|FAIL|usage: idl2code.groovy <input.idl> <outDir> [java] [rust] [compile]"; return }
def input = new File(args[0])
def outDir = new File(args[1])
Set<String> opts = (args.length > 2 ? args[2..-1] : ["java", "rust"]) as Set
def clean = { Object s -> String.valueOf(s).replace("\r", " ").replace("\n", " ").take(400) }
boolean ok = true
try {
    def ast = core.parse(input.getText("UTF-8"), input.name)
    ast.warnings.each { println "WARN|" + clean(it) }
    if ("java" in opts) {
        Map<String, String> files = gen.toJava(ast)
        def javaDir = new File(outDir, "java")
        javaDir.deleteDir()
        files.each { rel, src -> def f = new File(javaDir, rel); f.parentFile.mkdirs(); f.setText(src, "UTF-8") }
        println "JAVA|OK|" + files.size()
        if ("compile" in opts) {
            def compiler = ToolProvider.getSystemJavaCompiler()
            if (compiler == null) { println "JAVAC|SKIPPED|no system Java compiler (running on a JRE?)" }
            else if (files.isEmpty()) { println "JAVAC|OK|nothing to compile" }
            else {
                def classes = new File(outDir, "classes"); classes.deleteDir(); classes.mkdirs()
                def diags = new DiagnosticCollector<JavaFileObject>()
                def fm = compiler.getStandardFileManager(diags, null, java.nio.charset.StandardCharsets.UTF_8)
                def units = fm.getJavaFileObjectsFromFiles(files.keySet().collect { new File(javaDir, it) })
                boolean compiled = compiler.getTask(null, fm, diags, ["-d", classes.path, "-Xlint:none", "-proc:none"], null, units).call()
                fm.close()
                def errors = diags.diagnostics.findAll { it.kind == Diagnostic.Kind.ERROR }
                if (compiled) println "JAVAC|OK"
                else {
                    ok = false
                    errors.take(5).each { d -> println "JAVAC|FAIL|" + clean(new File(String.valueOf(d.source?.name)).name + ":" + d.lineNumber + ": " + d.getMessage(Locale.ROOT)) }
                }
            }
        }
    }
    if ("rust" in opts) {
        String rs = gen.toRust(ast)
        def rustFile = new File(outDir, "rust/lib.rs")
        rustFile.parentFile.mkdirs()
        rustFile.setText(rs, "UTF-8")
        println "RUST|OK|" + rustFile.path
        if ("compile" in opts) {
            String rustc = System.getenv("PATH").split(File.pathSeparator).collect { new File(it, System.getProperty("os.name").toLowerCase().contains("win") ? "rustc.exe" : "rustc") }.find { it.exists() }?.path
            if (rustc == null) println "RUSTC|SKIPPED|rustc not on PATH"
            else {
                def p = [rustc, "--crate-type", "lib", "--edition", "2021", "--emit", "metadata", "-o", new File(outDir, "rust/lib.rmeta").path, rustFile.path].execute()
                def err = new StringBuilder(); p.consumeProcessErrorStream(err); p.waitFor()
                if (p.exitValue() == 0) println "RUSTC|OK"
                else { ok = false; err.readLines().findAll { it.startsWith("error") }.take(5).each { println "RUSTC|FAIL|" + clean(it) } }
            }
        }
    }
    println(ok ? "RESULT|OK|" + outDir.path : "RESULT|FAIL|generated code does not compile")
} catch (Throwable t) {
    String msg = idlException.isInstance(t) ? t.message : (t.class.simpleName + ": " + t.message + " @ " + (t.stackTrace.find { it.fileName?.startsWith("UML3Idl") } ?: ""))
    println "RESULT|FAIL|" + clean(msg)
}
