// UML3 IDL core: OMG IDL 4.2 (v1 scope) lexer, parser, AST, SysML v2 emitter and canonical IDL writer.
// Pure Groovy - no CATIA Magic dependencies - so the same code runs from the command line and inside
// CATIA Magic (loaded with GroovyClassLoader). Never calls System.exit; errors are IdlException with a line.
// Scope and mapping: docs/IDL-MAPPING.md and library/UML3IDL.sysml.

class IdlException extends RuntimeException {
    int line
    IdlException(String message, int line) {
        super("line " + line + ": " + message)
        this.line = line
    }
}

class IdlToken {
    String kind   // ID, INT, FLOAT, CHAR, STRING, PUNCT, EOF
    String text
    int line
    String toString() { return kind + "(" + text + ")@" + line }
}

class IdlLexer {
    List<IdlToken> tokens = []
    List<String> warnings = []

    IdlLexer(String src) { lex(src) }

    private void add(String kind, String text, int line) {
        tokens << new IdlToken(kind: kind, text: text, line: line)
    }

    private void lex(String s) {
        int i = 0, line = 1, n = s.length()
        boolean lineStart = true
        while (i < n) {
            char c = s.charAt(i)
            if (c == '\n' as char) { line++; i++; lineStart = true; continue }
            if (Character.isWhitespace(c)) { i++; continue }
            if (c == '#' as char && lineStart) {
                int e = s.indexOf('\n', i); if (e < 0) e = n
                warnings << ("line " + line + ": preprocessor directive ignored: " + s.substring(i, e).trim())
                i = e; continue
            }
            lineStart = false
            if (s.startsWith("//", i)) { int e = s.indexOf('\n', i); i = e < 0 ? n : e; continue }
            if (s.startsWith("/*", i)) {
                int e = s.indexOf("*/", i + 2)
                if (e < 0) throw new IdlException("unterminated comment", line)
                line += s.substring(i, e).count("\n"); i = e + 2; continue
            }
            if ((c == 'L' as char) && i + 1 < n && (s.charAt(i + 1) == '"' as char || s.charAt(i + 1) == '\'' as char)) { i++; c = s.charAt(i) }
            if (c == '"' as char || c == '\'' as char) {
                char q = c
                StringBuilder sb = new StringBuilder()
                int j = i + 1
                while (j < n && s.charAt(j) != q) {
                    if (s.charAt(j) == '\\' as char && j + 1 < n) { sb.append(s.charAt(j)); j++ }
                    if (s.charAt(j) == '\n' as char) throw new IdlException("unterminated literal", line)
                    sb.append(s.charAt(j)); j++
                }
                if (j >= n) throw new IdlException("unterminated literal", line)
                add(q == '"' as char ? "STRING" : "CHAR", sb.toString(), line)
                i = j + 1; continue
            }
            if (Character.isDigit(c) || (c == '.' as char && i + 1 < n && Character.isDigit(s.charAt(i + 1)))) {
                int j = i
                if (s.startsWith("0x", i) || s.startsWith("0X", i)) {
                    j = i + 2
                    while (j < n && Character.digit(s.charAt(j), 16) >= 0) j++
                    add("INT", s.substring(i, j), line); i = j; continue
                }
                boolean isFloat = false
                while (j < n && Character.isDigit(s.charAt(j))) j++
                if (j < n && s.charAt(j) == '.' as char) { isFloat = true; j++; while (j < n && Character.isDigit(s.charAt(j))) j++ }
                if (j < n && (s.charAt(j) == 'e' as char || s.charAt(j) == 'E' as char)) {
                    isFloat = true; j++
                    if (j < n && (s.charAt(j) == '+' as char || s.charAt(j) == '-' as char)) j++
                    while (j < n && Character.isDigit(s.charAt(j))) j++
                }
                if (j < n && (s.charAt(j) == 'd' as char || s.charAt(j) == 'D' as char)) { isFloat = true; j++ }
                add(isFloat ? "FLOAT" : "INT", s.substring(i, j), line); i = j; continue
            }
            if (Character.isLetter(c) || c == '_' as char) {
                int j = i
                while (j < n && (Character.isLetterOrDigit(s.charAt(j)) || s.charAt(j) == '_' as char)) j++
                add("ID", s.substring(i, j), line); i = j; continue
            }
            for (String p : ["::", "<<", ">>"]) {
                if (s.startsWith(p, i)) { add("PUNCT", p, line); i += 2; c = 0 as char; break }
            }
            if (c == 0 as char) continue
            if ("{}()<>[];:,=+-*/%|^&~@".indexOf(c as int) >= 0) { add("PUNCT", String.valueOf(c), line); i++; continue }
            throw new IdlException("unexpected character '" + c + "'", line)
        }
        add("EOF", "", line)
    }
}

// ---------------------------------------------------------------- AST

class IdlAnnotation {
    String name
    List<String> args = []        // raw tokens of the argument list, null-free
    String argText() { return joinTokens(args) }
    String text() { return "@" + name + (args ? "(" + argText() + ")" : "") }
    static String joinTokens(List<String> ts) {
        StringBuilder sb = new StringBuilder()
        ts.each { t -> if (t == ",") sb.append(", ") else sb.append(t) }
        return sb.toString()
    }
}

class IdlTypeRef {
    String kind        // basic, scoped, sequence, string, wstring, fixed
    String name        // basic canonical name or scoped name (no leading ::)
    IdlTypeRef element // sequence element
    Long bound         // sequence / string bound
    Integer digits
    Integer scale
    int line
}

class IdlDeclarator {
    String name
    List<Long> dims = []
}

class IdlMember {
    List<IdlAnnotation> annotations = []
    IdlTypeRef type
    IdlDeclarator decl
    int line
    IdlAnnotation annotation(String n) { return annotations.find { it.name == n } }
}

class IdlDefinition {
    String kind
    String name
    List<IdlAnnotation> annotations = []
    int line
}

