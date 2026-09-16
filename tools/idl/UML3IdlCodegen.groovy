// UML3 IDL code generators: IDL AST (UML3IdlCore.groovy) -> Java and Rust source.
// Pure Groovy, no CATIA Magic classes; load AFTER UML3IdlCore.groovy into the same GroovyClassLoader.
// Because the input is the IDL AST, the same generators serve IDL files and SysML models (UML3Idl.fromModel).
//   Java: OMG IDL4 to Java Language Mapping 1.0 (ptc/2019-07-02), default @java_mapping options
//         (apply_naming_convention TRUE, promote_integer_width FALSE, constants_container "Constants").
//   Rust: no OMG mapping exists; conventions follow the ic-idl Rust backend (docs/IDL-CODEGEN.md).
// Errors are IdlException (line numbers from the AST). No System.exit.

// ---------------------------------------------------------------- shared model queries

class IdlCodegenContext {
    IdlFile file
    IdlNames names
    Map<String, Object> constants = [:]
    Map<IdlDefinition, List<String>> scopeOf = [:]   // definition -> enclosing module path

    IdlCodegenContext(IdlFile f) {
        file = f
        names = new IdlNames(f)
        index(f.defs, [])
    }

    private void index(List<IdlDefinition> defs, List<String> scope) {
        defs.each { d ->
            scopeOf[d] = scope
            if (d instanceof IdlConst) { constants[d.name] = ((IdlConst) d).value; constants[(scope + [d.name]).join("::")] = ((IdlConst) d).value }
            if (d instanceof IdlModule) index(((IdlModule) d).defs, scope + [d.name])
        }
    }

    // IDL modules may be reopened; generated packages / Rust modules must be emitted once
    static List<IdlDefinition> mergeModules(List<IdlDefinition> defs) {
        List<IdlDefinition> out = []
        Map<String, IdlModule> seen = [:]
        defs.each { d ->
            if (d instanceof IdlModule) {
                IdlModule first = seen[d.name]
                if (first == null) {
                    first = new IdlModule(kind: "module", name: d.name, line: d.line, annotations: d.annotations)
                    seen[d.name] = first
                    out << first
                }
                first.defs.addAll(((IdlModule) d).defs)
            } else out << d
        }
        return out
    }

    IdlDefinition lookup(String name, List<String> scope) {
        return names.byQualified[names.resolve(name, scope)]
    }

    IdlDefinition require(IdlTypeRef t, List<String> scope) {
        IdlDefinition d = lookup(t.name, scope)
        if (d == null) throw new IdlException("unresolved type '" + t.name + "' (declared in another file? includes are not resolved)", t.line)
        return d
    }

    // follows typedef chains; returns [type, extra array dims (outermost first), definition scope]
    List resolveAlias(IdlTypeRef t, List<String> scope) {
        List<Long> dims = []
        IdlTypeRef cur = t
        List<String> curScope = scope
        int guard = 0
        while (cur.kind == "scoped") {
            IdlDefinition d = require(cur, curScope)
            if (!(d instanceof IdlTypedef)) break
            IdlTypedef td = (IdlTypedef) d
            dims.addAll(td.decl.dims)
            curScope = scopeOf[td]
            cur = td.type
            if (++guard > 100) throw new IdlException("typedef cycle at '" + t.name + "'", t.line)
        }
        return [cur, dims, curScope]
    }

    // union discriminator / label support: the resolved discriminator kind and label values
    static final Set<String> INTEGER = ["short", "long", "long long", "unsigned short", "unsigned long", "unsigned long long",
        "int8", "uint8", "int16", "uint16", "int32", "uint32", "int64", "uint64", "octet"] as Set

    Object labelValue(String label, IdlTypeRef disc, List<String> discScope, List<String> scope, int line) {
        String s = label.trim()
        if (s ==~ /-?\d+/) return Long.parseLong(s)
        if (s ==~ /(?i)0x[0-9a-f]+/) return Long.parseLong(s.substring(2), 16)
        if (s == "TRUE") return Boolean.TRUE
        if (s == "FALSE") return Boolean.FALSE
        if (s ==~ /'.*'/) return s
        if (disc.kind == "scoped") {
            IdlDefinition e = require(disc, discScope)
            if (e instanceof IdlEnum) {
                String lit = s.contains("::") ? s.substring(s.lastIndexOf("::") + 2) : s
                if (((IdlEnum) e).literals.contains(lit)) return lit
            }
        }
        Object v = constants[names.resolve(s, scope)] ?: constants[s]
        if (v instanceof IdlScopedValue) {
            String lit = ((IdlScopedValue) v).name
            return lit.contains("::") ? lit.substring(lit.lastIndexOf("::") + 2) : lit
        }
        if (v != null) return v
        throw new IdlException("cannot resolve union case label '" + label + "'", line)
    }
}

// ---------------------------------------------------------------- naming (OMG IDL4-Java 7.1.1.1, reused for Rust)

class IdlNaming {
    // words: split on '_' and on case transitions; an uppercase run followed by lowercase starts a new word at its
    // last capital (so EValue -> E, Value and ALLUppercase -> ALL, Uppercase), as in the spec's snake-case examples
    static List<String> words(String n) {
        List<String> out = []
        n.split("_").findAll { it }.each { part ->
            StringBuilder w = new StringBuilder()
            for (int i = 0; i < part.length(); i++) {
                char c = part.charAt(i)
                if (w.length() > 0) {
                    char prev = part.charAt(i - 1)
                    boolean nextLower = i + 1 < part.length() && Character.isLowerCase(part.charAt(i + 1))
                    if ((Character.isLowerCase(prev) && Character.isUpperCase(c)) ||
                        (Character.isUpperCase(prev) && Character.isUpperCase(c) && nextLower)) {
                        out << w.toString(); w.setLength(0)
                    }
                }
                w.append(c)
            }
            if (w.length() > 0) out << w.toString()
        }
        return out
    }

    // 7.1.1.1.1: capitalize the first letter of every '_'-separated part, keep the rest
    static String pascal(String n) {
        String r = n.split("_").findAll { it }.collect { it.substring(0, 1).toUpperCase() + it.substring(1) }.join("")
        return r ?: n
    }

    // 7.1.1.1.2
    static String camel(String n) {
        String p = pascal(n)
        return p.substring(0, 1).toLowerCase() + p.substring(1)
    }

