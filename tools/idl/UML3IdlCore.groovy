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
                    int expStart = j
                    while (j < n && Character.isDigit(s.charAt(j))) j++
                    if (j == expStart) throw new IdlException("invalid floating-point literal '" + s.substring(i, j) + "' (exponent has no digits)", line)
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
class IdlEnum extends IdlDefinition { List<String> literals = []; Map<String, Long> values = [:] }   // values: explicit @value(n)
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
        constValues.put(c.name, c.value)
        constValues.put(qualify(c.name), c.value)
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
                case "INT": return intLiteral(x)
                case "FLOAT": return Double.parseDouble(x.text.replaceAll("[dD]\$", ""))
                case "STRING": return x.text
                case "CHAR": return x.text
                case "ID":
                    if (x.text == "TRUE") return Boolean.TRUE
                    if (x.text == "FALSE") return Boolean.FALSE
                    StringBuilder qn = new StringBuilder(x.text)
                    while (pos[0] + 1 < ts.size() && ts[pos[0]].text == "::") { qn.append("::").append(ts[pos[0] + 1].text); pos[0] += 2 }
                    Object v = constValues.get(qn.toString())
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

    static Long intLiteral(IdlToken x) {
        try {
            return x.text.toLowerCase().startsWith("0x") ? Long.parseLong(x.text.substring(2), 16) : Long.parseLong(x.text)
        } catch (NumberFormatException e) {
            throw new IdlException("integer literal '" + x.text + "' is outside the signed 64-bit range supported by v1", x.line)
        }
    }

    // a bound or array dimension: a positive integer constant expression (e.g. 10, MAX, MAX * 2)
    Long boundValue() {
        IdlToken first = peek()
        List<IdlToken> expr = []
        int depth = 0
        while (!(depth == 0 && (isPunct("]") || isPunct(">") || isPunct(",")))) {
            IdlToken x = next()
            if (x.kind == "EOF") throw new IdlException("unterminated bound", first.line)
            if (x.kind == "PUNCT" && x.text == "(") depth++
            if (x.kind == "PUNCT" && x.text == ")") depth--
            expr << x
        }
        if (expr.isEmpty()) throw new IdlException("expected a positive integer bound", first.line)
        Object v = evaluate(expr, first.line)
        if (v instanceof Long && (Long) v > 0) return (Long) v
        throw new IdlException("bound '" + expr.collect { it.text }.join(" ") + "' is not a positive integer constant", first.line)
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
        enumerator(e)
        while (isPunct(",")) { next(); enumerator(e) }
        expectPunct("}")
        return e
    }

    private void enumerator(IdlEnum e) {
        List<IdlAnnotation> anns = annotations()
        String lit = identifier()
        e.literals << lit
        IdlAnnotation v = anns.find { it.name == "value" }
        if (v != null) {
            Object n = evaluate(v.args.collect { new IdlToken(kind: it ==~ /-?\d+|0[xX][0-9a-fA-F]+/ ? "INT" : (it ==~ /[A-Za-z_].*/ ? "ID" : "PUNCT"), text: it, line: peek().line) }, peek().line)
            if (!(n instanceof Long)) throw new IdlException("@value of enumerator '" + lit + "' is not an integer constant", peek().line)
            e.values.put(lit, (Long) n)
        }
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
            byQualified.put(q, d)
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
        if (withViews) views(name(base.replaceAll(/[^A-Za-z0-9_]/, "_")), base.replaceAll(/[^A-Za-z0-9_]/, "_"), f.fileName.replaceAll(/.*[\\\/]/, ""))
        return out.toString()
    }

    // Views of the imported file, in a separate root package '<file>_views' so the IDL export (which reads the file
    // package) is unaffected: a compact and a detail class diagram of the types and interfaces, and a package
    // diagram of the modules (UML3Views; compact and detail views, E14).
    boolean withViews = true

    void views(String pkgRef, String pkg, String fileName) {
        line(0, "package " + name(pkg + "_views") + " {")
        line(1, "doc")
        line(1, "/*")
        line(1, "Views of " + fileName + ", generated by the UML3 IDL importer: compact and detail class diagrams of")
        line(1, "its types and interfaces, and a package diagram of its modules.")
        line(1, "Contents:")
        line(1, "- idlTypes (ClassDiagram): structs, unions, enumerations, exceptions and interfaces as compact boxes.")
        line(1, "- idlTypeDetails (ClassDetailDiagram): the same elements with their members and documentation.")
        line(1, "- idlModules (PackageDiagram): the IDL modules.")
        line(1, "*/")
        line(1, "private import UML3Views::*;")
        line(1, "view idlTypes : ClassDiagram {")
        line(2, "doc /* The types and interfaces of " + fileName + ", one compact box each. */")
        line(2, "expose " + pkgRef + "::**;")
        line(1, "}")
        line(1, "view idlTypeDetails : ClassDetailDiagram {")
        line(2, "doc /* The types and interfaces of " + fileName + " with their members. */")
        line(2, "expose " + pkgRef + "::**;")
        line(1, "}")
        line(1, "view idlModules : PackageDiagram {")
        line(2, "doc /* The IDL modules of " + fileName + ". */")
        line(2, "expose " + pkgRef + "::**;")
        line(1, "}")
        line(0, "}")
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
                // not 'constant': KerML requires constant features to be variable (features of occurrences);
                // a package-level attribute with a bound value ('=') is already fixed (CATIA Magic E08)
                line(ind, "attribute " + name(c.name) + " : " + sh.type + " = " + constValue(c.value, c.type) + ";")
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
        Object v = parserConstants.get(s)
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
            if (tk == ",") { if (key != null) kv.put(key, val.toString()); key = null; val.setLength(0); continue }
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
    // IDL 4.2 keywords; identifiers colliding with them (case-insensitively) must be written with the '_' escape
    static final Set<String> KEYWORDS = ("abstract any alias attribute bitfield bitmask bitset boolean case char component " +
        "connector const consumes context custom default double exception emits enum eventtype factory false finder fixed " +
        "float getraises home import in inout interface local long manages map mirrorport module multiple native object " +
        "octet oneway out primarykey private port porttype provides public publishes raises readonly setraises sequence " +
        "short string struct supports switch true truncatable typedef typeid typename typeprefix unsigned union uses " +
        "valuebase valuetype void wchar wstring int8 uint8 int16 int32 int64 uint16 uint32 uint64").split(" ") as Set
    static String id(String n) { return KEYWORDS.contains(n.toLowerCase()) ? "_" + n : n }
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
        return "::" + q.split("::").collect { id(it) }.join("::")
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
                Object v = constants.get(kv.get(k))
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
                line(ind, "module " + id(d.name) + " {")
                definitions(((IdlModule) d).defs, scope + [d.name], ind + 1)
                line(ind, "};")
            } else if (d instanceof IdlConst) {
                IdlConst c = (IdlConst) d
                line(ind, "const " + type(c.type, scope) + " " + id(c.name) + " = " + constValue(c.value, c.type) + ";")
            } else if (d instanceof IdlEnum) {
                IdlEnum en = (IdlEnum) d
                line(ind, "enum " + id(d.name) + " { " + en.literals.collect { (en.values.containsKey(it) ? "@value(" + en.values.get(it) + ") " : "") + id(it) }.join(", ") + " };")
            } else if (d instanceof IdlTypedef) {
                IdlTypedef td = (IdlTypedef) d
                line(ind, annotations(td.annotations) + "typedef " + type(td.type, scope) + " " + id(td.name) + dims(td.decl) + ";")
            } else if (d instanceof IdlStruct) {
                IdlStruct s = (IdlStruct) d
                line(ind, "struct " + id(s.name) + (s.base ? " : " + fq(s.base, scope) : "") + " {")
                s.members.each { m -> line(ind + 1, annotations(m.annotations) + type(m.type, scope) + " " + id(m.decl.name) + dims(m.decl) + ";") }
                line(ind, "};")
            } else if (d instanceof IdlUnion) {
                IdlUnion u = (IdlUnion) d
                line(ind, "union " + id(u.name) + " switch (" + type(u.discriminator, scope) + ") {")
                u.cases.each { uc ->
                    String labels = uc.labels.collect { "case " + it + ": " }.join("") + (uc.isDefault ? "default: " : "")
                    line(ind + 1, labels + annotations(uc.member.annotations) + type(uc.member.type, scope) + " " + id(uc.member.decl.name) + dims(uc.member.decl) + ";")
                }
                line(ind, "};")
            } else if (d instanceof IdlExceptionDef) {
                IdlExceptionDef x = (IdlExceptionDef) d
                line(ind, "exception " + id(x.name) + " {")
                x.members.each { m -> line(ind + 1, annotations(m.annotations) + type(m.type, scope) + " " + id(m.decl.name) + dims(m.decl) + ";") }
                line(ind, "};")
            } else if (d instanceof IdlInterface) {
                IdlInterface itf = (IdlInterface) d
                line(ind, "interface " + id(itf.name) + (itf.bases ? " : " + itf.bases.collect { fq(it, scope) }.join(", ") : "") + " {")
                itf.exports.each { e ->
                    if (e instanceof IdlAttribute) {
                        IdlAttribute a = (IdlAttribute) e
                        line(ind + 1, annotations(a.annotations) + (a.readonly ? "readonly " : "") + "attribute " + type(a.type, scope) + " " + id(a.name) + ";")
                    } else {
                        IdlOperation op = (IdlOperation) e
                        String params = op.params.collect { p -> p.direction + " " + type(p.type, scope) + " " + id(p.name) }.join(", ")
                        String raises = op.raises ? " raises (" + op.raises.collect { fq(it, scope) }.join(", ") + ")" : ""
                        line(ind + 1, annotations(op.annotations) + (op.oneway ? "oneway " : "") +
                            (op.returnType == null ? "void" : type(op.returnType, scope)) + " " + id(op.name) + "(" + params + ")" + raises + ";")
                    }
                }
                line(ind, "};")
            }
        }
    }
}