class IdlModule extends IdlDefinition { List<IdlDefinition> defs = [] }
class IdlConst extends IdlDefinition { IdlTypeRef type; List<IdlToken> expr = []; Object value }
class IdlTypedef extends IdlDefinition { IdlTypeRef type; IdlDeclarator decl }
class IdlStruct extends IdlDefinition { String base; List<IdlMember> members = [] }
class IdlUnionCase { List<String> labels = []; boolean isDefault; IdlMember member }
class IdlUnion extends IdlDefinition { IdlTypeRef discriminator; List<IdlUnionCase> cases = [] }
class IdlEnum extends IdlDefinition { List<String> literals = [] }
class IdlExceptionDef extends IdlDefinition { List<IdlMember> members = [] }
class IdlAttribute { List<IdlAnnotation> annotations = []; boolean readonly; IdlTypeRef type; String name; int line }
class IdlParam { String direction; IdlTypeRef type; String name; List<IdlAnnotation> annotations = [] }
class IdlOperation {
    List<IdlAnnotation> annotations = []
    boolean oneway
    IdlTypeRef returnType   // null = void
    String name
    List<IdlParam> params = []
    List<String> raises = []
    int line
}
class IdlInterface extends IdlDefinition { List<String> bases = []; List<Object> exports = [] }

class IdlFile {
    String fileName
    List<IdlDefinition> defs = []
    List<String> warnings = []
}

// ---------------------------------------------------------------- Parser

class IdlParser {
    static final Set<String> BASIC_WORDS = ["short", "long", "unsigned", "float", "double", "char", "wchar", "boolean",
        "octet", "any", "int8", "uint8", "int16", "uint16", "int32", "uint32", "int64", "uint64"] as Set
    static final Set<String> UNSUPPORTED = ["valuetype", "eventtype", "component", "home", "native", "bitset", "bitmask",
        "typeid", "typeprefix", "import", "porttype", "connector", "custom", "map", "Object", "ValueBase"] as Set

    List<IdlToken> t
    int p = 0
    IdlFile file
    List<String> scope = []
    Map<String, Object> constValues = [:]   // fully qualified and simple names -> Long/Double/String/Boolean

    IdlFile parse(String text, String fileName) {
        IdlLexer lx = new IdlLexer(text)
        t = lx.tokens
        file = new IdlFile(fileName: fileName)
        file.warnings.addAll(lx.warnings)
        while (!at("EOF")) {
            IdlDefinition d = definition()
            if (d != null) file.defs << d
        }
        return file
    }

    // -- token helpers
    IdlToken peek(int k = 0) { return t[Math.min(p + k, t.size() - 1)] }
    boolean at(String kind) { return peek().kind == kind }
    boolean isWord(String w, int k = 0) { IdlToken x = peek(k); return x.kind == "ID" && x.text == w }
    boolean isPunct(String s, int k = 0) { IdlToken x = peek(k); return x.kind == "PUNCT" && x.text == s }
    IdlToken next() { return t[p++] }
    IdlToken expectPunct(String s) {
        if (!isPunct(s)) throw new IdlException("expected '" + s + "' but found '" + peek().text + "'", peek().line)
        return next()
    }
    void expectWord(String w) {
        if (!isWord(w)) throw new IdlException("expected '" + w + "' but found '" + peek().text + "'", peek().line)
        next()
    }
    String identifier() {
        IdlToken x = peek()
        if (x.kind != "ID") throw new IdlException("expected identifier but found '" + x.text + "'", x.line)
        next()
        return x.text.startsWith("_") ? x.text.substring(1) : x.text   // IDL escaped identifier
    }
    String scopedName() {
        StringBuilder sb = new StringBuilder()
        if (isPunct("::")) next()
        sb.append(identifier())
        while (isPunct("::")) { next(); sb.append("::").append(identifier()) }
        return sb.toString()
    }
    String qualify(String simple) { return (scope + [simple]).join("::") }

    List<IdlAnnotation> annotations() {
        List<IdlAnnotation> out = []
        while (isPunct("@")) {
            next()
            IdlAnnotation a = new IdlAnnotation(name: identifier())
            if (isPunct("(")) {
                next()
                int depth = 1
                while (depth > 0) {
                    IdlToken x = next()
                    if (x.kind == "EOF") throw new IdlException("unterminated annotation", x.line)
                    if (x.kind == "PUNCT" && x.text == "(") depth++
                    if (x.kind == "PUNCT" && x.text == ")") { depth--; if (depth == 0) break }
                    a.args << (x.kind == "STRING" ? '"' + x.text + '"' : x.text)
                }
            }
            out << a
        }
        return out
    }

    // -- definitions
    IdlDefinition definition() {
        List<IdlAnnotation> anns = annotations()
        IdlToken x = peek()
        if (x.kind != "ID") throw new IdlException("expected a definition but found '" + x.text + "'", x.line)
        String w = x.text
        if (UNSUPPORTED.contains(w) || (w == "abstract" && isWord("valuetype", 1))) {
            throw new IdlException("unsupported IDL construct '" + (w == "abstract" ? "valuetype" : w) + "'", x.line)
        }
        IdlDefinition d
        switch (w) {
            case "module": d = module(); break
            case "const": d = constDef(); break
            case "typedef": typedefs(anns); expectPunct(";"); return null
            case "struct": d = struct(); break
            case "union": d = union(); break
            case "enum": d = enumDef(); break
            case "exception": d = exceptionDef(); break
            case "local":
            case "abstract":
                next()
                if (!isWord("interface")) throw new IdlException("unsupported IDL construct '" + w + " " + peek().text + "'", x.line)
                file.warnings << ("line " + x.line + ": '" + w + "' interface qualifier not represented")
                d = interfaceDef(); break
            case "interface": d = interfaceDef(); break
            default: throw new IdlException("unexpected '" + w + "'", x.line)
        }
        expectPunct(";")
        if (d != null) d.annotations.addAll(0, anns)
        return d
    }

    IdlModule module() {
        int line = peek().line
        expectWord("module")
        IdlModule m = new IdlModule(kind: "module", name: identifier(), line: line)
        expectPunct("{")
        scope << m.name
        while (!isPunct("}")) {
            IdlDefinition d = definition()
            if (d != null) m.defs << d
        }
        scope.remove(scope.size() - 1)
        expectPunct("}")
        return m
    }

