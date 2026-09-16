/*
 * Headless SysML v2 checker built on the OMG Pilot Implementation (SysMLInteractive).
 * Unlike the ANTLR-only sysml-validator, this performs full Xtext linking, so unresolved
 * types, imports and specializations are reported as errors.
 *
 * Usage: groovy -cp <classpath> SysMLCheck.groovy <libraryDir> <report.json> <file-or-dir>...
 * Files load in the given order (directories sorted by path) into one shared resource set,
 * so later files may reference earlier ones. Result: sets exit code via a thrown status
 * only when run standalone; writes a JSON report for diagnostics.
 */
import groovy.json.JsonOutput
import java.nio.file.*

if (args.length < 3) {
    System.err.println 'Usage: SysMLCheck.groovy <libraryDir> <report.json> <file-or-dir>...'
    return 2
}

List<Path> files = []
args[2..-1].each { a ->
    Path p = Paths.get(a)
    if (Files.isDirectory(p)) {
        Files.walk(p).withCloseable { s -> s.filter { it.toString().endsWith('.sysml') }.sorted().forEach { files << it } }
    } else {
        files << p
    }
}

def interactiveClass = Class.forName('org.omg.sysml.interactive.SysMLInteractive')
def sysml = interactiveClass.getInstance()
sysml.loadLibrary(args[0])

def report = [library: args[0], started: new Date().toString(), files: []]
int totalErrors = 0, totalWarnings = 0
files.each { Path f ->
    def r = sysml.process(f.getText('UTF-8'), true)
    def errs = [], warns = []
    if (r.exception != null) errs << "EXCEPTION: ${r.exception}".toString()
    r.issues.each { is ->
        String msg = "line ${is.lineNumber}:${is.column} ${is.message}"
        switch (String.valueOf(is.severity)) {
            case 'ERROR': errs << msg; break
            case 'WARNING': warns << msg; break
        }
    }
    totalErrors += errs.size(); totalWarnings += warns.size()
    String status = errs ? 'FAIL' : 'PASS'
    println "${status}  ${f}  (${errs.size()} errors, ${warns.size()} warnings)"
    errs.each { println "    ERROR   $it" }
    warns.each { println "    WARNING $it" }
    report.files << [file: f.toString(), status: status, errors: errs, warnings: warns]
}
report.totalErrors = totalErrors
report.totalWarnings = totalWarnings
Paths.get(args[1]).toFile().text = JsonOutput.prettyPrint(JsonOutput.toJson(report))
println "SUMMARY files=${files.size()} errors=${totalErrors} warnings=${totalWarnings}"
System.exit(totalErrors == 0 ? 0 : 1) // standalone CLI JVM only; never run inside MagicDraw
