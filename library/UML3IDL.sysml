library package UML3IDL {
	doc
	/*
	 * UML3IDL - OMG IDL 4.2 support for UML3.
	 *
	 * Only what SysML v2 / UML3 do not already provide. The mapping (tools/idl, docs/IDL-MAPPING.md):
	 *   module            -> package (native)
	 *   struct            -> #dataType attribute def (UML3Core), inheritance ':>'
	 *   typedef T X       -> attribute def X :> T (native alias)
	 *   typedef sequence  -> attribute def X { @IdlSequence { bound = N; } attribute items : T[0..N] ordered nonunique; }
	 *   sequence member   -> attribute m : T[0..*] ordered nonunique;   bounded: [0..N]
	 *   array member      -> attribute m : T[n1*n2] ordered nonunique { @IdlArray { dimensions = (n1, n2); } }
	 *   string<N>         -> String { @Facets { maxLength = N; } }   fixed<d,s> -> Decimal { @Facets { precision = d; scale = s; } }
	 *   enum              -> enum def (native)
	 *   union             -> #union attribute def (this package) with @Discriminator / @Case
	 *   exception         -> #exceptionType item def (UML3Core)
	 *   interface         -> #interfaceType item def (UML3Core); operations abstract #operation action
	 *   readonly attribute-> constant attribute    oneway -> @IdlOneway    return -> out result { @IdlReturn; }
	 *   raises (E)        -> #raises dependency from Interface::operation to E
	 *   const             -> constant attribute NAME : T = value; (package level)
	 *   @key -> #id  @optional -> [0..1]  @range -> @Facets  @default -> default  @id -> @IdlMemberId
	 *   any other annotation -> @IdlAnnotation { text = "@name(...)"; } (preserved for export)
	 */

	private import ScalarValues::*;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;
	private import UML3Types::*;

	/* ---------------------------------------------------------------------
	 * IDL basic types with no UML3Types equivalent
	 * --------------------------------------------------------------------- */

	attribute def Octet :> Natural {
		doc /* IDL octet: an 8-bit opaque byte (not an arithmetic uint8). */
		@Facets { bitWidth = 8; isSigned = false; minInclusive = 0; maxInclusive = 255; }
	}
	attribute def WChar :> String {
		doc /* IDL wchar: one wide character. */
		@Facets { minLength = 1; maxLength = 1; }
	}
	attribute def WString :> String {
		doc /* IDL wstring: wide-character string (bound with @Facets maxLength). */
	}
	attribute def LongDouble :> Real {
		doc /* IDL long double: extended precision floating point. */
	}
	attribute def Any :> Base::DataValue {
		doc /* IDL any: a self-describing value of any IDL type. */
	}

	/* ---------------------------------------------------------------------
	 * Union
	 * --------------------------------------------------------------------- */

	abstract attribute def Union :> DataType {
		doc
		/*
		 * IDL discriminated union. Exactly one attribute is marked @Discriminator; every other
		 * attribute is a branch with @Case { labels = ("1", "2"); } or @Case { isDefault = true; }.
		 * Branch attributes have multiplicity [0..1] (only the selected branch holds a value).
		 */
	}
	abstract attribute idlUnions : Union[0..*] nonunique :> dataTypes;

	metadata def <union> UnionMetadata :> SemanticMetadata {
		:>> baseType = idlUnions meta SysML::Usage;
	}

	metadata def Discriminator {
		doc /* Marks the discriminator attribute of a #union. */
	}

	metadata def Case {
		doc /* Case labels of a union branch; labels are IDL constant expressions as text. */
		attribute labels : String[0..*] ordered;
		attribute isDefault : Boolean default false;
	}

	/* ---------------------------------------------------------------------
	 * Collections and structural details
	 * --------------------------------------------------------------------- */

	metadata def IdlSequence {
		doc /* On a typedef'd attribute def whose single 'items' attribute holds the sequence elements. */
		attribute bound : Natural[0..1];
	}

	metadata def IdlArray {
		doc /* Array dimensions of an attribute (or of the 'items' attribute of a typedef'd array). */
		attribute dimensions : Natural[1..*] ordered nonunique;
	}

	metadata def IdlMemberId {
		doc /* Explicit member id (@id annotation). */
		attribute memberId : Natural;
	}

	metadata def IdlAnnotation {
		doc /* An IDL annotation without a UML3 mapping, preserved verbatim for export. */
		attribute text : String;
	}

	metadata def IdlFile {
		doc /* On the package that represents one IDL file. */
		attribute fileName : String;
	}

	/* ---------------------------------------------------------------------
	 * Operations
	 * --------------------------------------------------------------------- */

	metadata def IdlOneway {
		doc /* IDL oneway operation: no reply, no out parameters, no raises. */
	}

	metadata def IdlReturn {
		doc /* Marks the out parameter that carries the IDL operation's return value. */
	}

	metadata def <raises> RaisesDependency :> DependencyKind {
		doc /* IDL raises clause: dependency from an operation (client) to an #exceptionType (supplier). */
	}
}