    IdlConst constDef() {
        int line = peek().line
        expectWord("const")
        IdlConst c = new IdlConst(kind: "const", line: line)
        c.type = typeSpec(false)
        c.name = identifier()
        expectPunct("=")
        while (!isPunct(";")) {
            IdlToken x = next()
            if (x.kind == "EOF") throw new IdlException("unterminated constant", line)
            if (x.kind == "PUNCT" && x.text in ["<<", ">>", "|", "&", "^", "~"]) {
                throw new IdlException("unsupported operator '" + x.text + "' in constant expression", x.line)
            }
            c.expr << x
        }
        c.value = evaluate(c.expr, line)
        constValues[c.name] = c.value
        constValues[qualify(c.name)] = c.value
        return c
    }

    // literals, constant names, unary minus, + - * / % and parentheses
    Object evaluate(List<IdlToken> expr, int line) {
        List<IdlToken> ts = new ArrayList<>(expr)
        int[] pos = [0] as int[]
        def primary
        def term
        def exprFn
        primary = {
            IdlToken x = ts[pos[0]]
            if (x.kind == "PUNCT" && x.text == "-") { pos[0]++; def v = primary(); return v instanceof Number ? -v : null }
            if (x.kind == "PUNCT" && x.text == "(") { pos[0]++; def v = exprFn(); pos[0]++; return v }
            pos[0]++
            switch (x.kind) {
                case "INT": return x.text.toLowerCase().startsWith("0x") ? Long.parseLong(x.text.substring(2), 16) : Long.parseLong(x.text)
                case "FLOAT": return Double.parseDouble(x.text.replaceAll("[dD]\$", ""))
                case "STRING": return x.text
                case "CHAR": return x.text
                case "ID":
                    if (x.text == "TRUE") return Boolean.TRUE
                    if (x.text == "FALSE") return Boolean.FALSE
                    StringBuilder qn = new StringBuilder(x.text)
                    while (pos[0] + 1 < ts.size() && ts[pos[0]].text == "::") { qn.append("::").append(ts[pos[0] + 1].text); pos[0] += 2 }
                    Object v = constValues[qn.toString()]
                    return v != null ? v : new IdlScopedValue(name: qn.toString())
                case "PUNCT":
                    if (x.text == "::") return primary()
                default: throw new IdlException("cannot evaluate constant expression", line)
            }
        }
        term = {
            def v = primary()
            while (pos[0] < ts.size() && ts[pos[0]].text in ["*", "/", "%"]) {
                String op = ts[pos[0]++].text; def r = primary()
                if (!(v instanceof Number) || !(r instanceof Number)) throw new IdlException("non-numeric constant arithmetic", line)
                v = op == "*" ? v * r : op == "/" ? (v instanceof Long && r instanceof Long ? v.intdiv(r) : v / r) : v % r
            }
            return v
        }
        exprFn = {
            def v = term()
            while (pos[0] < ts.size() && ts[pos[0]].text in ["+", "-"]) {
                String op = ts[pos[0]++].text; def r = term()
                if (v instanceof String && r instanceof String && op == "+") { v = v + r; continue }
                if (!(v instanceof Number) || !(r instanceof Number)) throw new IdlException("non-numeric constant arithmetic", line)
                v = op == "+" ? v + r : v - r
            }
            return v
        }
        Object result = exprFn()
        if (pos[0] != ts.size()) throw new IdlException("cannot evaluate constant expression", line)
        return result
    }

    void typedefs(List<IdlAnnotation> anns) {
        int line = peek().line
        expectWord("typedef")
        IdlTypeRef type = typeSpec(false)
        declarators().each { dd ->
            IdlTypedef td = new IdlTypedef(kind: "typedef", name: dd.name, type: type, decl: dd, line: line)
            td.annotations.addAll(anns)
            pendingTypedefs << td
        }
    }

    // one typedef statement yields one definition per declarator; IdlParserV1 inserts them in order
    List<IdlTypedef> pendingTypedefs = []

    Long boundValue() {
        IdlToken x = next()
        if (x.kind == "INT") return x.text.toLowerCase().startsWith("0x") ? Long.parseLong(x.text.substring(2), 16) : Long.parseLong(x.text)
        if (x.kind == "ID") {
            StringBuilder qn = new StringBuilder(x.text)
            while (isPunct("::")) { next(); qn.append("::").append(identifier()) }
            Object v = constValues[qn.toString()]
            if (v instanceof Long) return (Long) v
            throw new IdlException("bound '" + qn + "' is not an integer constant", x.line)
        }
        throw new IdlException("expected a positive integer bound", x.line)
    }

    IdlTypeRef typeSpec(boolean allowVoid) {
        IdlToken x = peek()
        int line = x.line
        if (x.kind != "ID" && !(x.kind == "PUNCT" && x.text == "::")) throw new IdlException("expected a type but found '" + x.text + "'", line)
        String w = x.text
        if (w in ["map", "Object", "ValueBase"]) throw new IdlException("unsupported IDL construct '" + w + "'", line)
        if (w == "void") {
            if (!allowVoid) throw new IdlException("'void' is only allowed as an operation result", line)
            next(); return null
        }
        if (w == "unsigned") {
            next()
            if (isWord("short")) { next(); return basic("unsigned short", line) }
            expectWord("long")
            if (isWord("long")) { next(); return basic("unsigned long long", line) }
            return basic("unsigned long", line)
        }
        if (w == "long") {
            next()
            if (isWord("long")) { next(); return basic("long long", line) }
            if (isWord("double")) { next(); return basic("long double", line) }
            return basic("long", line)
        }
        if (BASIC_WORDS.contains(w)) { next(); return basic(canonicalBasic(w), line) }
        if (w == "string" || w == "wstring") {
            next()
            IdlTypeRef r = new IdlTypeRef(kind: w, line: line)
            if (isPunct("<")) { next(); r.bound = boundValue(); expectPunct(">") }
            return r
        }
        if (w == "fixed") {
            next(); expectPunct("<")
            IdlTypeRef r = new IdlTypeRef(kind: "fixed", line: line)
            r.digits = boundValue() as Integer; expectPunct(","); r.scale = boundValue() as Integer
            expectPunct(">")
            return r
        }
        if (w == "sequence") {
            next(); expectPunct("<")
            IdlTypeRef el = typeSpec(false)
            if (el.kind == "sequence") throw new IdlException("anonymous nested sequence is not supported; typedef the inner sequence", line)
            IdlTypeRef r = new IdlTypeRef(kind: "sequence", element: el, line: line)
            if (isPunct(",")) { next(); r.bound = boundValue() }
            if (isPunct(">>")) throw new IdlException("anonymous nested sequence is not supported; typedef the inner sequence", line)
            expectPunct(">")
            return r
        }
        return new IdlTypeRef(kind: "scoped", name: scopedName(), line: line)
    }