// ---------------------------------------------------------------- SysML v2 model -> IDL AST (export)
// Duck-typed over the KerML/SysML object model (CATIA Magic implementation), so it needs no CATIA Magic
// classes. API established by probes (tools/cameo-scripts/probeIdlModelApi.groovy, logs/cameo/probe-idl-api-*.txt):
//   getOwnedMember/getOwnedElement/getOwnedRelationship, getMetadataDefinition().getName(), owned features of a
//   metadata usage named after the redefined attribute holding a literal, FeatureValueImpl.getValue()/isDefault(),
//   MultiplicityRange.getLowerBound()/getUpperBound(), Literal*.getValue()/isValue(), OperatorExpression ',' for
//   sequences, Subclassification.getSuperclassifier(), Dependency.getClient()/getSupplier(), getDirection().

class IdlFromModel {
    static final Map<String, String> BASIC_BACK = [
        "Int16": "short", "UInt16": "unsigned short", "Int32": "long", "UInt32": "unsigned long", "Int64": "long long",
        "UInt64": "unsigned long long", "Int8": "int8", "UInt8": "uint8", "Float32": "float", "Float64": "double",
        "LongDouble": "long double", "Char": "char", "WChar": "wchar", "Boolean": "boolean", "Octet": "octet", "Any": "any"
    ]
    static final Map<String, String> LOSSY = ["Integer": "long long", "Natural": "unsigned long long", "Real": "double",
        "Rational": "double", "Text": "string", "Uuid": "string", "Timestamp": "string", "Date": "string", "TimeOfDay": "string",
        "DurationValue": "string", "Uri": "string", "EmailAddress": "string", "CurrencyCode": "string", "JsonText": "string",
        "Bytes": "string", "Money": "fixed"]

