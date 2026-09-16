# OMG IDL 4.2 ↔ UML3 (SysML v2) mapping

UML3 imports and exports OMG IDL with Groovy. The IDL constructs are carried by native SysML v2 elements plus the
UML3 keywords from `UML3Core`/`UML3Types`. `library/UML3IDL.sysml` adds only what has no existing equivalent:
a few basic types, unions, and metadata that preserves IDL-only details so that export can reproduce them.

## Tools

| Piece | Where it runs | What it does |
|---|---|---|
| `tools/idl/UML3IdlCore.groovy` | anywhere (pure Groovy, no MagicDraw classes) | lexer, parser, IDL → SysML emitter, canonical IDL writer, duck-typed model → IDL reader. Facade `UML3Idl.parse / toSysml / fromModel / toIdl` |
| `tools/idl/idl2sysml.groovy` | command line | `groovy tools/idl/idl2sysml.groovy in.idl out.sysml [canonical.idl]`; also checks that IDL → canonical → canonical is stable (`ROUNDTRIP|STABLE`) |
| `tools/cameo-scripts/importIdl.groovy` | CATIA Magic (harness `/run-script` or macro console) | converts the IDL and builds it into the open project as **one undoable command** ("UML3 IDL Import"); a build error cancels the whole session |
| `tools/cameo-scripts/exportIdl.groovy` | CATIA Magic | reads a root package of the project (read-only, no session) and writes IDL |
| `tools/idl/UML3IdlCodegen.groovy`, `tools/idl/idl2code.groovy` | anywhere | IDL AST → Java (OMG IDL4-Java 1.0) and Rust; see [IDL-CODEGEN.md](IDL-CODEGEN.md) |

The Cameo scripts read a request file in the harness scripts directory:

```text
# uml3-idl-request.txt                      # uml3-idl-export-request.txt
idl=E:/.../tests/idl/shop_order.idl          package=shop_order
core=E:/.../tools/idl/UML3IdlCore.groovy     core=E:/.../tools/idl/UML3IdlCore.groovy
sysmlOut=E:/.../logs/idl/cameo-x.sysml       idlOut=E:/.../logs/idl/cameo-export-x.idl
```

If they run outside CATIA Magic, both scripts detect it and work on the IDL fixture instead: conversion only, or a writer demo.
Output is line-oriented (`MODE|`, `DIAG|`, `WARN|`, `RESULT|OK|…`, `RESULT|FAIL|…`), and the scripts never call `System.exit`.

The imported file becomes a root package named after the file (`shop_order`), annotated with `@IdlFile`. IDL modules are nested packages inside it.

## Mapping (v1 scope)

| IDL | UML3 / SysML v2 | Notes |
|---|---|---|
| `module M` | `package M` | native |
| `struct S : B` | `#dataType attribute def S :> B` | members are attribute usages |
| `typedef T X` | `attribute def X :> T` | alias by specialization |
| `typedef sequence<T[,N]> X` | `attribute def X { @IdlSequence { bound = N; } attribute items : T[0..N] ordered nonunique; }` | |
| member `sequence<T[,N]> m` | `attribute m : T[0..*]` / `[0..N]` `ordered nonunique` | |
| array `T m[a][b]` | `attribute m : T[a*b] ordered nonunique { @IdlArray { dimensions = (a, b); } }` | |
| `string<N>`, `wstring<N>` | `String` / `WString` `{ @Facets { maxLength = N; } }` | |
| `fixed<d,s>` | `Decimal { @Facets { precision = d; scale = s; } }` | |
| `enum` | `enum def` | native |
| `union U switch (D)` | `#union attribute def U`; `attribute discriminator : D { @Discriminator; }`; each branch `[0..1] { @Case { labels = (...); } }` or `@Case { isDefault = true; }` | `Union :> DataType` in UML3IDL |
| `exception E` | `#exceptionType item def E` | |
| `interface I : J` | `#interfaceType item def I :> J` | |
| `attribute T a` / `readonly attribute` | `attribute a : T` / `constant attribute a : T` | |
| operation | `abstract #operation action op { in/out/inout params; out result : T { @IdlReturn; } }` | `void` has no result |
| `oneway` | `@IdlOneway` in the operation | |
| `raises (E1, E2)` | `#raises dependency from I::op to E1;` (one per exception) | `RaisesDependency :> DependencyKind` |
| `const T N = v` | package-level `attribute N : T = v;` | **not** `constant` (see below) |
| `@key` | `#id` | |
| `@optional` | multiplicity `[0..1]` | |
| `@range(min, max)` | `@Facets { minInclusive; maxInclusive; }` | constant references are resolved to values |
| `@value(n)` on an enumerator | kept in the IDL AST, canonical IDL, Java and Rust | not yet carried in the SysML model |
| `@default(v)` | `default v` | |
| `@id(n)` | `@IdlMemberId { memberId = n; }` | |
| any other annotation | `@IdlAnnotation { text = "@name(...)"; }` | kept verbatim for export |