    static String canonicalBasic(String w) {
        switch (w) {
            case "int16": return "short"
            case "int32": return "long"
            case "int64": return "long long"
            case "uint16": return "unsigned short"
            case "uint32": return "unsigned long"
            case "uint64": return "unsigned long long"
            default: return w
        }
    }

    static IdlTypeRef basic(String name, int line) { return new IdlTypeRef(kind: "basic", name: name, line: line) }

    List<IdlDeclarator> declarators() {
        List<IdlDeclarator> out = [declarator()]
        while (isPunct(",")) { next(); out << declarator() }
        return out
    }

    IdlDeclarator declarator() {
        IdlDeclarator d = new IdlDeclarator(name: identifier())
        while (isPunct("[")) { next(); d.dims << boundValue(); expectPunct("]") }
        return d
    }

    List<IdlMember> members() {
        List<IdlMember> out = []
        while (!isPunct("}")) {
            List<IdlAnnotation> anns = annotations()
            int line = peek().line
            IdlTypeRef type = typeSpec(false)
            declarators().each { dd ->
                IdlMember m = new IdlMember(type: type, decl: dd, line: line)
                m.annotations.addAll(anns)
                out << m
            }
            expectPunct(";")
        }
        return out
    }

    IdlStruct struct() {
        int line = peek().line
        expectWord("struct")
        IdlStruct s = new IdlStruct(kind: "struct", name: identifier(), line: line)
        if (isPunct(";")) return null   // forward declaration
        if (isPunct(":")) { next(); s.base = scopedName() }
        expectPunct("{")
        s.members = members()
        expectPunct("}")
        return s
    }

    IdlUnion union() {
        int line = peek().line
        expectWord("union")
        IdlUnion u = new IdlUnion(kind: "union", name: identifier(), line: line)
        if (isPunct(";")) return null
        expectWord("switch"); expectPunct("(")
        annotations()
        u.discriminator = typeSpec(false)
        expectPunct(")"); expectPunct("{")
        while (!isPunct("}")) {
            IdlUnionCase uc = new IdlUnionCase()
            while (isWord("case") || isWord("default")) {
                if (isWord("default")) { next(); uc.isDefault = true; expectPunct(":"); continue }
                next()
                List<String> label = []
                while (!isPunct(":")) {
                    IdlToken x = next()
                    if (x.kind == "EOF") throw new IdlException("unterminated case label", line)
                    label << (x.kind == "STRING" ? '"' + x.text + '"' : x.kind == "CHAR" ? "'" + x.text + "'" : x.text)
                }
                expectPunct(":")
                uc.labels << label.join("").replaceFirst('^::', '')
            }
            if (uc.labels.isEmpty() && !uc.isDefault) throw new IdlException("expected 'case' or 'default'", peek().line)
            List<IdlAnnotation> anns = annotations()
            int ml = peek().line
            IdlTypeRef type = typeSpec(false)
            IdlMember m = new IdlMember(type: type, decl: declarator(), line: ml)
            m.annotations.addAll(anns)
            expectPunct(";")
            uc.member = m
            u.cases << uc
        }
        expectPunct("}")
        return u
    }

    IdlEnum enumDef() {
        int line = peek().line
        expectWord("enum")
        IdlEnum e = new IdlEnum(kind: "enum", name: identifier(), line: line)
        expectPunct("{")
        annotations()
        e.literals << identifier()
        while (isPunct(",")) { next(); annotations(); e.literals << identifier() }
        expectPunct("}")
        return e
    }

    IdlExceptionDef exceptionDef() {
        int line = peek().line
        expectWord("exception")
        IdlExceptionDef x = new IdlExceptionDef(kind: "exception", name: identifier(), line: line)
        expectPunct("{")
        x.members = members()
        expectPunct("}")
        return x
    }

    IdlInterface interfaceDef() {
        int line = peek().line
        expectWord("interface")
        IdlInterface itf = new IdlInterface(kind: "interface", name: identifier(), line: line)
        if (isPunct(";")) return null   // forward declaration
        if (isPunct(":")) {
            next()
            itf.bases << scopedName()
            while (isPunct(",")) { next(); itf.bases << scopedName() }
        }
        expectPunct("{")
        while (!isPunct("}")) {
            List<IdlAnnotation> anns = annotations()
            IdlToken x = peek()
            if (x.kind == "ID" && x.text in ["typedef", "struct", "union", "enum", "exception", "const"]) {
                throw new IdlException("type declarations inside an interface are not supported in v1 ('" + x.text + "'); declare them in the module", x.line)
            }
            if (isWord("readonly") || isWord("attribute")) {
                boolean ro = false
                if (isWord("readonly")) { next(); ro = true }
                expectWord("attribute")
                IdlTypeRef type = typeSpec(false)
                List<String> names = [identifier()]
                while (isPunct(",")) { next(); names << identifier() }
                if (isWord("getraises") || isWord("setraises") || isWord("raises")) {
                    throw new IdlException("unsupported IDL construct 'attribute raises'", peek().line)
                }
                names.each { nm ->
                    IdlAttribute a = new IdlAttribute(readonly: ro, type: type, name: nm, line: x.line)
                    a.annotations.addAll(anns)
                    itf.exports << a
                }
                expectPunct(";")
                continue
            }
            IdlOperation op = new IdlOperation(line: x.line)
            op.annotations.addAll(anns)
            if (isWord("oneway")) { next(); op.oneway = true }
            op.returnType = typeSpec(true)
            op.name = identifier()
            expectPunct("(")
            while (!isPunct(")")) {
                List<IdlAnnotation> pAnns = annotations()
                IdlToken d = next()
                if (!(d.kind == "ID" && d.text in ["in", "out", "inout"])) throw new IdlException("expected parameter direction but found '" + d.text + "'", d.line)
                IdlParam prm = new IdlParam(direction: d.text, type: typeSpec(false), name: identifier())
                prm.annotations.addAll(pAnns)
                op.params << prm
                if (isPunct(",")) next()
            }
            expectPunct(")")
            if (isWord("raises")) {
                next(); expectPunct("(")
                op.raises << scopedName()
                while (isPunct(",")) { next(); op.raises << scopedName() }
                expectPunct(")")
            }
            if (isWord("context")) throw new IdlException("unsupported IDL construct 'context'", peek().line)
            expectPunct(";")
            itf.exports << op
        }
        expectPunct("}")
        return itf
    }
}

