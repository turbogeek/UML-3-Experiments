// READ-ONLY API discovery for the IDL exporter: dumps zero-argument getters (names, classes, simple values)
// of selected elements of the imported IDL package, plus their owned metadata usages and feature values.
// Paths are read from uml3-api-probe-subjects.txt (one A::B::C per line). Output is bounded text.
import com.nomagic.magicdraw.core.Application
import com.dassault_systemes.modeler.kerml.model.RootNamespaces

def proj = Application.getInstance().getProject()
if (proj == null) return "ERROR|NO_PROJECT"
def out = new StringBuilder()
def nameOf = { e -> try { e != null && e.respondsTo("getName") ? e.getName() : null } catch (x) { null } }
def membersOf = { e -> try { e.respondsTo("getOwnedMember") ? (e.getOwnedMember() ?: []) : [] } catch (x) { [] } }
def roots = RootNamespaces.getAllRoots(proj) ?: []
def findPath = { List path ->
    def cur = null
    for (r in roots) { def hit = membersOf(r).find { nameOf(it) == path[0] }; if (hit != null) { cur = hit; break } }
    for (int i = 1; i < path.size() && cur != null; i++) { def want = path[i]; cur = membersOf(cur).find { nameOf(it) == want } }
    return cur
}
def brief
brief = { Object v ->
    if (v == null) return "null"
    if (v instanceof Collection) return "[" + v.take(6).collect { brief(it) }.join(", ") + (v.size() > 6 ? ", ..." + v.size() : "") + "]"
    if (v instanceof String || v instanceof Number || v instanceof Boolean || v instanceof Enum) return String.valueOf(v)
    String n = nameOf(v)
    return v.getClass().getSimpleName() + (n != null ? "(" + n + ")" : "")
}
def INTERESTING = ~/^(get|is)(Name|DeclaredName|ShortName|QualifiedName|Type|Definition|Direction|Multiplicity|LowerBound|UpperBound|Ordered|Unique|Constant|Abstract|Variable|Valuation|Value|IsDefault|Default|OwnedFeature|OwnedMember|OwnedRelationship|OwnedElement|OwnedSpecialization|OwnedSubclassification|OwnedRedefinition|OwnedTyping|OwnedFeatureMembership|Feature|MetadataDefinition|Metaclass|Client|Supplier|OwnedAnnotation|Annotation|RedefinedFeature|Superclassifier|General|Referent|Result|Operand|LibraryElement|Owner|OwningNamespace|Documentation|EnumeratedValue|Parameter|Input|Output|OwnedEndFeature)$/
// small leaf objects (literals, multiplicities, values, relationships): dump every simple zero-arg getter
def LEAF = ~/.*(Literal|Multiplicity|FeatureValue|Dependency|Subclassification|Redefinition|FeatureReferenceExpression|OperatorExpression|Membership).*Impl/
def NOISY = ~/^(getClass|hashCode|toString|eAll.*|eContents|eCrossReferences|eClass|eResource|eAdapters|eDeliver|getObjectParent|getHumanName.*|getLocalID|getID|getProject|getAppliedStereotype.*|getSyncElement|get_.*)$/
def dump = { Object e, String indent ->
    if (e == null) { out.append(indent + "null\n"); return }
    boolean leaf = e.getClass().getSimpleName() ==~ LEAF
    e.getClass().getMethods()
        .findAll { it.parameterCount == 0 && (it.getName().startsWith("get") || it.getName().startsWith("is")) &&
                   !(it.getName() ==~ NOISY) && (leaf || it.getName() ==~ INTERESTING) }
        .sort { it.getName() }
        .each { m ->
            try { out.append(indent + m.getName() + " = " + brief(m.invoke(e)) + "\n") }
            catch (Throwable t) { out.append(indent + m.getName() + " threw " + t.getClass().getSimpleName() + "\n") }
        }
}

def subjects = new File(new File(System.getProperty("user.home"), "Documents/GitHub/sysmlv2-validator/utilityScripts"), "uml3-api-probe-subjects.txt")
if (!subjects.exists()) return "ERROR|missing " + subjects
subjects.readLines("UTF-8").findAll { it.trim() && !it.startsWith("#") }.each { line ->
    def e = findPath(line.trim().split("::") as List)
    out.append("===== " + line + " : " + (e == null ? "NOT FOUND" : e.getClass().getSimpleName()) + "\n")
    if (e == null) return
    dump(e, "  ")
    // leaf-level details: multiplicity, bound/default values, relationships owned by this element
    def owned = []
    try { owned = e.getOwnedElement() ?: [] } catch (x) {}
    owned.findAll { it.getClass().getSimpleName() ==~ LEAF }.each { leafEl ->
        out.append("  -- leaf " + leafEl.getClass().getSimpleName() + "\n")
        dump(leafEl, "     ")
        try { (leafEl.getOwnedElement() ?: []).each { sub -> out.append("     -- sub " + sub.getClass().getSimpleName() + "\n"); dump(sub, "        ") } } catch (x) {}
    }
    try {
        (e.getOwnedRelationship() ?: []).findAll { it.getClass().getSimpleName() ==~ /.*(FeatureValue|Dependency|Subclassification).*/ }.each { rel ->
            out.append("  -- relationship " + rel.getClass().getSimpleName() + "\n")
            dump(rel, "     ")
        }
    } catch (x) {}
    // metadata usages owned by the element, with their redefining features and values
    owned.findAll { it.getClass().getSimpleName().contains("MetadataUsage") }.each { mu ->
        out.append("  -- metadata usage " + brief(mu) + "\n")
        dump(mu, "     ")
        def feats = []
        try { feats = mu.getOwnedFeature() ?: [] } catch (x) {}
        feats.each { f ->
            out.append("     -- feature " + brief(f) + "\n")
            dump(f, "        ")
            try {
                def fv = f.getValuation()
                if (fv != null) { out.append("        -- valuation.value\n"); dump(fv.getValue(), "           ") }
            } catch (x) {}
        }
    }
}
return out.toString()