    List<String> warnings = []
    String filePrefix = ""
    Map<Object, List<String>> raisesByOperation = new IdentityHashMap<>()

    // ---- reflective helpers (respondsTo + fallbacks)
    // named callOn, not call: inside closures a bare call(...) resolves to Closure.call (E09 bug)
    static Object callOn(Object o, String m) {
        try { return (o != null && o.respondsTo(m)) ? o."$m"() : null } catch (Throwable t) { return null }
    }
    static List list(Object o, String m) {
        Object v = callOn(o, m)
        return v == null ? [] : (v instanceof Collection ? new ArrayList((Collection) v) : [v])
    }
    static String kind(Object o) { return o == null ? "" : o.getClass().getSimpleName().replaceAll(/Impl$/, "") }
    static String nameOf(Object o) { Object n = callOn(o, "getName"); return n == null ? null : n.toString() }
    static boolean isLibrary(Object o) { return callOn(o, "isLibraryElement") == Boolean.TRUE }

    List metadataUsages(Object e) { return list(e, "getOwnedElement").findAll { kind(it) == "MetadataUsage" } }
    static String metadataName(Object mu) { return nameOf(callOn(mu, "getMetadataDefinition")) }
    Object metadata(Object e, String defName) { return metadataUsages(e).find { metadataName(it) == defName } }
    boolean has(Object e, String defName) { return metadata(e, defName) != null }

