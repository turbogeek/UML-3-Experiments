// READ-ONLY: what text CATIA Magic's diagram labels produce for UML3 keywords.
// Uses the functions behind the shape labels (found by javap on the kerml / kerml.diagram jars):
//   KeywordProvider.getInstance().getKeyword(Element).lowerCaseWrapped()    -> metaclass keyword
//   ModelTextCreator.getSemanticMetadataText(Element, boolean)              -> List<String>
//   ModelTextCreator.createMetadataKeywordsText(Element, Supplier<TextBuilder>, String, boolean, boolean)
//                                                                           (MetadataLabelWrapper)
// Boolean parameter meanings are undocumented, so all combinations are reported.
// Output: ELEM|path|kind|variant|text     Classes are loaded reflectively via the KerML class loader.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def cl = RootNamespaces.getClassLoader()
def load = { String n -> Class.forName(n, true, cl) }
def clean = { Object t -> t == null ? "null" : t.toString().replace("|", "/").replace("\n", "\\n").replace("\r", "") }
def nameOf = { e -> try { e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def membersOf = { e -> try { e.respondsTo("getOwnedMember") ? (e.getOwnedMember() ?: []) : [] } catch (x) { [] } }
def roots = RootNamespaces.getAllRoots(proj) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) {
        def hit = membersOf(r).find { nameOf(it) == path[0] }
        if (hit != null) { cur = hit; break }
    }
    for (int i = 1; i < path.size() && cur != null; i++) {
        def want = path[i]
        cur = membersOf(cur).find { nameOf(it) == want }
    }
    return cur
}

def keywordProvider, textCreator, plainBuilderClass
try {
    keywordProvider = load("com.dassault_systemes.modeler.kerml.text.KeywordProvider").getMethod("getInstance").invoke(null)
    textCreator = load("com.dassault_systemes.modeler.kerml.text.ModelTextCreator").getDeclaredConstructor().newInstance()
    plainBuilderClass = load("com.nomagic.text.builders.PlainTextBuilder")
} catch (Throwable t) {
    return "ERROR|cannot load text API: " + clean(t)
}

def specFile = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-display-subjects.txt")
if (!specFile.exists()) return "ERROR|subjects file missing: " + specFile
specFile.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.unique().each { line ->
    def path = line.trim().split("::") as List
    def e = findPath(path)
    if (e == null) { out.append("ELEM|" + line + "|NOT_FOUND||\n"); return }
    String kind = e.getClass().getSimpleName()
    try { out.append("ELEM|" + line + "|" + kind + "|metaclassKeyword|" + clean(keywordProvider.getKeyword(e).lowerCaseWrapped()) + "\n") }
    catch (Throwable t) { out.append("ELEM|" + line + "|" + kind + "|metaclassKeyword|EXC " + clean(t) + "\n") }
    [true, false].each { b ->
        try { out.append("ELEM|" + line + "|" + kind + "|semanticMetadataText(" + b + ")|" + clean(textCreator.getSemanticMetadataText(e, b)) + "\n") }
        catch (Throwable t) { out.append("ELEM|" + line + "|" + kind + "|semanticMetadataText(" + b + ")|EXC " + clean(t) + "\n") }
    }
    [[true, true], [true, false], [false, true], [false, false]].each { flags ->
        try {
            def supplier = ({ -> plainBuilderClass.getDeclaredConstructor().newInstance() } as java.util.function.Supplier)
            def tb = textCreator.createMetadataKeywordsText(e, supplier, " ", flags[0], flags[1])
            out.append("ELEM|" + line + "|" + kind + "|metadataKeywordsText(" + flags[0] + "," + flags[1] + ")|" + clean(tb) + "\n")
        } catch (Throwable t) {
            out.append("ELEM|" + line + "|" + kind + "|metadataKeywordsText(" + flags[0] + "," + flags[1] + ")|EXC " + clean(t) + "\n")
        }
    }
}
return out.toString()
