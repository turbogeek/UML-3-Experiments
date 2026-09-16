// Checks the name transformations against tests/idl/codegen/naming-examples.txt (OMG IDL4-Java 7.1.1.1 examples).
// Usage: groovy tools/idl/codegen_selftest.groovy [examples.txt]
// Output: CASE|PASS|...  CASE|FAIL|...  RESULT|OK|n  or RESULT|FAIL|n failed   (no System.exit)
def here = new File(getClass().protectionDomain.codeSource.location.toURI()).parentFile
def loader = new GroovyClassLoader(getClass().classLoader)
["UML3IdlCore.groovy", "UML3IdlCodegen.groovy"].each { n ->
    def f = new File(here, n); if (!f.exists()) f = new File("tools/idl/" + n)
    loader.parseClass(f)
}
def naming = loader.loadClass("IdlNaming")
def file = new File(args.length > 0 ? args[0] : "tests/idl/codegen/naming-examples.txt")
int failed = 0, total = 0
file.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.each { l ->
    def p = (l + " ").split(/\|/, -1)*.trim()
    String form = p[0], input = p[1], spec = p[2], deviation = p.size() > 3 ? p[3] : ""
    String expected = deviation ?: spec
    String got = naming."$form"(input)
    total++
    boolean pass = got == expected
    if (!pass) failed++
    println "CASE|" + (pass ? "PASS" : "FAIL") + "|" + form + "(" + input + ") = " + got + " expected " + expected + (deviation ? " (spec example: " + spec + ")" : "")
}
println(failed == 0 && total > 0 ? "RESULT|OK|" + total : "RESULT|FAIL|" + failed + " of " + total + " failed")