    Object metaValue(Object mu, String feature) {
        Object f = list(mu, "getOwnedFeature").find { nameOf(it) == feature }
        if (f == null) return null
        Object expr = list(f, "getOwnedMember").find { !(kind(it).startsWith("Multiplicity")) }
        return value(expr)
    }

    Object value(Object expr) {
        if (expr == null) return null
        String k = kind(expr)
        switch (k) {
            case "LiteralInteger": return (callOn(expr, "getValue") as Number)?.longValue()
            case "LiteralRational": return (callOn(expr, "getValue") as Number)?.doubleValue()
            case "LiteralString": return callOn(expr, "getValue")?.toString()
            case "LiteralBoolean": return callOn(expr, "isValue") == Boolean.TRUE
            case "LiteralInfinity": return "*"
            case "FeatureReferenceExpression":
                Object ref = callOn(expr, "getReferent")
                return new IdlScopedValue(name: scoped(ref))
        }
        if (k.contains("OperatorExpression")) {
            String op = callOn(expr, "getOperator")?.toString()
            List args = list(expr, "getArgument")
            if (args.isEmpty()) args = list(expr, "getOperand")
            if (args.isEmpty()) args = list(expr, "getOwnedMember").findAll { kind(it).startsWith("Literal") || kind(it).contains("Expression") }
            if (op == ",") return args.collectMany { a -> def v = value(a); v instanceof List ? v : [v] }
            if (op == "-" && args.size() == 1) { def v = value(args[0]); return v instanceof Number ? -v : v }
            warnings << ("unsupported expression operator '" + op + "'")
            return null
        }
        warnings << ("unsupported expression kind " + k)
        return null
    }

    Map<String, Object> facets(Object e) {
        Map<String, Object> f = [:]
        Object mu = metadata(e, "Facets")
        if (mu != null) list(mu, "getOwnedFeature").each { feat -> f[nameOf(feat)] = metaValue(mu, nameOf(feat)) }
        return f
    }

    String scoped(Object dfn) {
        String q = callOn(dfn, "getQualifiedName")?.toString() ?: nameOf(dfn)
        if (q != null && filePrefix && q.startsWith(filePrefix)) return q.substring(filePrefix.length())
        if (!isLibrary(dfn)) warnings << ("type '" + q + "' is outside the exported package; written with its qualified name")
        return q
    }

    Object featureValue(Object u) {
        return list(u, "getOwnedRelationship").find { kind(it) == "FeatureValue" }
    }

    List<Object> bounds(Object u) {
        Object m = callOn(u, "getMultiplicity")
        if (m == null) return [1L, 1L]
        Object lo = value(callOn(m, "getLowerBound"))
        Object hi = value(callOn(m, "getUpperBound"))
        if (lo == null && hi != null) lo = hi
        if (hi == null && lo != null) hi = lo
        return [lo, hi]
    }

