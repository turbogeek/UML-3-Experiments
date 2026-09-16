// Runs the UML3 IDL core and code generators over many IDL files in ONE JVM and writes one result line per file.
// Usage: groovy tools/idl/idl_corpus.groovy <file-list.txt> <results.tsv> [timeoutSeconds]
//   file-list: one path per line (as the caller wants it reported)
//   results.tsv columns: file, outcome, detail, roundTrip, sysml, java, rust
//     outcome  ACCEPT | UNSUPPORTED | REJECT | CRASH | TIMEOUT
//     roundTrip STABLE | UNSTABLE | FAIL:<msg> | -     sysml OK | -
//     ACCEPT = parsed AND SysML emitted; an emitter IdlException is UNSUPPORTED ("mapping: ...")
//     java  OK (generated and compiled by the in-process javac) | NOMAP:<IdlException> | NOCOMPILE:<first error> |
//           CRASH:<non-IdlException> | -
//     rust  OK (generated; not compiled here) | NOMAP:<IdlException> | CRASH:<non-IdlException> | -
// Prints SUMMARY|<outcome>=<n>...|java=<ok>|rust=<ok> at the end. No System.exit (project rule).
import java.util.concurrent.*
import javax.tools.*

def here = new File(getClass().protectionDomain.codeSource.location.toURI()).parentFile
def loader = new GroovyClassLoader(getClass().classLoader)
["UML3IdlCore.groovy", "UML3IdlCodegen.groovy"].each { n ->
    def f = new File(here, n); if (!f.exists()) f = new File("tools/idl/" + n)
    loader.parseClass(f)
}
def facade = loader.loadClass("UML3Idl")
def codegen = loader.loadClass("UML3IdlCodegen")
def idlException = loader.loadClass("IdlException")

if (args.length < 2) { println "RESULT|FAIL|usage: idl_corpus.groovy <file-list.txt> <results.tsv> [timeoutSeconds]"; return }
List<String> files = new File(args[0]).readLines("UTF-8").findAll { it.trim() }
if (files.isEmpty()) { println "RESULT|FAIL|empty file list " + args[0]; return }
long timeout = args.length > 2 ? (args[2] as long) : 10L
def clean = { Object s -> String.valueOf(s).replace("\t", " ").replace("\r", " ").replace("\n", " ").take(300) }
def javac = ToolProvider.getSystemJavaCompiler()
if (javac == null) { println "RESULT|FAIL|no system Java compiler (Groovy must run on a JDK)"; return }
File scratch = File.createTempFile("uml3-idl-corpus", "")
scratch.delete(); scratch.mkdirs()

// compiles in-memory sources; returns null when they compile, else the first error
def compileJava = { Map<String, String> sources ->
    if (sources.isEmpty()) return null
    def diags = new DiagnosticCollector<JavaFileObject>()
    def units = sources.collect { rel, src ->
        new SimpleJavaFileObject(URI.create("string:///" + rel), JavaFileObject.Kind.SOURCE) {
            CharSequence getCharContent(boolean ignoreEncodingErrors) { return src }
        }
    }
    File outDir = new File(scratch, "classes")
    outDir.deleteDir(); outDir.mkdirs()
    def fm = javac.getStandardFileManager(diags, null, java.nio.charset.StandardCharsets.UTF_8)
    boolean ok = javac.getTask(null, fm, diags, ["-d", outDir.path, "-Xlint:none", "-proc:none"], null, units).call()
    fm.close()
    if (ok) return null
    def e = diags.diagnostics.find { it.kind == Diagnostic.Kind.ERROR }
    return e == null ? "compilation failed" : (e.source?.name ?: "?") + ":" + e.lineNumber + ": " + e.getMessage(Locale.ROOT)
}

def generator = { Closure gen ->
    try { gen(); return "OK" }
    catch (Throwable t) { return (idlException.isInstance(t) ? "NOMAP:" : "CRASH:" + t.class.simpleName + ": ") + t.message }
}

// daemon threads: a runaway parse must not keep the JVM alive after the run
def newPool = { -> Executors.newSingleThreadExecutor({ Runnable r -> Thread th = new Thread(r); th.daemon = true; th } as ThreadFactory) }
def pool = newPool()
Map<String, Integer> counts = [:].withDefault { 0 }
def out = new File(args[1])
out.parentFile?.mkdirs()
out.withWriter("UTF-8") { w ->
    w.write("file\toutcome\tdetail\troundTrip\tsysml\tjava\trust\n")
    files.each { path ->
        Callable<List<String>> job = {
            def f = new File(path)
            String text = f.getText("UTF-8")
            def ast
            try {
                ast = facade.parse(text, f.name)
            } catch (Throwable t) {
                if (idlException.isInstance(t)) {
                    return [t.message.contains("unsupported") ? "UNSUPPORTED" : "REJECT", t.message, "-", "-", "-", "-"]
                }
                return ["CRASH", t.class.name + ": " + t.message + " @ " + (t.stackTrace.find { it.className.startsWith("Idl") } ?: ""), "-", "-", "-", "-"]
            }
            String sysml = "OK", rt
            try {
                facade.toSysml(ast)
            } catch (Throwable t) {
                // import = parse AND emit: a mapping limitation is an unsupported construct, anything else a crash
                if (idlException.isInstance(t)) return ["UNSUPPORTED", "mapping: " + t.message, "-", "-", "-", "-"]
                return ["CRASH", "emit: " + t.class.name + ": " + t.message, "-", "-", "-", "-"]
            }
            try {
                String c1 = facade.toIdl(ast)
                String c2 = facade.toIdl(facade.parse(c1, f.name))
                rt = c1 == c2 ? "STABLE" : "UNSTABLE"
            } catch (Throwable t) { rt = "FAIL:" + t.class.simpleName + ": " + t.message }
            Map<String, String> javaSources = null
            String java = generator { javaSources = codegen.toJava(ast) }
            if (java == "OK") {
                String err = compileJava(javaSources)
                if (err != null) java = "NOCOMPILE:" + err
            }
            String rust = generator { codegen.toRust(ast) }
            return ["ACCEPT", ast.warnings.size() + " warnings", rt, sysml, java, rust]
        } as Callable<List<String>>
        List<String> r
        Future<List<String>> fut = pool.submit(job)
        try {
            r = fut.get(timeout, TimeUnit.SECONDS)
        } catch (TimeoutException te) {
            fut.cancel(true)
            r = ["TIMEOUT", "> " + timeout + " s", "-", "-", "-", "-"]
            // the stuck thread may keep running; start a fresh worker for the remaining files
            pool.shutdownNow()
            pool = newPool()
        } catch (ExecutionException ee) {
            r = ["CRASH", clean(ee.cause), "-", "-", "-", "-"]
        }
        counts[r[0]]++
        if (r[4] == "OK") counts["java"]++
        if (r[5] == "OK") counts["rust"]++
        w.write(([path] + r.collect { clean(it) }).join("\t") + "\n")
    }
}
pool.shutdownNow()
scratch.deleteDir()
println "SUMMARY|" + ["ACCEPT", "UNSUPPORTED", "REJECT", "CRASH", "TIMEOUT"].collect { it + "=" + counts[it] }.join("|") +
    "|java=" + counts["java"] + "|rust=" + counts["rust"] + "|total=" + files.size()
println "RESULT|OK|" + out.path