class IdlScopedValue {
    String name
    String toString() { return name }
}

// Parser subclass hook: typedefs are inserted where they occur. Implemented by overriding the container
// loops (module/file) instead of the placeholder pendingTypedefs list above.
class IdlParserV1 extends IdlParser {
    @Override
    IdlFile parse(String text, String fileName) {
        IdlLexer lx = new IdlLexer(text)
        t = lx.tokens
        file = new IdlFile(fileName: fileName)
        file.warnings.addAll(lx.warnings)
        while (!at("EOF")) { file.defs.addAll(definitionsOnce()) }
        return file
    }

    List<IdlDefinition> definitionsOnce() {
        pendingTypedefs.clear()
        IdlDefinition d = definition()
        List<IdlDefinition> out = []
        out.addAll(pendingTypedefs)
        pendingTypedefs.clear()
        if (d != null) out << d
        return out
    }

    @Override
    IdlModule module() {
        int line = peek().line
        expectWord("module")
        IdlModule m = new IdlModule(kind: "module", name: identifier(), line: line)
        expectPunct("{")
        scope << m.name
        while (!isPunct("}")) { m.defs.addAll(definitionsOnce()) }
        scope.remove(scope.size() - 1)
        expectPunct("}")
        return m
    }
}

// ---------------------------------------------------------------- Name resolution

class IdlNames {
    Map<String, IdlDefinition> byQualified = [:]
    Map<IdlDefinition, String> qualifiedOf = [:]

    IdlNames(IdlFile f) { index(f.defs, []) }

    private void index(List<IdlDefinition> defs, List<String> scope) {
        defs.each { d ->
            String q = (scope + [d.name]).join("::")
            byQualified[q] = d
            qualifiedOf[d] = q
            if (d instanceof IdlModule) index(((IdlModule) d).defs, scope + [d.name])
        }
    }

    // IDL resolution: search the enclosing scopes from innermost outward; leading '::' = absolute
    String resolve(String name, List<String> scope) {
        for (int i = scope.size(); i >= 0; i--) {
            String q = (scope.subList(0, i) + [name]).join("::")
            if (byQualified.containsKey(q)) return q
        }
        return name
    }
}

// ---------------------------------------------------------------- SysML v2 emitter

class IdlToSysml {
    static final Set<String> RESERVED = ([
        // SysML v2 reserved words
        "about", "abstract", "accept", "action", "actor", "after", "alias", "all", "allocate", "allocation", "analysis",
        "and", "as", "assert", "assign", "assume", "at", "attribute", "bind", "binding", "by", "calc", "case", "comment",
        "concern", "connect", "connection", "constant", "constraint", "crosses", "decide", "def", "default", "defined",
        "dependency", "derived", "do", "doc", "else", "end", "entry", "enum", "event", "exhibit", "exit", "expose",
        "false", "filter", "first", "flow", "for", "fork", "frame", "from", "hastype", "if", "implies", "import", "in",
        "include", "individual", "inout", "interface", "istype", "item", "join", "language", "library", "locale", "loop",
        "merge", "message", "meta", "metadata", "nonunique", "not", "null", "objective", "occurrence", "of", "or",
        "ordered", "out", "package", "parallel", "part", "perform", "port", "private", "protected", "public",
        "redefines", "ref", "references", "render", "rendering", "rep", "require", "requirement", "return", "satisfy",
        "send", "snapshot", "specializes", "stakeholder", "standard", "state", "subject", "subsets", "succession",
        "terminate", "then", "timeslice", "to", "transition", "true", "until", "use", "variant", "variation",
        "verification", "verify", "via", "view", "viewpoint", "when", "while", "xor",
        // KerML keywords rejected as names by some tools
        "assoc", "behavior", "bool", "chains", "class", "classifier", "composite", "conjugate", "conjugates",
        "conjugation", "connector", "datatype", "differences", "disjoining", "disjoint", "expr", "feature", "featured",
        "featuring", "function", "interaction", "intersects", "inv", "inverse", "member", "metaclass", "multiplicity",
        "namespace", "portion", "predicate", "readonly", "redefinition", "sequence", "specialization", "start", "done",
        "step", "struct", "subclassifier", "subset", "subtype", "type", "typed", "typing", "unions", "value", "var"
    ] as Set)

    static final Map<String, String> BASIC = [
        "short": "Int16", "unsigned short": "UInt16", "long": "Int32", "unsigned long": "UInt32",
        "long long": "Int64", "unsigned long long": "UInt64", "int8": "Int8", "uint8": "UInt8",
        "float": "Float32", "double": "Float64", "long double": "LongDouble", "char": "Char", "wchar": "WChar",
        "boolean": "Boolean", "octet": "Octet", "any": "Any"
    ]

    IdlFile file
    IdlNames names
    StringBuilder out = new StringBuilder()
    List<String> warnings = []