    // 7.1.1.1.3
    static String upperSnake(String n) {
        if (!n.any { Character.isLowerCase(it as char) }) return n
        return words(n).collect { it.toUpperCase() }.join("_")
    }

    static String snake(String n) {
        return words(n).collect { it.toLowerCase() }.join("_")
    }

    // names mapped from different IDL names must stay distinct (IDL4-Java footnote 2); applies to Rust as well
    static void checkDistinct(Map<String, String> mappedToIdl, String mapped, String idl, String what, int line) {
        String prior = mappedToIdl[mapped]
        if (prior != null && prior == idl) throw new IdlException("duplicate " + what + " '" + idl + "'", line)
        if (prior != null && prior != idl) {
            throw new IdlException(what + " '" + idl + "' and '" + prior + "' map to the same name '" + mapped + "'", line)
        }
        mappedToIdl[mapped] = idl
    }
}

// ---------------------------------------------------------------- Java (OMG IDL4 to Java 1.0)

class IdlToJava {
    static final Set<String> RESERVED = ("abstract assert boolean break byte case catch char class const continue default do " +
        "double else enum extends final finally float for goto if implements import instanceof int interface long native new " +
        "package private protected public return short static strictfp super switch synchronized this throw throws transient " +
        "try void volatile while true false null var record yield sealed permits").split(" ") as Set
    // 7.1.2: names reserved where the mapping collides with java.lang.Object (and, for exceptions, Throwable) methods
    static final Set<String> OBJECT_METHODS = ["getClass", "hashCode", "equals", "toString", "clone", "notify", "notifyAll", "wait", "finalize"] as Set
    static final Set<String> THROWABLE_GETTERS = ["getMessage", "getLocalizedMessage", "getCause", "getStackTrace", "getSuppressed"] as Set

    IdlCodegenContext ctx
    Map<String, String> files = new LinkedHashMap<>()
    boolean needHolder, needAny

    Map<String, String> generate(IdlFile f) {
        ctx = new IdlCodegenContext(f)
        definitions(f.defs, [])
        if (needHolder) files["org/omg/type/Holder.java"] = "package org.omg.type;\n\n// OMG IDL4-Java 7.1.3\npublic class Holder<E> {\n    public E value;\n    public Holder() { }\n    public Holder(E value) { this.value = value; }\n}\n"
        if (needAny) files["org/omg/type/Any.java"] = "package org.omg.type;\n\n// OMG IDL4-Java 7.3: middleware-specific; this placeholder only makes generated code compile\npublic interface Any extends java.io.Serializable { }\n"
        return files
    }

    static String esc(String n) { return RESERVED.contains(n) ? "_" + n : n }
    static String typeName(String idl) { return esc(IdlNaming.pascal(idl)) }
    static String pkg(List<String> scope) { return scope.collect { esc(it) }.join(".") }

    String header(List<String> scope) {
        return (scope ? "package " + pkg(scope) + ";\n\n" : "") + "// Generated by the UML3 IDL generator (OMG IDL4 to Java 1.0 mapping). Do not edit.\n\n"
    }

    void emit(List<String> scope, String simpleName, String body) {
        currentScope = scope
        String path = (scope ? scope.collect { esc(it) }.join("/") + "/" : "") + simpleName + ".java"
        if (files.containsKey(path)) throw new IdlException("two IDL definitions map to the Java class " + path, 0)
        files[path] = header(scope) + body
    }

    // ---- types

    List<String> currentScope = []

    String qualified(IdlDefinition d) {
        List<String> scope = ctx.scopeOf[d]
        if (scope.isEmpty() && !currentScope.isEmpty()) {
            throw new IdlException("'" + d.name + "' is declared outside any module (Java unnamed package, IDL4-Java 7.2.2) and cannot be referenced from package " + pkg(currentScope), d.line)
        }
        return (scope ? pkg(scope) + "." : "") + typeName(d.name)
    }

    static final Map<String, String> PRIMITIVE = [
        "boolean": "boolean", "char": "char", "wchar": "char", "octet": "byte", "int8": "byte", "uint8": "byte",
        "short": "short", "int16": "short", "unsigned short": "short", "uint16": "short",
        "long": "int", "int32": "int", "unsigned long": "int", "uint32": "int",
        "long long": "long", "int64": "long", "unsigned long long": "long", "uint64": "long",
        "float": "float", "double": "double"]
    static final Map<String, String> BOXED = ["boolean": "Boolean", "char": "Character", "byte": "Byte", "short": "Short",
        "int": "Integer", "long": "Long", "float": "Float", "double": "Double"]

    // Java type of an IDL type use (typedefs replaced, 7.2.4.6); dims = declarator array dimensions
    String javaType(IdlTypeRef t, List<Long> dims, List<String> scope, boolean boxed) {
        List r = ctx.resolveAlias(t, scope)
        IdlTypeRef base = (IdlTypeRef) r[0]
        List<Long> all = new ArrayList<Long>(dims ?: []) + (List<Long>) r[1]
        String j = elementType(base, (List<String>) r[2], boxed && all.isEmpty())
        return j + ("[]" * all.size())
    }

    String elementType(IdlTypeRef t, List<String> scope, boolean boxed) {
        switch (t.kind) {
            case "basic":
                if (t.name == "long double") return "java.math.BigDecimal"
                if (t.name == "any") { needAny = true; return "org.omg.type.Any" }
                String p = PRIMITIVE[t.name]
                if (p == null) throw new IdlException("no Java mapping for basic type '" + t.name + "'", t.line)
                return boxed ? BOXED[p] : p
            case "string": case "wstring": return "String"
            case "fixed": return "java.math.BigDecimal"
            case "sequence":
                // 7.2.4.2.1: sequences map to java.util.List<E>; the spec's BooleanSeq/IntegerSeq... interfaces declare
                // constructors (not legal Java interfaces), so List<boxed type> is used for basic elements as well
                return "java.util.List<" + javaType(t.element, [], scope, true) + ">"
            case "scoped":
                IdlDefinition d = ctx.require(t, scope)
                if (d instanceof IdlInterface) return qualified(d)
                return qualified(d)
        }
        throw new IdlException("no Java mapping for type kind '" + t.kind + "'", t.line)
    }

    boolean isPrimitive(String javaType) { return BOXED.containsKey(javaType) }

