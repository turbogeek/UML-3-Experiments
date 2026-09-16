// Local pre-flight check for Groovy scripts that will run inside MagicDraw via the harness.
// 1) parses to CONVERSION phase (syntax; Cameo classes are not on the local classpath, so
//    imports are not resolved here)
// 2) rejects imports known to be missing from MagicDraw's embedded GroovyShell classpath
// 3) rejects System.exit (would kill MagicDraw)
// Usage: groovy tools/check_groovy.groovy <file.groovy>...   Exit code 0 = ok, 1 = problems.
import org.codehaus.groovy.control.CompilationUnit
import org.codehaus.groovy.control.Phases

// Verified 2026-09-16: "unable to resolve class groovy.json.JsonSlurper" inside the harness.
def UNAVAILABLE_IMPORTS = ["groovy.json."]

int problems = 0
args.each { path ->
    int before = problems
    def f = new File(path)
    try {
        def cu = new CompilationUnit()
        cu.addSource(f)
        cu.compile(Phases.CONVERSION)
    } catch (Exception e) {
        println "SYNTAX   " + f.name + ": " + e.message
        problems++
    }
    f.readLines("UTF-8").eachWithIndex { line, i ->
        def t = line.trim()
        if (t.startsWith("import ") && UNAVAILABLE_IMPORTS.any { t.contains(it) }) {
            println "IMPORT   " + f.name + ":" + (i + 1) + " not available in MagicDraw GroovyShell: " + t
            problems++
        }
        if (!t.startsWith("//") && t.contains("System.exit")) {
            println "FORBID   " + f.name + ":" + (i + 1) + " System.exit would terminate MagicDraw"
            problems++
        }
    }
    if (problems == before) println "OK       " + f.name
}
System.exit(problems == 0 ? 0 : 1) // local CLI JVM only, never inside MagicDraw