Basic types: `short/long/long long` → `Int16/Int32/Int64`; `unsigned …` and `uint8…uint64` → `UInt8…UInt64`;
`int8` → `Int8`; `float/double` → `Float32/Float64`; `long double` → `LongDouble`; `boolean` → `Boolean`;
`char/string` → `String`; `octet` → `Octet`; `wchar` → `WChar`; `wstring` → `WString`; `any` → `Any`.

Names that are SysML/KerML reserved words are quoted (`'state'`, `'message'`), and export unquotes them.

### Why `const` is not `constant`
CATIA Magic's `validateFeatureConstantIsVariable` requires a `constant` feature to be *variable*, i.e. owned by an occurrence type. A package-level feature is not variable, so `constant attribute` there is invalid (experiment E08: 4 errors on the first import). `check_rules.py` rule **R14** reports it.

## Export: canonical IDL

The exporter does not reproduce the original text. It writes **canonical IDL**: fully qualified type names, constant references in annotations resolved to values, quoted char constants, and a fixed member order and layout. The round-trip test therefore compares the IDL exported from the model with the canonical form of the original file (`idl2sysml.groovy … canonical.idl`), and requires them to be identical.

## Not supported in v1 (import fails with a clear message)

`tests/idl/unsupported/` holds one file per construct; `expected-errors.txt` lists the required message.

| Construct | Message |
|---|---|
| `valuetype` | unsupported IDL construct 'valuetype' |
| `map<K,V>` | unsupported IDL construct 'map' |
| `sequence<sequence<T>>` (anonymous nested) | anonymous nested sequence (use a typedef) |
| `<<`, `>>` in constant expressions | unsupported operator '<<' in constant expression |
| types declared inside an interface | type declarations inside an interface |

Also rejected with `unsupported IDL construct`: `eventtype`, `component`, `home`, `native`, `bitset`, `bitmask`, `Object`, `ValueBase`, `context`, and `raises` on attributes. Preprocessor directives (`#include`, `#pragma`, …) are ignored with a `WARN`; includes are not resolved.

## Third-party IDL corpora (E10)

The importer is tested against 701 IDL files from seven projects, held as shallow git submodules in `external/idl`
(`git submodule update --init --depth 1`). Sources, licenses and the known-invalid directories are listed in
`tests/idl/corpus/expectations.json`. `tools/idl_corpus_check.py` runs everything in one JVM (about 30 s), and
`tests/idl/corpus/baseline.json` records the outcome of each file.

| Outcome | Files | Meaning |
|---|---|---|
| ACCEPT | 394 | parsed, SysML emitted, stable canonical round trip |
| UNSUPPORTED | 160 | out-of-scope construct named in the message (`valuetype` 44, `Object` 19, `import` 19, `bitmask` 16, `map` 16, `typeprefix` 15, ...) |
| REJECT | 147 | syntax the v1 parser does not accept (types inside interfaces, vendor extensions such as `enum { A = 1 }`, C code in Cyclone's xtests) |
| CRASH / TIMEOUT | 0 | invariant I1 |

The known-invalid files (JacORB `compiler/fail`, ic-hir `tests/fail`) are rejected only in 14 of 39 cases, because v1
has no semantic checks. The other 25 are recorded as known leniency. The first run (E10, predictions in
`tests/idl/corpus/e10-predictions.json`) found 3 crashes on invalid literals, an unstable round trip for IDL
keywords used as names, and bounds that did not accept constant expressions. All three are fixed, with regression
fixtures in `tests/idl`. Code generation found a Groovy trap that affects this code: `map["Empty"]` returns
`isEmpty()`, `map["properties"]` returns the map, and `map["properties"] = v` throws. Maps keyed by IDL names
therefore use `get`/`put` (`tests/idl/groovy_map_keys.idl`).

## Verification

| Check | Result |
|---|---|
| `run_tests.py` suite `idl-import` | `shop_order.idl` → SysML contains every line of `tests/idl/shop_order.expect`; canonical round trip is stable; every unsupported fixture fails with its expected message |
| `run_tests.py` suite `idl-corpus` | invariants I1–I6 over the 701 corpus files (no crash, stable round trips, no regressions, generated Java compiles) |
| `run_tests.py` suite `idl-codegen` | spec naming examples, spec Java declarations, Rust mapping fixture, compilation |
| `cameo_check.py --idl` (in `run_tests.py --cameo`) | CATIA Magic import: 0 build errors, 1 undoable command; validation engine: 0 failures on `shop_order`; export from the live model is **identical** to the canonical original; the guarded undo removes the import |