    // default constructor initialisation (7.2.4.3.1); null = leave Java default
    String defaultValue(IdlMember m, List<String> scope, String jt) {
        IdlAnnotation dflt = m.annotation("default")
        if (dflt != null && m.decl.dims.isEmpty()) return literal(dflt.argText(), m.type, scope, m.line)
        if (m.annotation("optional") != null) return null
        List r = ctx.resolveAlias(m.type, scope)
        IdlTypeRef base = (IdlTypeRef) r[0]
        List<Long> dims = new ArrayList<Long>(m.decl.dims) + (List<Long>) r[1]
        if (!dims.isEmpty()) {
            String elem = jt.substring(0, jt.length() - 2 * dims.size())
            String sizes = dims.collect { "[" + it + "]" }.join("")
            return elem.contains("<") ? "(" + jt + ") new " + elem.substring(0, elem.indexOf("<")) + sizes : "new " + elem + sizes
        }
        switch (base.kind) {
            case "string": case "wstring": return '""'
            case "sequence": return "new java.util.ArrayList<>()"
            case "fixed": return "java.math.BigDecimal.ZERO"
            case "basic": return base.name == "long double" ? "java.math.BigDecimal.ZERO" : null
            case "scoped":
                IdlDefinition d = ctx.require(base, (List<String>) r[2])
                if (d instanceof IdlEnum) return qualified(d) + "." + esc(((IdlEnum) d).literals[0])
                if (d instanceof IdlInterface) return null
                return "new " + qualified(d) + "()"
        }
        return null
    }

    // element initialisation for arrays of objects ("elements initialized with their default constructor")
    List<String> fillArray(IdlMember m, List<String> scope, String field, String jt) {
        if (!jt.endsWith("[]")) return []
        String elem = jt.replaceAll(/(\[\])+$/, "")
        String init
        if (elem == "String") init = '""'
        else if (elem == "java.math.BigDecimal") init = "java.math.BigDecimal.ZERO"
        else if (isPrimitive(elem) || elem == "org.omg.type.Any") return []
        else {
            List r = ctx.resolveAlias(m.type, scope)
            IdlTypeRef base = (IdlTypeRef) r[0]
            if (base.kind == "sequence") init = "new java.util.ArrayList<>()"
            else if (base.kind == "scoped") {
                IdlDefinition d = ctx.require(base, (List<String>) r[2])
                if (d instanceof IdlInterface) return []
                init = d instanceof IdlEnum ? elem + "." + esc(((IdlEnum) d).literals[0]) : "new " + elem + "()"
            } else return []
        }
        int depth = (jt.length() - elem.length()) / 2
        List<String> lines = []
        String target = field
        String indent = "        "
        for (int i = 0; i < depth; i++) {
            lines << indent + ("    " * i) + "for (int i" + i + " = 0; i" + i + " < " + target + ".length; i" + i + "++) {"
            target = target + "[i" + i + "]"
        }
        lines << indent + ("    " * depth) + target + " = " + init + ";"
        for (int i = depth - 1; i >= 0; i--) lines << indent + ("    " * i) + "}"
        return lines
    }

    String literal(String idlValue, IdlTypeRef t, List<String> scope, int line) {
        String v = idlValue.trim()
        List r = ctx.resolveAlias(t, scope)
        IdlTypeRef base = (IdlTypeRef) r[0]
        if (v == "TRUE" || v == "FALSE") return v.toLowerCase()
        if (base.kind == "scoped") {
            IdlDefinition d = ctx.require(base, (List<String>) r[2])
            if (d instanceof IdlEnum) return qualified(d) + "." + esc(v.contains("::") ? v.substring(v.lastIndexOf("::") + 2) : v)
        }
        if (base.kind == "string" || base.kind == "wstring") return v.startsWith('"') ? v : '"' + v + '"'
        if (base.kind == "fixed" || base.name == "long double") return 'new java.math.BigDecimal("' + v + '")'
        String jt = elementType(base, (List<String>) r[2], false)
        if (jt == "char") return v
        if (jt == "long") return v + "L"
        if (jt == "float") return v + "F"
        if (jt == "byte" || jt == "short") return "(" + jt + ") " + v
        return v
    }

    String constValue(IdlConst c, List<String> scope) {
        Object v = c.value
        List r = ctx.resolveAlias(c.type, scope)
        IdlTypeRef base = (IdlTypeRef) r[0]
        if (v instanceof Boolean) return v.toString()
        if (v instanceof IdlScopedValue) {
            IdlDefinition e = base.kind == "scoped" ? ctx.require(base, (List<String>) r[2]) : null
            String lit = ((IdlScopedValue) v).name
            lit = lit.contains("::") ? lit.substring(lit.lastIndexOf("::") + 2) : lit
            if (e instanceof IdlEnum) return qualified(e) + "." + esc(lit)
            throw new IdlException("constant '" + c.name + "' refers to '" + ((IdlScopedValue) v).name + "', which is not a value", c.line)
        }
        if (base.kind == "string" || base.kind == "wstring") return '"' + javaEscape(String.valueOf(v)) + '"'
        if (base.kind == "fixed" || base.name == "long double") return 'new java.math.BigDecimal("' + v + '")'
        String jt = elementType(base, (List<String>) r[2], false)
        if (jt == "char") return v instanceof Number ? "(char) " + v : "'" + javaEscape(String.valueOf(v)) + "'"
        if (jt == "boolean") return String.valueOf(v).toLowerCase()
        if (jt == "long") return v + "L"
        if (jt == "float") return (v instanceof Double ? v : ((Number) v).doubleValue()) + "F"
        if (jt == "double") return String.valueOf(v instanceof Double ? v : ((Number) v).doubleValue())
        long n = ((Number) v).longValue()
        if (jt == "int") return n >= Integer.MIN_VALUE && n <= Integer.MAX_VALUE ? String.valueOf(n) : "(int) " + n + "L"   // unsigned wrap, 8.1.2
        return "(" + jt + ") " + n
    }

    static String javaEscape(String s) {
        // IDL escapes (\n, \", \\, \x41, A) are kept by the lexer; Java accepts the same forms except \x
        return s.replaceAll(/\\x([0-9a-fA-F]{1,2})/) { all, hex -> String.format("\\u%04x", Integer.parseInt((String) hex, 16)) }
    }

    // ---- definitions

