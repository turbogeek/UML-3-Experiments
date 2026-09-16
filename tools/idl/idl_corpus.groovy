// Runs the UML3 IDL core over many IDL files in ONE JVM and writes one result line per file.
// Usage: groovy tools/idl/idl_corpus.groovy <file-list.txt> <results.tsv> [timeoutSeconds]
//   file-list: one path per line (as the caller wants it reported)
//   results.tsv columns: file, outcome, detail, roundTrip, sysml
//     outcome  ACCEPT | UNSUPPORTED | REJECT | CRASH | TIMEOUT
//     roundTrip STABLE | UNSTABLE | FAIL:<msg> | -     sysml OK | -
//     ACCEPT = parsed AND SysML emitted; an emitter IdlException is UNSUPPORTED ("mapping: ...")
// Prints SUMMARY|<outcome>=<n>... at the end. No System.exit (project rule).
import java.util.concurrent.*

def coreFile = new File(new File(getClass().protectionDomain.codeSource.location.toURI()).parentFile, "UML3IdlCore.groovy")
if (!coreFile.exists()) coreFile = new File("tools/idl/UML3IdlCore.groovy")
def loader = new GroovyClassLoader(getClass().classLoader)
loader.parseClass(coreFile)
def facade = loader.loadClass("UML3Idl")
def idlException = loader.loadClass("IdlException")

if (args.length < 2) { println "RESULT|FAIL|usage: idl_corpus.groovy <file-list.txt> <results.tsv> [timeoutSeconds]"; return }
List<String> files = new File(args[0]).readLines("UTF-8").findAll { it.trim() }
if (files.isEmpty()) { println "RESULT|FAIL|empty file list " + args[0]; return }
long timeout = args.length > 2 ? (args[2] as long) : 10L
def clean = { Object s -> String.valueOf(s).replace("\t", " ").replace("\r", " ").replace("\n", " ").take(300) }

// daemon threads: a runaway parse must not keep the JVM alive after the run
def pool = Executors.newSingleThreadExecutor({ Runnable r -> Thread th = new Thread(r); th.daemon = true; th } as ThreadFactory)
Map<String, Integer> counts = [:].withDefault { 0 }
def out = new File(args[1])
out.parentFile?.mkdirs()
out.withWriter("UTF-8") { w ->
    w.write("file\toutcome\tdetail\troundTrip\tsysml\n")
    files.each { path ->
        Callable<List<String>> job = {
            def f = new File(path)
            String text = f.getText("UTF-8")
            def ast
            try {
                ast = facade.parse(text, f.name)
            } catch (Throwable t) {
                if (idlException.isInstance(t)) {
                    return [t.message.contains("unsupported") ? "UNSUPPORTED" : "REJECT", t.message, "-", "-"]
                }
                return ["CRASH", t.class.name + ": " + t.message + " @ " + (t.stackTrace.find { it.className.startsWith("Idl") } ?: ""), "-", "-"]
            }
            String sysml = "OK", rt
            try {
                facade.toSysml(ast)
            } catch (Throwable t) {
                // import = parse AND emit: a mapping limitation is an unsupported construct, anything else a crash
                if (idlException.isInstance(t)) return ["UNSUPPORTED", "mapping: " + t.message, "-", "-"]
                return ["CRASH", "emit: " + t.class.name + ": " + t.message, "-", "-"]
            }
            try {
                String c1 = facade.toIdl(ast)
                String c2 = facade.toIdl(facade.parse(c1, f.name))
                rt = c1 == c2 ? "STABLE" : "UNSTABLE"
            } catch (Throwable t) { rt = "FAIL:" + t.class.simpleName + ": " + t.message }
            return ["ACCEPT", ast.warnings.size() + " warnings", rt, sysml]
        } as Callable<List<String>>
        List<String> r
        Future<List<String>> fut = pool.submit(job)
        try {
            r = fut.get(timeout, TimeUnit.SECONDS)
        } catch (TimeoutException te) {
            fut.cancel(true)
            r = ["TIMEOUT", "> " + timeout + " s", "-", "-"]
            // the stuck thread may keep running; start a fresh worker for the remaining files
            pool.shutdownNow()
            pool = Executors.newSingleThreadExecutor({ Runnable rr -> Thread th = new Thread(rr); th.daemon = true; th } as ThreadFactory)
        } catch (ExecutionException ee) {
            r = ["CRASH", clean(ee.cause), "-", "-"]
        }
        counts[r[0]]++
        w.write([path, r[0], clean(r[1]), clean(r[2]), clean(r[3])].join("\t") + "\n")
    }
}
pool.shutdownNow()
println "SUMMARY|" + ["ACCEPT", "UNSUPPORTED", "REJECT", "CRASH", "TIMEOUT"].collect { it + "=" + counts[it] }.join("|") + "|total=" + files.size()
println "RESULT|OK|" + out.path
