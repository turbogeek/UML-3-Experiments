// READ-ONLY follow-up: does the Collection<Feature> overload used by MetadataLabelWrapper render
// PLAIN (non-semantic) metadata such as #primaryKey, which the Element overload omitted?
//   ModelTextCreator.createMetadataKeywordsText(Collection<Feature>, TextBuilder) -> String
// Metadata usages are found among the element's owned members / owned features by class name.
// Output: META|path|metadataUsageClasses|text
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def cl = RootNamespaces.getClassLoader()
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

def textCreator = Class.forName("com.dassault_systemes.modeler.kerml.text.ModelTextCreator", true, cl).getDeclaredConstructor().newInstance()
def plainBuilderClass = Class.forName("com.nomagic.text.builders.PlainTextBuilder", true, cl)

[["OnlineStoreDatabase", "Logical", "PurchaseOrder", "orderId"],
 ["OnlineStoreDatabase", "Logical", "CustomerAccount", "email"],
 ["OnlineStoreArchitecture", "OrderService"]].each { path ->
    def e = findPath(path)
    String p = path.join("::")
    if (e == null) { out.append("META|" + p + "|NOT_FOUND|\n"); return }
    def pool = []
    try { pool.addAll(membersOf(e)) } catch (x) {}
    try { if (e.respondsTo("getOwnedFeature")) pool.addAll(e.getOwnedFeature() ?: []) } catch (x) {}
    try { if (e.respondsTo("getOwnedElement")) pool.addAll(e.getOwnedElement() ?: []) } catch (x) {}
    // NB: Groovy unique()/sort() call compareTo, which KerML elements reject (UnsupportedOperationException).
    def distinct = java.util.Collections.newSetFromMap(new java.util.IdentityHashMap())
    distinct.addAll(pool.findAll { it != null })
    def metas = new ArrayList(distinct.findAll { it.getClass().getSimpleName().contains("MetadataUsage") })
    try {
        String text = textCreator.createMetadataKeywordsText(metas, plainBuilderClass.getDeclaredConstructor().newInstance())
        out.append("META|" + p + "|" + metas.collect { it.getClass().getSimpleName() }.join(",") + "|" + clean(text) + "\n")
    } catch (Throwable t) {
        out.append("META|" + p + "|" + metas.size() + " found|EXC " + clean(t) + "\n")
    }
}
return out.toString()