    void definitions(List<IdlDefinition> rawDefs, List<String> scope) {
        List<IdlDefinition> defs = IdlCodegenContext.mergeModules(rawDefs)
        List<IdlConst> consts = defs.findAll { it instanceof IdlConst } as List<IdlConst>
        currentScope = scope
        if (consts) constants(consts, scope)
        Map<String, String> typeNames = [:]
        defs.each { d ->
            currentScope = scope
            if (!(d instanceof IdlModule) && !(d instanceof IdlConst) && !(d instanceof IdlTypedef)) {
                IdlNaming.checkDistinct(typeNames, typeName(d.name), d.name, "type", d.line)
            }
            if (d instanceof IdlModule) definitions(((IdlModule) d).defs, scope + [d.name])
            else if (d instanceof IdlStruct) structLike(d, ((IdlStruct) d).members, ((IdlStruct) d).base, scope, false)
            else if (d instanceof IdlExceptionDef) structLike(d, ((IdlExceptionDef) d).members, null, scope, true)
            else if (d instanceof IdlEnum) enumeration((IdlEnum) d, scope)
            else if (d instanceof IdlUnion) union((IdlUnion) d, scope)
            else if (d instanceof IdlInterface) iface((IdlInterface) d, scope)
            // typedef: no Java type (7.2.4.6)
        }
    }

    // 7.2.3: one Constants class per package
    void constants(List<IdlConst> consts, List<String> scope) {
        StringBuilder b = new StringBuilder("public final class Constants {\n    private Constants() { }\n")
        Map<String, String> seen = [:]
        consts.each { c ->
            String n = esc(IdlNaming.upperSnake(c.name))
            IdlNaming.checkDistinct(seen, n, c.name, "constant", c.line)
            b.append("    public static final ").append(javaType(c.type, [], scope, false)).append(" ").append(n)
             .append(" = ").append(constValue(c, scope)).append(";\n")
        }
        b.append("}\n")
        emit(scope, "Constants", b.toString())
    }

    static class JField { IdlMember m; String type; String field; String prop; String param; boolean optional }

    List<JField> fields(List<IdlMember> members, List<String> scope, boolean isException, int line) {
        Map<String, String> props = [:]
        return members.collect { m ->
            JField f = new JField(m: m, optional: m.annotation("optional") != null)
            f.type = javaType(m.type, m.decl.dims, scope, f.optional)
            String prop = IdlNaming.pascal(m.decl.name)
            if (OBJECT_METHODS.contains("get" + prop) || (isException && THROWABLE_GETTERS.contains("get" + prop))) prop = "_" + prop
            IdlNaming.checkDistinct(props, prop, m.decl.name, "member", m.line)
            f.prop = prop
            f.param = esc(IdlNaming.camel(m.decl.name))
            f.field = f.param
            return f
        }
    }

    List<JField> inheritedFields(String base, List<String> scope, int line) {
        if (!base) return []
        IdlDefinition b = ctx.lookup(base, scope)
        if (!(b instanceof IdlStruct)) throw new IdlException("struct base '" + base + "' is not a struct in this file", line)
        IdlStruct bs = (IdlStruct) b
        return inheritedFields(bs.base, ctx.scopeOf[bs], bs.line) + fields(bs.members, ctx.scopeOf[bs], false, bs.line)
    }

    String rangeCheck(JField f, List<String> scope) {
        IdlAnnotation range = f.m.annotation("range")
        List<String> conds = []
        Map<String, String> kv = [:]
        if (range != null) kv.putAll(IdlToSysml.keyValues(range))
        ["min", "max"].each { k -> IdlAnnotation a = f.m.annotation(k); if (a != null) kv[k] = a.argText() }
        if (kv.isEmpty() || !isPrimitive(f.type) || f.type in ["boolean", "char"]) return ""
        if (kv.min != null) conds << f.param + " < " + boundLiteral(kv.min, scope, f.m.line)
        if (kv.max != null) conds << f.param + " > " + boundLiteral(kv.max, scope, f.m.line)
        return "        if (" + conds.join(" || ") + ") throw new IllegalArgumentException(\"" + f.m.decl.name + " out of range\");\n"
    }

    String boundLiteral(String s, List<String> scope, int line) {
        String v = s.trim()
        if (v ==~ /-?[\d.eE+]+/) return v
        Object c = ctx.constants[ctx.names.resolve(v, scope)] ?: ctx.constants[v]
        if (c instanceof Number) return String.valueOf(c)
        throw new IdlException("range bound '" + s + "' is not a numeric constant", line)
    }

    void structLike(IdlDefinition d, List<IdlMember> members, String base, List<String> scope, boolean isException) {
        String cls = typeName(d.name)
        List<JField> own = fields(members, scope, isException, d.line)
        List<JField> inherited = inheritedFields(base, scope, d.line)
        StringBuilder b = new StringBuilder()
        String baseClass = base ? qualified(ctx.lookup(base, scope)) : null
        b.append("public class ").append(cls)
        if (isException) b.append(" extends java.lang.RuntimeException")
        else if (baseClass) b.append(" extends ").append(baseClass)
        b.append(" implements java.io.Serializable {\n")
        b.append("    private static final long serialVersionUID = 1L;\n\n")
        own.each { f -> b.append("    private ").append(f.type).append(" ").append(f.field).append(";\n") }
        // default constructor
        b.append("\n    public ").append(cls).append("() {\n")
        own.each { f ->
            String dv = defaultValue(f.m, scope, f.type)
            if (dv != null) b.append("        this.").append(f.field).append(" = ").append(dv).append(";\n")
            fillArray(f.m, scope, "this." + f.field, f.type).each { b.append(it).append("\n") }
        }
        b.append("    }\n")
        // all-values constructor (7.2.4.3.1; with a base struct its first parameter is the base instance, 7.14.1)
        if (!own.isEmpty() || baseClass) {
            List<String> params = []
            if (baseClass) params << baseClass + " parent"
            own.each { f -> params << f.type + " " + f.param }
            b.append("\n    public ").append(cls).append("(").append(params.join(", ")).append(") {\n")
            if (baseClass) {
                IdlStruct bs = (IdlStruct) ctx.lookup(base, scope)
                List<String> superArgs = []
                if (bs.base) superArgs << "parent"
                fields(bs.members, ctx.scopeOf[bs], false, bs.line).each { pf -> superArgs << "parent.get" + pf.prop + "()" }
                b.append("        super(").append(superArgs.join(", ")).append(");\n")
            }
            own.each { f -> b.append("        this.").append(f.field).append(" = ").append(f.param).append(";\n") }
            b.append("    }\n")
        }
        // accessors / modifiers
        own.each { f ->
            b.append("\n    public ").append(f.type).append(" get").append(f.prop).append("() {\n        return ").append(f.field).append(";\n    }\n")
            b.append("\n    public void set").append(f.prop).append("(").append(f.type).append(" ").append(f.param).append(") {\n")
            b.append(rangeCheck(f, scope))
            b.append("        this.").append(f.field).append(" = ").append(f.param).append(";\n    }\n")
        }
        b.append("}\n")
        emit(scope, cls, b.toString())
    }

