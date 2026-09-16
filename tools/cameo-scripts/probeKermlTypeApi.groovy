// READ-ONLY diagnostic: discover the Dassault KerML API for specialization on a loaded element.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def sb = new StringBuilder()
def proj = Application.getInstance().getProject()
if (proj == null) return "NO_PROJECT"
def nameOf = { e -> try { e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def membersOf = { e -> try { e.respondsTo("getOwnedMember") ? (e.getOwnedMember() ?: []) : [] } catch (x) { [] } }

def findPath = { List<String> path ->
    def cur = null
    for (r in (RootNamespaces.getAllRoots(proj) ?: [])) {
        def hit = membersOf(r).find { nameOf(it) == path[0] }
        if (hit != null) { cur = hit; break }
    }
    for (int i = 1; i < path.size() && cur != null; i++) {
        String want = path[i]
        cur = membersOf(cur).find { nameOf(it) == want }
    }
    return cur
}

def e = findPath(["OnlineStoreArchitecture", "OrderService"])
if (e == null) return "NOT FOUND OnlineStoreArchitecture::OrderService"
sb.append("class=" + e.getClass().getName() + "\n")
def names = e.getClass().getMethods().collect { it.getName() + "/" + it.getParameterCount() }.unique().sort()
names.findAll { it =~ /(?i)(special|super|general|subclass|subset|allTypes|conform|owned(Feature|Member)\/|^getFeature\/|inheritedFeature|getType\/)/ }
     .each { sb.append("  method " + it + "\n") }
// Try the most likely candidates and print what they return (names only)
["getOwnedSpecialization", "getOwnedSubclassification", "allSupertypes", "getAllSupertypes", "supertypes"].each { m ->
    if (e.respondsTo(m)) {
        try {
            def v = e."$m"()
            def items = (v instanceof Collection) ? v : [v]
            sb.append("CALL " + m + " -> " + items.size() + " : " + items.collect { x ->
                def g = null
                try { g = x.respondsTo("getGeneral") ? x.getGeneral() : (x.respondsTo("getSuperclassifier") ? x.getSuperclassifier() : x) } catch (y) { g = x }
                String n = nameOf(g); n != null ? n : g.getClass().getSimpleName()
            }.join(", ") + "\n")
        } catch (Throwable t) { sb.append("CALL " + m + " threw " + t + "\n") }
    }
}
return sb.toString()
