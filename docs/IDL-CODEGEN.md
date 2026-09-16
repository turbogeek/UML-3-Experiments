# IDL → Java and Rust code generation

UML3 generates Java and Rust source from IDL with Groovy (`tools/idl/UML3IdlCodegen.groovy`). The generators take the
IDL AST of `tools/idl/UML3IdlCore.groovy` as input, so they work the same whether the AST comes from an `.idl` file
(`UML3Idl.parse`) or from a SysML v2 model in CATIA Magic (`UML3Idl.fromModel`, see [IDL-MAPPING.md](IDL-MAPPING.md)).

```bash
groovy tools/idl/idl2code.groovy tests/idl/shop_order.idl out java rust compile
```

| Option | Output |
|---|---|
| `java` | `out/java/<package dirs>/*.java` |
| `rust` | `out/rust/lib.rs` (one library crate root) |
| `compile` | Java is compiled with the in-process `javac` (`javax.tools`, needs a JDK). `lib.rs` is compiled with `rustc --emit metadata` when `rustc` is on `PATH`, otherwise `RUSTC|SKIPPED` |

Result lines: `JAVA|OK|n`, `JAVAC|OK` / `JAVAC|FAIL|file:line: message`, `RUST|OK`, `RUSTC|OK|FAIL|SKIPPED`, then `RESULT|OK|FAIL`.
The scripts never call `System.exit`. A construct a generator cannot map gives an `IdlException` with the line number;
it is never silently dropped.

## Java: OMG IDL4 to Java Language Mapping 1.0