    // 7.2.4.3.3
    void enumeration(IdlEnum e, List<String> scope) {
        String cls = typeName(e.name)
        StringBuilder b = new StringBuilder("public enum ").append(cls).append(" {\n")
        long next = 0
        List<String> lits = []
        e.literals.each { l ->
            long v = e.values.containsKey(l) ? e.values[l] : next
            next = v + 1
            lits << "    " + esc(l) + "(" + v + ")"
        }
        b.append(lits.join(",\n")).append(";\n\n")
        b.append("    private final int value;\n\n")
        b.append("    private ").append(cls).append("(int value) {\n        this.value = value;\n    }\n\n")
        b.append("    public int getValue() {\n        return value;\n    }\n\n")
        b.append("    public static ").append(cls).append(" valueOf(int v) {\n")
        b.append("        for (").append(cls).append(" e : values()) {\n            if (e.value == v) return e;\n        }\n")
        b.append("        throw new IllegalArgumentException(\"no ").append(cls).append(" with value \" + v);\n    }\n}\n")
        emit(scope, cls, b.toString())
    }

    // 7.2.4.3.2
    void union(IdlUnion u, List<String> scope) {
        String cls = typeName(u.name)
        List r = ctx.resolveAlias(u.discriminator, scope)
        IdlTypeRef discBase = (IdlTypeRef) r[0]
        List<String> discScope = (List<String>) r[2]
        String dt = elementType(discBase, discScope, false)
        IdlEnum discEnum = discBase.kind == "scoped" ? (IdlEnum) ctx.require(discBase, discScope) : null

        // label values per case; candidate default values in "0 index" order
        List<List<Object>> caseValues = u.cases.collect { uc -> uc.labels.collect { ctx.labelValue(it, discBase, discScope, scope, uc.member.line) } }
        Set<Object> used = caseValues.flatten() as Set
        def discLiteral = { Object v ->
            if (discEnum != null) return qualified(discEnum) + "." + esc((String) v)
            if (v instanceof Boolean) return v.toString()
            if (v instanceof String) return (String) v                  // 'c'
            if (dt == "long") return v + "L"
            if (dt == "int") return String.valueOf(v)
            return "(" + dt + ") " + v
        }
        def candidates = { ->
            if (discEnum != null) return discEnum.literals
            if (dt == "boolean") return [Boolean.FALSE, Boolean.TRUE]
            if (dt == "char") return (0..255).collect { "'\\u" + String.format("%04x", it) + "'" }
            return (0L..1024L).collect { it }
        }
        def firstFree = { -> candidates().find { !used.contains(it) } }
        def discEquals = { Object v ->
            String lit = discLiteral(v)
            return "discriminator == " + lit
        }
        boolean hasDefault = u.cases.any { it.isDefault }
        boolean covered = discEnum != null ? discEnum.literals.every { used.contains(it) } : (dt == "boolean" ? used.containsAll([true, false]) : false)
        Object initial = candidates()[0]

        StringBuilder b = new StringBuilder("public final class ").append(cls).append(" implements java.io.Serializable {\n")
        b.append("    private static final long serialVersionUID = 1L;\n\n")
        Map<String, String> props = [:]
        String discField = "discriminator"
        b.append("    private ").append(dt).append(" ").append(discField).append(";\n")
        b.append("    private java.lang.Object value;\n\n")
        // default constructor: discriminator default; if it selects a branch, that member gets its default value
        b.append("    public ").append(cls).append("() {\n        this.discriminator = ").append(discLiteral(initial)).append(";\n")
        int selected = caseValues.findIndexOf { it.contains(initial) }
        if (selected < 0 && hasDefault) selected = u.cases.findIndexOf { it.isDefault }
        if (selected >= 0) {
            IdlMember m = u.cases[selected].member
            String jt = javaType(m.type, m.decl.dims, scope, false)
            String dv = defaultValue(m, scope, jt)
            if (dv == null && isPrimitive(jt)) dv = jt == "boolean" ? "false" : (jt == "char" ? "'\\u0000'" : "(" + jt + ") 0")
            if (dv != null) b.append("        this.value = ").append(dv).append(";\n")
        }
        b.append("    }\n\n")
        b.append("    public ").append(dt).append(" getDiscriminator() {\n        return discriminator;\n    }\n")

        u.cases.eachWithIndex { uc, i ->
            IdlMember m = uc.member
            String jt = javaType(m.type, m.decl.dims, scope, false)
            String prop = IdlNaming.pascal(m.decl.name)
            if (OBJECT_METHODS.contains("get" + prop) || prop == "Discriminator") prop = "_" + prop
            IdlNaming.checkDistinct(props, prop, m.decl.name, "union member", m.line)
            String param = esc(IdlNaming.camel(m.decl.name))
            if (param == "discriminator") param = "_discriminator"
            String boxed = BOXED[jt] ?: jt
            // a member is selected by its own labels, and (default branch) by every value no other case uses
            List<String> own = caseValues[i].collect { discEquals(it) }
            List<String> otherUsed = (used - (caseValues[i] as Set)).collect { discEquals(it) }
            String selectedCond = uc.isDefault ?
                ((own ? own.join(" || ") + " || " : "") + (otherUsed ? "!(" + otherUsed.join(" || ") + ")" : "true")) :
                own.join(" || ")
            b.append("\n    public ").append(jt).append(" get").append(prop).append("() {\n")
            b.append("        if (!(").append(selectedCond).append(")) throw new IllegalStateException(\"member ").append(m.decl.name).append(" is not set\");\n")
            b.append("        return (").append(boxed).append(") value;\n    }\n")
            Object first = uc.isDefault && caseValues[i].isEmpty() ? firstFree() : caseValues[i][0]
            if (first == null) throw new IdlException("no free discriminator value for the default branch of union '" + u.name + "'", m.line)
            b.append("\n    public void set").append(prop).append("(").append(jt).append(" ").append(param).append(") {\n")
            b.append("        this.discriminator = ").append(discLiteral(first)).append(";\n")
            b.append("        this.value = ").append(param).append(";\n    }\n")
            if (caseValues[i].size() > 1 || uc.isDefault) {
                b.append("\n    public void set").append(prop).append("(").append(jt).append(" ").append(param).append(", ").append(dt).append(" discriminator) {\n")
                b.append("        if (!(").append(selectedCond).append(")) throw new IllegalArgumentException(\"discriminator not valid for ").append(m.decl.name).append("\");\n")
                b.append("        this.discriminator = discriminator;\n        this.value = ").append(param).append(";\n    }\n")
            }
        }
        if (!hasDefault && !covered) {
            Object free = firstFree()
            if (free != null) {
                b.append("\n    public void __default() {\n        this.discriminator = ").append(discLiteral(free)).append(";\n        this.value = null;\n    }\n")
                b.append("\n    public void __default(").append(dt).append(" discriminator) {\n")
                if (!used.isEmpty()) b.append("        if (").append(used.collect { discEquals(it) }.join(" || ")).append(") throw new IllegalArgumentException(\"discriminator selects a member\");\n")
                b.append("        this.discriminator = discriminator;\n        this.value = null;\n    }\n")
            }
        }
        b.append("}\n")
        emit(scope, cls, b.toString())
    }