    static String name(String n) {
        return (RESERVED.contains(n) || !(n ==~ /[A-Za-z_][A-Za-z0-9_]*/)) ? "'" + n + "'" : n
    }
    static String qname(String q) { return q.split("::").collect { name(it) }.join("::") }
    static String str(String s) { return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"' }

    String convert(IdlFile f) {
        file = f
        names = new IdlNames(f)
        String base = f.fileName.replaceAll(/\.idl$/, "").replaceAll(/.*[\\\/]/, "")
        line(0, "package " + name(base.replaceAll(/[^A-Za-z0-9_]/, "_")) + " {")
        line(1, "doc /* Generated from " + f.fileName.replaceAll(/.*[\\\/]/, "") + " by the UML3 IDL importer (tools/idl). */")
        line(1, "@IdlFile { fileName = " + str(f.fileName.replaceAll(/.*[\\\/]/, "")) + "; }")
        line(1, "private import ScalarValues::*;")
        line(1, "private import UML3Core::*;")
        line(1, "private import UML3Types::*;")
        line(1, "private import UML3IDL::*;")
        definitions(f.defs, [], 1)
        line(0, "}")
        return out.toString()
    }

    void line(int indent, String text) { out.append("\t" * indent).append(text).append("\n") }

    void definitions(List<IdlDefinition> defs, List<String> scope, int ind) {
        defs.each { d ->
            if (d instanceof IdlModule) {
                line(ind, "package " + name(d.name) + " {")
                definitions(((IdlModule) d).defs, scope + [d.name], ind + 1)
                line(ind, "}")
            } else if (d instanceof IdlConst) {
                IdlConst c = (IdlConst) d
                Shape sh = shape(c.type, null, false, c.line)
                line(ind, "constant attribute " + name(c.name) + " : " + sh.type + " = " + constValue(c.value, c.type) + ";")
            } else if (d instanceof IdlEnum) {
                line(ind, "enum def " + name(d.name) + " {")
                ((IdlEnum) d).literals.each { lit -> line(ind + 1, "enum " + name(lit) + ";") }
                line(ind, "}")
            } else if (d instanceof IdlTypedef) {
                typedef((IdlTypedef) d, ind)
            } else if (d instanceof IdlStruct) {
                IdlStruct s = (IdlStruct) d
                line(ind, "#dataType attribute def " + name(s.name) + (s.base ? " :> " + qname(s.base) : "") + " {")
                defAnnotations(s, ind + 1)
                s.members.each { m -> member(m, ind + 1, null) }
                line(ind, "}")
            } else if (d instanceof IdlUnion) {
                union((IdlUnion) d, ind)
            } else if (d instanceof IdlExceptionDef) {
                IdlExceptionDef x = (IdlExceptionDef) d
                line(ind, "#exceptionType item def " + name(x.name) + " {")
                defAnnotations(x, ind + 1)
                x.members.each { m -> member(m, ind + 1, null) }
                line(ind, "}")
            } else if (d instanceof IdlInterface) {
                interfaceDef((IdlInterface) d, ind)
            }
        }
    }

    void defAnnotations(IdlDefinition d, int ind) {
        d.annotations.each { a -> line(ind, "@IdlAnnotation { text = " + str(a.text()) + "; }") }
    }

    String constValue(Object v, IdlTypeRef type) {
        if (v instanceof Boolean) return v ? "true" : "false"
        if (v instanceof String) return str((String) v)
        if (v instanceof IdlScopedValue) return qname(v.toString())
        if (v instanceof Double) return (v as Double).toString()
        return String.valueOf(v)
    }

    // --- type shape of a member / parameter / typedef element
    static class Shape {
        String type
        String multiplicity = ""
        Map<String, Object> facets = new LinkedHashMap<>()
        List<Long> arrayDims = []
    }

    Shape shape(IdlTypeRef t, IdlDeclarator decl, boolean optional, int line) {
        Shape sh = new Shape()
        IdlTypeRef el = t
        if (t.kind == "sequence") {
            el = t.element
            sh.multiplicity = "[0.." + (t.bound != null ? t.bound : "*") + "] ordered nonunique"
        }
        switch (el.kind) {
            case "basic": sh.type = BASIC[el.name]; break
            case "string": sh.type = "String"; if (el.bound != null) sh.facets.maxLength = el.bound; break
            case "wstring": sh.type = "WString"; if (el.bound != null) sh.facets.maxLength = el.bound; break
            case "fixed": sh.type = "Decimal"; sh.facets.precision = el.digits; sh.facets.scale = el.scale; break
            case "scoped": sh.type = qname(el.name); break
            default: throw new IdlException("unsupported element type " + el.kind, line)
        }
        if (decl != null && decl.dims) {
            if (t.kind == "sequence") throw new IdlException("arrays of anonymous sequences are not supported; typedef the sequence", line)
            long prod = 1
            decl.dims.each { prod *= it }
            sh.multiplicity = "[" + prod + "] ordered nonunique"
            sh.arrayDims = decl.dims
        }
        if (optional) {
            if (sh.multiplicity) throw new IdlException("@optional on a sequence or array is not supported", line)
            sh.multiplicity = "[0..1]"
        }
        return sh
    }

    static String facets(Map<String, Object> f) {
        List<String> order = ["minInclusive", "maxInclusive", "minLength", "maxLength", "precision", "scale"]
        List<String> parts = order.findAll { f.containsKey(it) }.collect { it + " = " + f[it] + ";" }
        return "@Facets { " + parts.join(" ") + " }"
    }

    Object resolveNumber(String text, int line) {
        String s = text.trim()
        if (s ==~ /-?\d+/) return Long.parseLong(s)
        if (s ==~ /-?\d*\.\d+([eE][-+]?\d+)?/) return Double.parseDouble(s)
        Object v = parserConstants[s]
        if (v instanceof Number) return v
        throw new IdlException("@range bound '" + s + "' is not a numeric constant", line)
    }

    Map<String, Object> parserConstants = [:]

    // member of a struct / exception / union branch; extra = @Case/@Discriminator text
    void member(IdlMember m, int ind, String extra) {
        boolean key = m.annotation("key") != null
        boolean optional = m.annotation("optional") != null
        Shape sh = shape(m.type, m.decl, optional || extra?.startsWith("@Case"), m.line)
        List<String> body = []
        String defaultText = ""
        m.annotations.each { a ->
            switch (a.name) {
                case "key": case "optional": break
                case "range":
                    Map<String, String> kv = keyValues(a)
                    if (kv.min != null) sh.facets.minInclusive = resolveNumber(kv.min, m.line)
                    if (kv.max != null) sh.facets.maxInclusive = resolveNumber(kv.max, m.line)
                    break
                case "default": defaultText = " default " + a.argText().replace("TRUE", "true").replace("FALSE", "false"); break
                case "id": break
                default: break
            }
        }
        if (sh.facets) body << facets(sh.facets)
        if (sh.arrayDims) body << "@IdlArray { dimensions = (" + sh.arrayDims.join(", ") + "); }"
        IdlAnnotation idAnn = m.annotation("id")
        if (idAnn != null) body << "@IdlMemberId { memberId = " + idAnn.argText() + "; }"
        if (extra) body << extra
        m.annotations.findAll { !(it.name in ["key", "optional", "range", "default", "id"]) }.each { a ->
            body << "@IdlAnnotation { text = " + str(a.text()) + "; }"
        }
        String decl = (key ? "#id " : "") + "attribute " + name(m.decl.name) + " : " + sh.type + sh.multiplicity + defaultText
        line(ind, body ? decl + " { " + body.join(" ") + " }" : decl + ";")
    }

    static Map<String, String> keyValues(IdlAnnotation a) {
        Map<String, String> kv = [:]
        String key = null
        StringBuilder val = new StringBuilder()
        List<String> toks = a.args + [","]
        for (int i = 0; i < toks.size(); i++) {
            String tk = toks[i]
            if (i + 1 < toks.size() && toks[i + 1] == "=" && key == null && val.length() == 0) { key = tk; i++; continue }
            if (tk == ",") { if (key != null) kv[key] = val.toString(); key = null; val.setLength(0); continue }
            val.append(tk)
        }
        return kv
    }

    void typedef(IdlTypedef td, int ind) {
        IdlTypeRef t = td.type
        String n = name(td.name)
        if (td.decl.dims) {
            if (t.kind == "sequence") throw new IdlException("typedef of an array of anonymous sequences is not supported", td.line)
            Shape sh = shape(t, td.decl, false, td.line)
            line(ind, "attribute def " + n + " {")
            defAnnotations(td, ind + 1)
            List<String> body = []
            if (sh.facets) body << facets(sh.facets)
            body << "@IdlArray { dimensions = (" + sh.arrayDims.join(", ") + "); }"
            line(ind + 1, "attribute items : " + sh.type + sh.multiplicity + " { " + body.join(" ") + " }")
            line(ind, "}")
            return
        }
        if (t.kind == "sequence") {
            Shape sh = shape(t, null, false, td.line)
            line(ind, "attribute def " + n + " {")
            defAnnotations(td, ind + 1)
            line(ind + 1, t.bound != null ? "@IdlSequence { bound = " + t.bound + "; }" : "@IdlSequence;")
            String itemDecl = "attribute items : " + sh.type + sh.multiplicity
            line(ind + 1, sh.facets ? itemDecl + " { " + facets(sh.facets) + " }" : itemDecl + ";")
            line(ind, "}")
            return
        }
        Shape sh = shape(t, null, false, td.line)
        if (sh.facets || td.annotations) {
            line(ind, "attribute def " + n + " :> " + sh.type + " {")
            defAnnotations(td, ind + 1)
            if (sh.facets) line(ind + 1, facets(sh.facets))
            line(ind, "}")
        } else {
            line(ind, "attribute def " + n + " :> " + sh.type + ";")
        }
    }

    void union(IdlUnion u, int ind) {
        line(ind, "#union attribute def " + name(u.name) + " {")
        defAnnotations(u, ind + 1)
        boolean clash = u.cases.any { it.member.decl.name == "discriminator" }
        Shape ds = shape(u.discriminator, null, false, u.line)
        line(ind + 1, "attribute " + (clash ? "discriminator_" : "discriminator") + " : " + ds.type + " { @Discriminator; }")
        u.cases.each { uc ->
            if (uc.member.type.kind == "sequence") throw new IdlException("union branches with anonymous sequences are not supported; typedef the sequence", uc.member.line)
            List<String> parts = []
            if (uc.labels) parts << "labels = (" + uc.labels.collect { str(it) }.join(", ") + ");"
            if (uc.isDefault) parts << "isDefault = true;"
            member(uc.member, ind + 1, "@Case { " + parts.join(" ") + " }")
        }
        line(ind, "}")
    }

    void interfaceDef(IdlInterface itf, int ind) {
        line(ind, "#interfaceType item def " + name(itf.name) + (itf.bases ? " :> " + itf.bases.collect { qname(it) }.join(", ") : "") + " {")
        defAnnotations(itf, ind + 1)
        List<String> raises = []
        itf.exports.each { e ->
            if (e instanceof IdlAttribute) {
                IdlAttribute a = (IdlAttribute) e
                IdlMember m = new IdlMember(type: a.type, decl: new IdlDeclarator(name: a.name), line: a.line)
                m.annotations.addAll(a.annotations)
                int before = out.length()
                member(m, ind + 1, null)
                if (a.readonly) out.insert(before + (ind + 1), "constant ")
            } else {
                IdlOperation op = (IdlOperation) e
                line(ind + 1, "abstract #operation action " + name(op.name) + " {")
                if (op.oneway) line(ind + 2, "@IdlOneway;")
                op.annotations.each { a -> line(ind + 2, "@IdlAnnotation { text = " + str(a.text()) + "; }") }
                Set<String> used = op.params.collect { it.name } as Set
                op.params.each { prm ->
                    Shape sh = shape(prm.type, null, false, op.line)
                    String decl = prm.direction + " " + name(prm.name) + " : " + sh.type + sh.multiplicity
                    line(ind + 2, sh.facets ? decl + " { " + facets(sh.facets) + " }" : decl + ";")
                }
                if (op.returnType != null) {
                    Shape sh = shape(op.returnType, null, false, op.line)
                    String rn = "result"
                    while (used.contains(rn)) rn += "_"
                    List<String> body = []
                    if (sh.facets) body << facets(sh.facets)
                    body << "@IdlReturn;"
                    line(ind + 2, "out " + rn + " : " + sh.type + sh.multiplicity + " { " + body.join(" ") + " }")
                }
                line(ind + 1, "}")
                op.raises.each { r -> raises << "#raises dependency from " + name(itf.name) + "::" + name(op.name) + " to " + qname(r) + ";" }
            }
        }
        line(ind, "}")
        raises.each { r -> line(ind, r) }
    }
}

// ---------------------------------------------------------------- Canonical IDL writer

class IdlWriter {
    IdlFile file
    IdlNames names
    StringBuilder out = new StringBuilder()