    // type of a definition (library basic or user-defined), with facets giving bounds / fixed digits
    IdlTypeRef typeOf(Object dfn, Map<String, Object> f) {
        String n = nameOf(dfn)
        if (dfn == null) { warnings << "untyped feature written as any"; return new IdlTypeRef(kind: "basic", name: "any") }
        if (isLibrary(dfn)) {
            if (BASIC_BACK.containsKey(n)) return new IdlTypeRef(kind: "basic", name: BASIC_BACK[n])
            if (n == "String" || n == "WString") return new IdlTypeRef(kind: n == "String" ? "string" : "wstring", bound: f.maxLength as Long)
            if (n == "Decimal") return new IdlTypeRef(kind: "fixed", digits: (f.precision ?: 31) as Integer, scale: (f.scale ?: 0) as Integer)
            if (LOSSY.containsKey(n)) {
                warnings << ("library type " + n + " has no exact IDL type; written as " + LOSSY[n])
                if (LOSSY[n] == "fixed") return new IdlTypeRef(kind: "fixed", digits: 19, scale: 4)
                if (LOSSY[n] == "string") return new IdlTypeRef(kind: "string", bound: f.maxLength as Long)
                return new IdlTypeRef(kind: "basic", name: LOSSY[n])
            }
            warnings << ("library type " + n + " has no IDL mapping; written as any")
            return new IdlTypeRef(kind: "basic", name: "any")
        }
        return new IdlTypeRef(kind: "scoped", name: scoped(dfn))
    }

    List<IdlAnnotation> parseAnnotations(String text) {
        IdlParserV1 p = new IdlParserV1()
        p.t = new IdlLexer(text).tokens
        return p.annotations()
    }

    // attribute usage / parameter -> type + declarator + annotations
    IdlMember member(Object u, boolean unionBranch) {
        Map<String, Object> f = facets(u)
        Object dfn = list(u, "getDefinition") ? list(u, "getDefinition")[0] : (list(u, "getType") ? list(u, "getType")[0] : null)
        IdlTypeRef t = typeOf(dfn, f)
        IdlMember m = new IdlMember(type: t, decl: new IdlDeclarator(name: nameOf(u)))
        List<Object> b = bounds(u)
        boolean ordered = callOn(u, "isOrdered") == Boolean.TRUE
        boolean unique = callOn(u, "isUnique") != Boolean.FALSE
        Object arr = metadata(u, "IdlArray")
        if (arr != null) {
            Object dims = metaValue(arr, "dimensions")
            m.decl.dims = (dims instanceof List ? dims : [dims]).collect { it as Long }
        } else if (b[1] == "*" || (b[1] instanceof Number && b[1] > 1) || (ordered && !unique)) {
            m.type = new IdlTypeRef(kind: "sequence", element: t, bound: b[1] == "*" ? null : (b[1] as Long))
        } else if (b[0] == 0L && b[1] == 1L && !unionBranch) {
            m.annotations << new IdlAnnotation(name: "optional")
        }
        if (has(u, "Identifier")) m.annotations << new IdlAnnotation(name: "key")
        Object mid = metadata(u, "IdlMemberId")
        if (mid != null) m.annotations << new IdlAnnotation(name: "id", args: [String.valueOf(metaValue(mid, "memberId"))])
        if (f.minInclusive != null || f.maxInclusive != null) {
            List<String> args = []
            if (f.minInclusive != null) args.addAll(["min", "=", String.valueOf(f.minInclusive)])
            if (f.maxInclusive != null) { if (args) args << ","; args.addAll(["max", "=", String.valueOf(f.maxInclusive)]) }
            m.annotations << new IdlAnnotation(name: "range", args: args)
        }
        Object fv = featureValue(u)
        if (fv != null && callOn(fv, "isDefault") == Boolean.TRUE) {
            Object v = value(callOn(fv, "getValue"))
            m.annotations << new IdlAnnotation(name: "default", args: [v instanceof Boolean ? (v ? "TRUE" : "FALSE") : String.valueOf(v)])
        }
        metadataUsages(u).findAll { metadataName(it) == "IdlAnnotation" }.each { mu ->
            m.annotations.addAll(parseAnnotations(String.valueOf(metaValue(mu, "text"))))
        }
        return m
    }