    // 7.4
    void iface(IdlInterface itf, List<String> scope) {
        String cls = typeName(itf.name)
        StringBuilder b = new StringBuilder("public interface ").append(cls)
        if (itf.bases) {
            b.append(" extends ").append(itf.bases.collect { bn ->
                IdlDefinition d = ctx.lookup(bn, scope)
                if (!(d instanceof IdlInterface)) throw new IdlException("interface base '" + bn + "' is not an interface in this file", itf.line)
                qualified(d)
            }.join(", "))
        }
        b.append(" {\n")
        Map<String, String> methods = [:]
        itf.exports.each { e ->
            if (e instanceof IdlAttribute) {
                IdlAttribute a = (IdlAttribute) e
                String jt = javaType(a.type, [], scope, false)
                String prop = IdlNaming.pascal(a.name)
                if (OBJECT_METHODS.contains("get" + prop)) prop = "_" + prop
                IdlNaming.checkDistinct(methods, "get" + prop, a.name, "attribute", a.line)
                b.append("    ").append(jt).append(" get").append(prop).append("();\n")
                if (!a.readonly) b.append("    void set").append(prop).append("(").append(jt).append(" ").append(esc(IdlNaming.camel(a.name))).append(");\n")
            } else {
                IdlOperation op = (IdlOperation) e
                String mn = esc(IdlNaming.camel(op.name))
                if (OBJECT_METHODS.contains(mn)) mn = "_" + mn
                IdlNaming.checkDistinct(methods, mn, op.name, "operation", op.line)
                Map<String, String> paramNames = [:]
                List<String> params = op.params.collect { p ->
                    IdlNaming.checkDistinct(paramNames, esc(IdlNaming.camel(p.name)), p.name, "parameter", op.line)
                    String pt = p.direction == "in" ? javaType(p.type, [], scope, false) : holder(javaType(p.type, [], scope, true))
                    pt + " " + esc(IdlNaming.camel(p.name))
                }
                String ret = op.returnType == null ? "void" : javaType(op.returnType, [], scope, false)
                String throwsClause = op.raises ? " throws " + op.raises.collect { rn ->
                    IdlDefinition x = ctx.lookup(rn, scope)
                    if (!(x instanceof IdlExceptionDef)) throw new IdlException("raises '" + rn + "' is not an exception in this file", op.line)
                    qualified(x)
                }.join(", ") : ""
                b.append("    ").append(ret).append(" ").append(mn).append("(").append(params.join(", ")).append(")").append(throwsClause).append(";\n")
            }
        }
        b.append("}\n")
        emit(scope, cls, b.toString())
    }

    String holder(String boxedType) {
        needHolder = true
        return "org.omg.type.Holder<" + boxedType + ">"
    }
}

// ---------------------------------------------------------------- Rust (ic-idl style conventions)

class IdlToRust {
    // strict and reserved keywords usable as raw identifiers; self/Self/super/crate cannot be raw -> trailing '_'
    static final Set<String> KEYWORDS = ("as async await break const continue dyn else enum extern false fn for if impl in let loop " +
        "match mod move mut pub ref return static struct trait true type unsafe use where while abstract become box do final " +
        "macro override priv try typeof unsized virtual yield gen").split(" ") as Set
    static final Set<String> NOT_RAW = ["self", "Self", "super", "crate", "_"] as Set
    static final Map<String, String> BASIC = [
        "boolean": "bool", "char": "char", "wchar": "char", "octet": "u8", "int8": "i8", "uint8": "u8",
        "short": "i16", "int16": "i16", "unsigned short": "u16", "uint16": "u16",
        "long": "i32", "int32": "i32", "unsigned long": "u32", "uint32": "u32",
        "long long": "i64", "int64": "i64", "unsigned long long": "u64", "uint64": "u64",
        "float": "f32", "double": "f64", "long double": "f64"]

    IdlCodegenContext ctx
    StringBuilder out = new StringBuilder()
    List<String> warnings = []

    static String id(String n) {
        if (NOT_RAW.contains(n)) return n + "_"
        return KEYWORDS.contains(n) ? "r#" + n : n
    }
    static String typeName(String n) { return id(IdlNaming.pascal(n)) }
    static String fieldName(String n) { return id(IdlNaming.snake(n)) }
    static String modName(String n) { return id(IdlNaming.snake(n)) }
    static String constName(String n) { return id(IdlNaming.upperSnake(n)) }

    String generate(IdlFile f) {
        ctx = new IdlCodegenContext(f)
        out.append("// Generated by the UML3 IDL generator (Rust mapping, docs/IDL-CODEGEN.md). Do not edit.\n")
        out.append("#![allow(dead_code, non_camel_case_types, non_snake_case, non_upper_case_globals, clippy::all)]\n\n")
        definitions(f.defs, [], 0)
        return out.toString()
    }

    void line(int ind, String text) { out.append("    " * ind).append(text).append("\n") }

    String path(IdlDefinition d) {
        List<String> scope = ctx.scopeOf[d]
        return "crate::" + (scope ? scope.collect { modName(it) }.join("::") + "::" : "") +
            (d instanceof IdlConst ? constName(d.name) : typeName(d.name))
    }