    String write(IdlFile f) {
        file = f
        names = new IdlNames(f)
        definitions(f.defs, [], 0)
        return out.toString()
    }

    void line(int ind, String text) { out.append("    " * ind).append(text).append("\n") }

    String fq(String name, List<String> scope) {
        String q = names.resolve(name, scope)
        return "::" + q
    }

    String type(IdlTypeRef t, List<String> scope) {
        switch (t.kind) {
            case "basic": return t.name
            case "string": return t.bound != null ? "string<" + t.bound + ">" : "string"
            case "wstring": return t.bound != null ? "wstring<" + t.bound + ">" : "wstring"
            case "fixed": return "fixed<" + t.digits + ", " + t.scale + ">"
            case "sequence": return "sequence<" + type(t.element, scope) + (t.bound != null ? ", " + t.bound : "") + ">"
            case "scoped": return fq(t.name, scope)
        }
        return "?"
    }

    Map<String, Object> constants = [:]

    String annotations(List<IdlAnnotation> anns) {
        List<String> order = ["key", "id", "optional", "range", "default"]
        List<IdlAnnotation> sorted = anns.findAll { it.name in order }.sort { order.indexOf(it.name) } + anns.findAll { !(it.name in order) }
        return sorted.collect { a -> canonicalText(a) + " " }.join("")
    }