    List<IdlAnnotation> defAnnotations(Object d) {
        return metadataUsages(d).findAll { metadataName(it) == "IdlAnnotation" }.collectMany { mu -> parseAnnotations(String.valueOf(metaValue(mu, "text"))) }
    }

    List attributeUsages(Object d) { return list(d, "getOwnedMember").findAll { kind(it) == "AttributeUsage" } }

    IdlFile build(Object filePackage) {
        filePrefix = (callOn(filePackage, "getQualifiedName") ?: nameOf(filePackage)) + "::"
        Object fileMeta = metadata(filePackage, "IdlFile")
        IdlFile file = new IdlFile(fileName: fileMeta != null ? metaValue(fileMeta, "fileName") : nameOf(filePackage) + ".idl")
        file.defs = definitions(filePackage)
        file.warnings.addAll(warnings)
        return file
    }

    List<IdlDefinition> definitions(Object ns) {
        // raises dependencies owned by this namespace
        list(ns, "getOwnedElement").findAll { kind(it) == "Dependency" && list(it, "getOwnedElement").any { mu -> metadataName(mu) == "RaisesDependency" } }.each { dep ->
            list(dep, "getClient").each { client ->
                List<String> r = raisesByOperation.get(client)
                if (r == null) { r = []; raisesByOperation.put(client, r) }
                list(dep, "getSupplier").each { s -> r << scoped(s) }
            }
        }
        List<IdlDefinition> out = []
        list(ns, "getOwnedMember").each { el ->
            String k = kind(el)
            String n = nameOf(el)
            switch (k) {
                case "Package":
                    IdlModule mod = new IdlModule(kind: "module", name: n)
                    mod.defs = definitions(el)
                    out << mod
                    break
                case "AttributeUsage":
                    Object fv = featureValue(el)
                    if (fv == null || callOn(fv, "isDefault") == Boolean.TRUE) { warnings << ("package-level attribute '" + n + "' without a bound value skipped"); break }
                    IdlConst c = new IdlConst(kind: "const", name: n)
                    Object dfn = list(el, "getDefinition") ? list(el, "getDefinition")[0] : null
                    c.type = typeOf(dfn, facets(el))
                    c.value = value(callOn(fv, "getValue"))
                    out << c
                    break
                case "EnumerationDefinition":
                    IdlEnum e = new IdlEnum(kind: "enum", name: n)
                    e.literals = list(el, "getOwnedMember").findAll { kind(it) == "EnumerationUsage" }.collect { nameOf(it) }
                    out << e
                    break
                case "AttributeDefinition":
                    out << attributeDefinition(el)
                    break
                case "ItemDefinition":
                    if (has(el, "ExceptionTypeMetadata")) {
                        IdlExceptionDef x = new IdlExceptionDef(kind: "exception", name: n, annotations: defAnnotations(el))
                        x.members = attributeUsages(el).collect { member(it, false) }
                        out << x
                    } else if (has(el, "InterfaceTypeMetadata")) {
                        out << interfaceDefinition(el)
                    } else {
                        warnings << ("item def '" + n + "' is neither #exceptionType nor #interfaceType; skipped")
                    }
                    break
                case "MetadataUsage": case "Documentation": case "Comment": case "Dependency":
                    break
                default:
                    warnings << ("element '" + n + "' of kind " + k + " has no IDL mapping; skipped")
            }
        }
        return out
    }