    String rustType(IdlTypeRef t, List<Long> dims, List<String> scope) {
        String base = elementType(t, scope)
        List<Long> ds = dims ?: []
        for (int i = ds.size() - 1; i >= 0; i--) base = "[" + base + "; " + ds[i] + "]"
        return base
    }

    String elementType(IdlTypeRef t, List<String> scope) {
        switch (t.kind) {
            case "basic":
                if (t.name == "any") throw new IdlException("'any' has no Rust mapping (v1)", t.line)
                String r = BASIC[t.name]
                if (r == null) throw new IdlException("no Rust mapping for basic type '" + t.name + "'", t.line)
                return r
            case "string": case "wstring": return "String"
            case "fixed": return "i128"
            case "sequence": return "Vec<" + rustType(t.element, [], scope) + ">"
            case "scoped":
                IdlDefinition d = ctx.require(t, scope)
                if (d instanceof IdlInterface) throw new IdlException("interface '" + t.name + "' used as a data type (object reference) has no Rust data mapping (v1)", t.line)
                return path(d)
        }
        throw new IdlException("no Rust mapping for type kind '" + t.kind + "'", t.line)
    }

    List<String> docs(IdlMember m, IdlTypeRef t) {
        List<String> d = []
        if (t.kind in ["string", "wstring"] && t.bound != null) d << "/// IDL bound: " + t.kind + "<" + t.bound + ">"
        if (t.kind == "sequence" && t.bound != null) d << "/// IDL bound: at most " + t.bound + " elements"
        if (t.kind == "fixed") d << "/// IDL fixed<" + t.digits + ", " + t.scale + ">: value scaled by 10^" + t.scale
        if (t.kind == "basic" && t.name == "long double") d << "/// IDL long double mapped to f64 (precision may be lost)"
        m?.annotations?.each { a -> if (a.name != "optional") d << "/// " + a.text() }
        return d
    }

    void definitions(List<IdlDefinition> rawDefs, List<String> scope, int ind) {
        List<IdlDefinition> defs = IdlCodegenContext.mergeModules(rawDefs)
        Map<String, String> typeNames = [:], valueNames = [:]
        defs.each { d ->
            if (d instanceof IdlModule) {
                IdlNaming.checkDistinct(valueNames, "mod " + modName(d.name), d.name, "module", d.line)
                line(ind, "pub mod " + modName(d.name) + " {")
                definitions(((IdlModule) d).defs, scope + [d.name], ind + 1)
                line(ind, "}")
                return
            }
            if (d instanceof IdlConst) {
                IdlNaming.checkDistinct(valueNames, constName(d.name), d.name, "constant", d.line)
                constant((IdlConst) d, scope, ind)
                return
            }
            IdlNaming.checkDistinct(typeNames, typeName(d.name), d.name, "type", d.line)
            d.annotations.each { a -> line(ind, "/// " + a.text()) }
            if (d instanceof IdlTypedef) {
                IdlTypedef td = (IdlTypedef) d
                docs(null, td.type).each { line(ind, it) }
                line(ind, "pub type " + typeName(td.name) + " = " + rustType(td.type, td.decl.dims, scope) + ";")
            } else if (d instanceof IdlStruct) {
                struct(d, allMembers((IdlStruct) d, scope), scope, ind, ((IdlStruct) d).base)
            } else if (d instanceof IdlExceptionDef) {
                struct(d, ((IdlExceptionDef) d).members.collect { [it, scope] }, scope, ind, null)
                String n = typeName(d.name)
                line(ind, "impl ::std::fmt::Display for " + n + " {")
                line(ind + 1, "fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result { write!(f, \"" + d.name + "\") }")
                line(ind, "}")
                line(ind, "impl ::std::error::Error for " + n + " {}")
            } else if (d instanceof IdlEnum) {
                enumeration((IdlEnum) d, ind)
            } else if (d instanceof IdlUnion) {
                union((IdlUnion) d, scope, ind)
            } else if (d instanceof IdlInterface) {
                trait((IdlInterface) d, scope, ind)
            }
            out.append("\n")
        }
    }

    // struct inheritance: Rust has no inheritance, base members come first (flattened)
    List<List> allMembers(IdlStruct s, List<String> scope) {
        List<List> r = []
        if (s.base) {
            IdlDefinition b = ctx.lookup(s.base, scope)
            if (!(b instanceof IdlStruct)) throw new IdlException("struct base '" + s.base + "' is not a struct in this file", s.line)
            r.addAll(allMembers((IdlStruct) b, ctx.scopeOf[b]))
        }
        s.members.each { r << [it, scope] }
        return r
    }

    void struct(IdlDefinition d, List<List> members, List<String> scope, int ind, String base) {
        if (base) line(ind, "/// IDL: struct " + d.name + " : " + base + " (base members flattened)")
        line(ind, "#[derive(Debug, Clone, PartialEq)]")
        line(ind, "pub struct " + typeName(d.name) + " {")
        Map<String, String> seen = [:]
        members.each { pair ->
            IdlMember m = (IdlMember) pair[0]
            List<String> ms = (List<String>) pair[1]
            String fn = fieldName(m.decl.name)
            IdlNaming.checkDistinct(seen, fn, m.decl.name, "member", m.line)
            String t = rustType(m.type, m.decl.dims, ms)
            if (m.annotation("optional") != null) t = "Option<" + t + ">"
            docs(m, m.type).each { line(ind + 1, it) }
            line(ind + 1, "pub " + fn + ": " + t + ",")
        }
        line(ind, "}")
    }

    void enumeration(IdlEnum e, int ind) {
        line(ind, "#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]")
        line(ind, "#[repr(i64)]")
        line(ind, "pub enum " + typeName(e.name) + " {")
        Map<String, String> seen = [:]
        long next = 0
        e.literals.each { l ->
            long v = e.values.containsKey(l) ? e.values[l] : next
            next = v + 1
            String vn = typeName(l)
            IdlNaming.checkDistinct(seen, vn, l, "enumerator", e.line)
            line(ind + 1, vn + " = " + v + ",")
        }
        line(ind, "}")
    }