    // canonical form: @range bounds as resolved numbers (the SysML model stores values, not constant names)
    String canonicalText(IdlAnnotation a) {
        if (a.name != "range") return a.text()
        Map<String, String> kv = IdlToSysml.keyValues(a)
        List<String> parts = []
        ["min", "max"].each { k ->
            if (kv[k] != null) {
                Object v = constants[kv[k]]
                parts << (k + "=" + (v instanceof Number ? v : kv[k]))
            }
        }
        return "@range(" + parts.join(", ") + ")"
    }

    String dims(IdlDeclarator d) { return d.dims.collect { "[" + it + "]" }.join("") }

    String constValue(Object v, IdlTypeRef t) {
        if (v instanceof Boolean) return v ? "TRUE" : "FALSE"
        if (v instanceof String) {
            boolean isChar = t.kind == "basic" && (t.name == "char" || t.name == "wchar")
            return isChar ? "'" + v + "'" : '"' + v + '"'
        }
        return String.valueOf(v)
    }

    void definitions(List<IdlDefinition> defs, List<String> scope, int ind) {
        defs.each { d ->
            if (d.annotations && !(d instanceof IdlTypedef)) line(ind, annotations(d.annotations).trim())
            if (d instanceof IdlModule) {
                line(ind, "module " + d.name + " {")
                definitions(((IdlModule) d).defs, scope + [d.name], ind + 1)
                line(ind, "};")
            } else if (d instanceof IdlConst) {
                IdlConst c = (IdlConst) d
                line(ind, "const " + type(c.type, scope) + " " + c.name + " = " + constValue(c.value, c.type) + ";")
            } else if (d instanceof IdlEnum) {
                line(ind, "enum " + d.name + " { " + ((IdlEnum) d).literals.join(", ") + " };")
            } else if (d instanceof IdlTypedef) {
                IdlTypedef td = (IdlTypedef) d
                line(ind, annotations(td.annotations) + "typedef " + type(td.type, scope) + " " + td.name + dims(td.decl) + ";")
            } else if (d instanceof IdlStruct) {
                IdlStruct s = (IdlStruct) d
                line(ind, "struct " + s.name + (s.base ? " : " + fq(s.base, scope) : "") + " {")
                s.members.each { m -> line(ind + 1, annotations(m.annotations) + type(m.type, scope) + " " + m.decl.name + dims(m.decl) + ";") }
                line(ind, "};")
            } else if (d instanceof IdlUnion) {
                IdlUnion u = (IdlUnion) d
                line(ind, "union " + u.name + " switch (" + type(u.discriminator, scope) + ") {")
                u.cases.each { uc ->
                    String labels = uc.labels.collect { "case " + it + ": " }.join("") + (uc.isDefault ? "default: " : "")
                    line(ind + 1, labels + annotations(uc.member.annotations) + type(uc.member.type, scope) + " " + uc.member.decl.name + dims(uc.member.decl) + ";")
                }
                line(ind, "};")
            } else if (d instanceof IdlExceptionDef) {
                IdlExceptionDef x = (IdlExceptionDef) d
                line(ind, "exception " + x.name + " {")
                x.members.each { m -> line(ind + 1, annotations(m.annotations) + type(m.type, scope) + " " + m.decl.name + dims(m.decl) + ";") }
                line(ind, "};")
            } else if (d instanceof IdlInterface) {
                IdlInterface itf = (IdlInterface) d
                line(ind, "interface " + itf.name + (itf.bases ? " : " + itf.bases.collect { fq(it, scope) }.join(", ") : "") + " {")
                itf.exports.each { e ->
                    if (e instanceof IdlAttribute) {
                        IdlAttribute a = (IdlAttribute) e
                        line(ind + 1, annotations(a.annotations) + (a.readonly ? "readonly " : "") + "attribute " + type(a.type, scope) + " " + a.name + ";")
                    } else {
                        IdlOperation op = (IdlOperation) e
                        String params = op.params.collect { p -> p.direction + " " + type(p.type, scope) + " " + p.name }.join(", ")
                        String raises = op.raises ? " raises (" + op.raises.collect { fq(it, scope) }.join(", ") + ")" : ""
                        line(ind + 1, annotations(op.annotations) + (op.oneway ? "oneway " : "") +
                            (op.returnType == null ? "void" : type(op.returnType, scope)) + " " + op.name + "(" + params + ")" + raises + ";")
                    }
                }
                line(ind, "};")
            }
        }
    }
}

// ---------------------------------------------------------------- Facade

class UML3Idl {
    static IdlFile parse(String text, String fileName) {
        return new IdlParserV1().parse(text, fileName)
    }

    static String toSysml(IdlFile f) {
        IdlToSysml e = new IdlToSysml()
        // constants for @range resolution (simple and qualified names)
        collectConstants(f.defs, [], e.parserConstants)
        return e.convert(f)
    }

    static String toIdl(IdlFile f) {
        IdlWriter w = new IdlWriter()
        collectConstants(f.defs, [], w.constants)
        return w.write(f)
    }

    private static void collectConstants(List<IdlDefinition> defs, List<String> scope, Map<String, Object> into) {
        defs.each { d ->
            if (d instanceof IdlConst) { into[d.name] = ((IdlConst) d).value; into[(scope + [d.name]).join("::")] = ((IdlConst) d).value }
            if (d instanceof IdlModule) collectConstants(((IdlModule) d).defs, scope + [d.name], into)
        }
    }
}