    IdlDefinition attributeDefinition(Object d) {
        String n = nameOf(d)
        List<Object> supers = list(d, "getOwnedSubclassification").collect { callOn(it, "getSuperclassifier") }.findAll { it != null }
        if (has(d, "UnionMetadata")) {
            IdlUnion u = new IdlUnion(kind: "union", name: n, annotations: defAnnotations(d))
            attributeUsages(d).each { a ->
                if (has(a, "Discriminator")) {
                    Object dfn = list(a, "getDefinition") ? list(a, "getDefinition")[0] : null
                    u.discriminator = typeOf(dfn, facets(a))
                } else {
                    Object cs = metadata(a, "Case")
                    IdlUnionCase uc = new IdlUnionCase(member: member(a, true))
                    if (cs != null) {
                        Object labels = metaValue(cs, "labels")
                        if (labels != null) uc.labels = (labels instanceof List ? labels : [labels]).collect { String.valueOf(it) }
                        uc.isDefault = metaValue(cs, "isDefault") == Boolean.TRUE
                    }
                    u.cases << uc
                }
            }
            return u
        }
        if (has(d, "DataTypeMetadata")) {
            IdlStruct s = new IdlStruct(kind: "struct", name: n, annotations: defAnnotations(d))
            Object base = supers.find { !isLibrary(it) }
            if (base != null) s.base = scoped(base)
            s.members = attributeUsages(d).collect { member(it, false) }
            return s
        }
        IdlTypedef td = new IdlTypedef(kind: "typedef", name: n, annotations: defAnnotations(d))
        Object items = attributeUsages(d).find { nameOf(it) == "items" }
        Object seq = metadata(d, "IdlSequence")
        if (seq != null && items != null) {
            IdlMember im = member(items, false)
            IdlTypeRef el = im.type.kind == "sequence" ? im.type.element : im.type
            Object bound = metaValue(seq, "bound")
            td.type = new IdlTypeRef(kind: "sequence", element: el, bound: bound as Long)
            td.decl = new IdlDeclarator(name: n)
            return td
        }
        if (items != null && metadata(items, "IdlArray") != null) {
            IdlMember im = member(items, false)
            td.type = im.type
            td.decl = new IdlDeclarator(name: n, dims: im.decl.dims)
            return td
        }
        if (supers.isEmpty()) warnings << ("attribute def '" + n + "' has no supertype; written as typedef any")
        td.type = typeOf(supers ? supers[0] : null, facets(d))
        td.decl = new IdlDeclarator(name: n)
        return td
    }

    IdlInterface interfaceDefinition(Object d) {
        IdlInterface itf = new IdlInterface(kind: "interface", name: nameOf(d), annotations: defAnnotations(d))
        itf.bases = list(d, "getOwnedSubclassification").collect { callOn(it, "getSuperclassifier") }.findAll { it != null && !isLibrary(it) }.collect { scoped(it) }
        list(d, "getOwnedMember").each { el ->
            String k = kind(el)
            if (k == "AttributeUsage") {
                IdlMember m = member(el, false)
                itf.exports << new IdlAttribute(readonly: callOn(el, "isConstant") == Boolean.TRUE, type: m.type, name: m.decl.name, annotations: m.annotations)
            } else if (k == "ActionUsage") {
                IdlOperation op = new IdlOperation(name: nameOf(el), oneway: has(el, "IdlOneway"), annotations: defAnnotations(el))
                list(el, "getOwnedMember").findAll { callOn(it, "getDirection") != null }.each { p ->
                    IdlMember pm = member(p, false)
                    if (has(p, "IdlReturn")) { op.returnType = pm.type; return }
                    op.params << new IdlParam(direction: String.valueOf(callOn(p, "getDirection")).toLowerCase(), type: pm.type, name: pm.decl.name)
                }
                List<String> raises = raisesByOperation.get(el)
                if (raises) op.raises.addAll(raises)
                itf.exports << op
            } else if (!(k in ["MetadataUsage", "Documentation", "Comment"])) {
                warnings << ("interface member '" + nameOf(el) + "' of kind " + k + " has no IDL mapping; skipped")
            }
        }
        return itf
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

    // export: a SysML v2 package (the file package created by the importer) -> IDL AST
    static IdlFile fromModel(Object filePackage) { return new IdlFromModel().build(filePackage) }

    static String toIdl(IdlFile f) {
        IdlWriter w = new IdlWriter()
        collectConstants(f.defs, [], w.constants)
        return w.write(f)
    }

    private static void collectConstants(List<IdlDefinition> defs, List<String> scope, Map<String, Object> into) {
        defs.each { d ->
            if (d instanceof IdlConst) { into.put(d.name, ((IdlConst) d).value); into.put((scope + [d.name]).join("::"), ((IdlConst) d).value) }
            if (d instanceof IdlModule) collectConstants(((IdlModule) d).defs, scope + [d.name], into)
        }
    }
}