The generator implements [IDL4-Java 1.0](https://www.omg.org/spec/IDL4-Java/) (ptc/2019-07-02) with the default
`@java_mapping` options: `apply_naming_convention = TRUE`, `promote_integer_width = FALSE`,
`constants_container = "Constants"`, `string_type = java.lang.String`.

| IDL | Java | Clause |
|---|---|---|
| `module A { module B` | `package A.B` (names unchanged) | 7.2.2 |
| `const` | `public final class Constants` per package, `public static final`, names in ALL_UPPERCASE_SNAKE | 7.2.3 |
| integers | `int8/uint8/octet → byte`, `short/uint16 → short`, `long/uint32 → int`, `long long/uint64 → long` (unsigned wraps) | 7.2.4.1.1, 8.1.2 |
| `float`, `double`, `long double` | `float`, `double`, `java.math.BigDecimal` | 7.2.4.1.2 |
| `char`, `wchar`; `boolean` | `char`; `boolean` | 7.2.4.1.3–5 |
| `string`, `wstring` (bounded or not) | `String` | 7.2.4.2.2–3 |
| `fixed` | `java.math.BigDecimal` | 7.2.4.2.4 |
| `sequence<T>` | `java.util.List<T>` (boxed elements; see deviations) | 7.2.4.2.1 |
| array `T a[x][y]` | `T[][]`, created with the declared sizes; object elements are default-constructed | 7.2.4.4 |
| `typedef` | no Java type; each use is replaced by the aliased type, recursively (array dimensions included) | 7.2.4.6 |
| `struct S : B` | `public class S extends B implements java.io.Serializable`: private fields, `getX()`/`setX()` in PascalCase, a default constructor (strings `""`, sequences empty, arrays sized, structs `new`, enums first literal) and an all-values constructor whose first parameter is the base instance | 7.2.4.3.1, 7.14.1 |
| `enum` (with `@value`) | `public enum` with `getValue()` and `valueOf(int)` | 7.2.4.3.3 |
| `union` | `public final class`: `getDiscriminator()`; a getter per member that throws `IllegalStateException` when the member is not selected; `setX(v)` selects the first label; `setX(v, discriminator)` for members with several labels and for `default` (throws `IllegalArgumentException`); `__default()` / `__default(d)` when there is no `default` and the labels do not cover the discriminator | 7.2.4.3.2 |
| `exception` | `class E extends java.lang.RuntimeException`, members as for structs | 7.4.1 |
| `interface I : J` | `public interface I extends J`: attributes become `getX()`/`setX()` (no setter when `readonly`); operations use camelCase; `out`/`inout` use `org.omg.type.Holder<T>`; `raises` becomes `throws` | 7.4 |
| `any` | `org.omg.type.Any` (a placeholder interface is generated; its implementation is middleware-specific) | 7.3 |
| `@optional` | boxed type for basic types, `null` by default | 7.17.1 |
| `@default(v)` | value set in the default constructor | 7.17.3 |
| `@range`, `@min`, `@max` | checked in the setter, `IllegalArgumentException` | 7.17.3 |
| `@key`, `@id`, extensibility annotations | no effect on the mapping | 7.17 |

**Names (7.1.1).**
- Types use PascalCase, members and parameters camelCase, constants ALL_UPPERCASE_SNAKE.
- A Java keyword or literal gets a `_` prefix (7.1.1.1).
- A member or operation whose accessor would collide with `java.lang.Object` methods (and, in exceptions, with the `Throwable` getters) also gets the `_` prefix (7.1.2).
- Two IDL names that map to the same Java name are an error (footnote 2).

**Verification.**
- `tests/idl/codegen/naming-examples.txt`: all 34 name examples of 7.1.1.1.
- `tests/idl/codegen/java_spec_examples.idl` with `.java.expect`: the 53 Java declarations the spec shows for its examples. Every generated file must compile.

### Where the spec contradicts itself, and the choices made

| Spec text | Problem | Implementation |
|---|---|---|
| 7.1.1.1 examples `"PASCALcase" → "PASCALCase"`, `"CAMELcase" → "cAMELCase"` | They conflict with `"CAMELCase" → "cAMELCase"`, `"ALLUppercase" → "ALL_UPPERCASE"` and `"EValue" → "E_VALUE"`: an uppercase run followed by lowercase cannot start the new word both at the lowercase letter and at the last capital | New word at the last capital (satisfies 32 of 34 examples; the 2 others are recorded in the test data) |
| 7.2.4.3.1 example `setURL(String URL)` | The Camel Case rule gives `uRL` (`"CAMELCASE" → "cAMELCASE"`) | `uRL`, as the rule says |
| 7.2.4.2.1.1 `BooleanSeq`, `IntegerSeq`… interfaces | Declared as Java interfaces with constructors, which is not legal Java; `CharSeq extends List<Char>` names a class that does not exist | `java.util.List<Boolean>`, `List<Integer>`… |
| 7.4 example | Constructors inside a Java interface | No constructors in interfaces |
| 7.2.4.4 example | `Constants` field `double` for `const long` | Type of the constant (`int`) |
| 7.4.1 example | `setErrorCode()` without a parameter | Setter with the member parameter |

**Other deviations and limits.**
- Declarations outside any module go to the unnamed package (7.2.2). Java cannot reference that package from a named one, so such a reference is an error.
- `valuetype`, `bitset`, `bitmask`, `map` and annotation definitions are rejected by the parser in v1, so they generate nothing.

## Rust

OMG has no IDL to Rust mapping. The conventions follow the Rust backend of
[ic-idl](https://github.com/intercom-dds/ic-idl) (`crates/ic-codegen-rust`), with three differences:
- IDL names are not shortened (ic-idl strips suffixes and enum prefixes).
- Keywords use raw identifiers (`r#type`) instead of a trailing underscore.
- IDL facts Rust cannot express (bounds, `@key`, other annotations) are kept as `///` doc comments.

| IDL | Rust |
|---|---|
| `module a_b` | `pub mod a_b { … }`; references use absolute `crate::…` paths; reopened modules are merged |
| basic types | `bool`, `char` (char and wchar), `i8/u8` (octet `u8`), `i16/u16`, `i32/u32`, `i64/u64`, `f32`, `f64`; `long double → f64` (documented loss) |
| `string`, `wstring`, `string<N>` | `String` (bound in a doc comment) |
| `sequence<T[,N]>` | `Vec<T>` (bound in a doc comment) |
| array `T a[x][y]` | `[[T; y]; x]` |
| `fixed<d,s>` | `i128` holding the value scaled by 10^s (doc comment) |
| `typedef` | `pub type X = T;` |
| `const` | `pub const NAME: T = v;` (`&str` for strings; enum constants use the variant path) |
| `enum` (with `@value`) | `#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)] #[repr(i64)] pub enum` with explicit discriminants |
| `struct S : B` | `#[derive(Debug, Clone, PartialEq)] pub struct S { pub b_field…, pub field: T }`: base members flattened first, as Rust has no inheritance |
| `@optional` | `Option<T>` |
| `@key` and other annotations | `/// @key` doc comments |
| `union U switch (D)` | `pub enum U`: `Member(T)` for a single label, `Member(D, T)` when the member has several labels or is `default`; `impl U { pub fn discriminator(&self) -> D }` |
| `exception E` | struct plus `impl Display` and `impl std::error::Error` |
| `interface I : J` | `pub trait I: J`: `get_x(&self)`/`set_x(&mut self, value)` for attributes; operations take `&mut self`; `in` by value, `out`/`inout` as `&mut T`; `raises` of one exception gives `Result<R, E>`, several give `Result<R, Box<dyn Error>>` |
| names | types and variants PascalCase, fields, functions and modules snake_case, constants UPPER_SNAKE; Rust keywords become `r#kw` (`self`, `Self`, `super`, `crate` become `self_`…); a collision after conversion is an error |

These are not mapped (an `IdlException` names the construct):
- `any`.
- Interfaces used as data types (object references).
- References to types from other files (`#include` is not resolved).

**Verification.**
- `tests/idl/codegen/rust_mapping.idl` exercises one construct per rule, and `rust_mapping.rs.expect` lists the required lines.
- No Rust toolchain is installed on the test machine, so the Rust output has not been compiled yet. The tests compile it automatically once `rustc` is on `PATH`.

## Corpus results (tools/idl_corpus_check.py)

The generators run on every file of the IDL corpora that the importer accepts. The corpora are 701 third-party files,
held as git submodules in `external/idl`: ic-idl, rtps-gen, hdds, eProsima IDL-Parser, Cyclone DDS, GlassFish ORB and JacORB.

| Of 394 accepted files | Java (generated and compiled) | Rust (generated) |
|---|---|---|
| OK | 304 | 266 |
| Not mapped, reported with a reason | 90 | 128 |
| Crash, or Java that does not compile | 0 (invariant I5) | 0 |

The most frequent reasons for not mapping:
- A type declared in an included file (45).
- An interface base or `raises` target from another file (32).
- Rust: object references (29) and `any` (14).
- Duplicate names in the JacORB must-fail files.

Per-file results are regression-protected by `tests/idl/corpus/baseline.json` (invariant I6).