    String constValue(Object v, IdlTypeRef t, List<String> scope, int line) {
        List r = ctx.resolveAlias(t, scope)
        IdlTypeRef base = (IdlTypeRef) r[0]
        if (v instanceof IdlScopedValue) {
            IdlDefinition e = base.kind == "scoped" ? ctx.require(base, (List<String>) r[2]) : null
            String lit = ((IdlScopedValue) v).name
            lit = lit.contains("::") ? lit.substring(lit.lastIndexOf("::") + 2) : lit
            if (e instanceof IdlEnum) return path(e) + "::" + typeName(lit)
            throw new IdlException("constant refers to '" + ((IdlScopedValue) v).name + "', which is not a value", line)
        }
        if (v instanceof Boolean) return v.toString()
        if (base.kind in ["string", "wstring"]) return '"' + String.valueOf(v).replaceAll(/\\x([0-9a-fA-F]{1,2})/) { all, h -> "\\u{" + h + "}" } + '"'
        String rt = elementType(base, (List<String>) r[2])
        if (rt == "char") return v instanceof Number ? "'\\u{" + Long.toHexString(((Number) v).longValue()) + "}'" : "'" + v + "'"
        if (rt in ["f32", "f64"]) { String s = String.valueOf(v instanceof Double ? v : ((Number) v).doubleValue()); return s.contains("E") ? s.replace("E", "e") : s }
        if (rt == "bool") return String.valueOf(v).toLowerCase()
        return String.valueOf(v) + (rt == "i128" ? "" : "")
    }

    void constant(IdlConst c, List<String> scope, int ind) {
        List r = ctx.resolveAlias(c.type, scope)
        IdlTypeRef base = (IdlTypeRef) r[0]
        String t = base.kind in ["string", "wstring"] ? "&str" : rustType(c.type, [], scope)
        line(ind, "pub const " + constName(c.name) + ": " + t + " = " + constValue(c.value, c.type, scope, c.line) + ";")
    }

    void union(IdlUnion u, List<String> scope, int ind) {
        List r = ctx.resolveAlias(u.discriminator, scope)
        IdlTypeRef discBase = (IdlTypeRef) r[0]
        List<String> discScope = (List<String>) r[2]
        String dt = elementType(discBase, discScope)
        IdlEnum discEnum = discBase.kind == "scoped" ? (IdlEnum) ctx.require(discBase, discScope) : null
        def lit = { Object v ->
            if (discEnum != null) return path(discEnum) + "::" + typeName((String) v)
            if (v instanceof Boolean || v instanceof String) return String.valueOf(v)
            return String.valueOf(v)
        }
        String n = typeName(u.name)
        line(ind, "/// IDL union " + u.name + " switch (" + (u.discriminator.name ?: u.discriminator.kind) + ")")
        line(ind, "#[derive(Debug, Clone, PartialEq)]")
        line(ind, "pub enum " + n + " {")
        Map<String, String> seen = [:]
        List<String> arms = []
        u.cases.each { uc ->
            IdlMember m = uc.member
            List<Object> values = uc.labels.collect { ctx.labelValue(it, discBase, discScope, scope, m.line) }
            String vn = typeName(m.decl.name)
            IdlNaming.checkDistinct(seen, vn, m.decl.name, "union member", m.line)
            String t = rustType(m.type, m.decl.dims, scope)
            line(ind + 1, "/// " + (uc.isDefault ? "default" : "") + (uc.isDefault && values ? ", " : "") + (values ? "case " + values.collect { lit(it) }.join(", ") : ""))
            if (values.size() == 1 && !uc.isDefault) {
                line(ind + 1, vn + "(" + t + "),")
                arms << n + "::" + vn + "(_) => " + lit(values[0]) + ","
            } else {
                line(ind + 1, vn + "(" + dt + ", " + t + "),")
                arms << n + "::" + vn + "(d, _) => *d,"
            }
        }
        line(ind, "}")
        line(ind, "impl " + n + " {")
        line(ind + 1, "pub fn discriminator(&self) -> " + dt + " {")
        line(ind + 2, "match self {")
        arms.each { line(ind + 3, it) }
        line(ind + 2, "}")
        line(ind + 1, "}")
        line(ind, "}")
    }

    void trait(IdlInterface itf, List<String> scope, int ind) {
        String bases = itf.bases ? ": " + itf.bases.collect { bn ->
            IdlDefinition d = ctx.lookup(bn, scope)
            if (!(d instanceof IdlInterface)) throw new IdlException("interface base '" + bn + "' is not an interface in this file", itf.line)
            path(d)
        }.join(" + ") : ""
        line(ind, "pub trait " + typeName(itf.name) + bases + " {")
        Map<String, String> seen = [:]
        itf.exports.each { e ->
            if (e instanceof IdlAttribute) {
                IdlAttribute a = (IdlAttribute) e
                String t = rustType(a.type, [], scope)
                String fn = IdlNaming.snake(a.name)
                IdlNaming.checkDistinct(seen, "get_" + fn, a.name, "attribute", a.line)
                line(ind + 1, "fn " + id("get_" + fn) + "(&self) -> " + t + ";")
                if (!a.readonly) line(ind + 1, "fn " + id("set_" + fn) + "(&mut self, value: " + t + ");")
            } else {
                IdlOperation op = (IdlOperation) e
                String fn = fieldName(op.name)
                IdlNaming.checkDistinct(seen, fn, op.name, "operation", op.line)
                Map<String, String> paramNames = [:]
                List<String> params = ["&mut self"] + op.params.collect { p ->
                    IdlNaming.checkDistinct(paramNames, fieldName(p.name), p.name, "parameter", op.line)
                    String t = rustType(p.type, [], scope)
                    fieldName(p.name) + ": " + (p.direction == "in" ? t : "&mut " + t)
                }
                String ret = op.returnType == null ? "()" : rustType(op.returnType, [], scope)
                if (op.raises) {
                    List<IdlDefinition> xs = op.raises.collect { rn ->
                        IdlDefinition x = ctx.lookup(rn, scope)
                        if (!(x instanceof IdlExceptionDef)) throw new IdlException("raises '" + rn + "' is not an exception in this file", op.line)
                        x
                    }
                    ret = "Result<" + ret + ", " + (xs.size() == 1 ? path(xs[0]) : "Box<dyn ::std::error::Error>") + ">"
                }
                if (op.oneway) line(ind + 1, "/// oneway")
                line(ind + 1, "fn " + fn + "(" + params.join(", ") + ")" + (ret == "()" ? "" : " -> " + ret) + ";")
            }
        }
        line(ind, "}")
    }
}

// ---------------------------------------------------------------- Facade

class UML3IdlCodegen {
    // relative path (package directories) -> Java source
    static Map<String, String> toJava(IdlFile f) { return new IdlToJava().generate(f) }
    // one Rust source file (a library crate root)
    static String toRust(IdlFile f) { return new IdlToRust().generate(f) }
}
