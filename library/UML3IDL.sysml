library package UML3IDL {
	doc
	/*
	UML3IDL: the OMG IDL 4.2 support of UML3, used to import IDL files into SysML v2 models and to
	export them again.

	IDL constructs map to native SysML v2 elements and to the keywords and types of UML3Core and
	UML3Types. This package adds only what has no equivalent there: IDL basic types, discriminated
	unions, and metadata that keeps IDL-only details so that export can reproduce the IDL. The importer
	and exporter (tools/idl, tools/cameo-scripts) are described in docs/IDL-MAPPING.md.

	Mapping, IDL -> UML3:
	  module M -> package M
	  struct S : B -> #dataType attribute def S :> B
	  typedef T X -> attribute def X :> T (an alias by specialization)
	  typedef sequence<T, N> X ->
	    attribute def X { @IdlSequence { bound = N; } attribute items : T[0..N] ordered nonunique; }
	  sequence<T> member m -> attribute m : T[0..*] ordered nonunique; bounded: T[0..N]
	  array member T m[a][b] ->
	    attribute m : T[n] ordered nonunique { @IdlArray { dimensions = (a, b); } }, where n = a * b
	  string<N>, wstring<N> -> String, WString { @Facets { maxLength = N; } }
	  fixed<d, s> -> Decimal { @Facets { precision = d; scale = s; } }
	  enum -> enum def
	  union -> #union attribute def with @Discriminator and @Case
	  exception E -> #exceptionType item def E
	  interface I : J -> #interfaceType item def I :> J, operations as abstract #operation actions
	  attribute, readonly attribute -> attribute, constant attribute
	  oneway -> @IdlOneway; return value -> out result { @IdlReturn; }
	  raises (E1, E2) -> one #raises dependency from I::op to each exception
	  const T N = v -> attribute N : T = v; at package level
	  @key -> #id; @optional -> [0..1]; @range -> @Facets; @default -> default; @id -> @IdlMemberId
	  any other annotation -> @IdlAnnotation { text = "@name(...)"; }
	IDL names that are SysML or KerML reserved words are quoted, such as 'state' and 'message'.

	Rationale: an IDL const is a bound attribute and not a 'constant' attribute, because KerML requires a
	constant feature to be variable, and a package-level feature is not variable (E08).

	Contents:
	- IDL basic types: Octet, WChar, WString, LongDouble, Any.
	- Unions: Union, idlUnions and the #union keyword, with @Discriminator and @Case.
	- Declaration details: @IdlSequence, @IdlArray, @IdlMemberId, @IdlAnnotation, @IdlFile.
	- Operations: @IdlOneway, @IdlReturn and the #raises dependency keyword.
	References: UML 2.5.1 DataType; UML 2.5.1 Interface; UML 2.5.1 Operation; KerML 8.3.3.3.4; E08; E09.
	*/

	private import ScalarValues::*;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;
	private import UML3Types::*;

	comment IdlBasicTypeDesign about Octet, WChar, WString, LongDouble, Any
		/*
		IDL basic types. Most IDL basic types map to types that already exist: short, long and long long
		(int16, int32, int64) to Int16, Int32 and Int64; their unsigned forms (uint16, uint32, uint64) to
		UInt16, UInt32 and UInt64; int8 and uint8 to Int8 and UInt8; float and double to Float32 and
		Float64; char to Char; string to String; boolean to Boolean. Octet, WChar, WString, LongDouble and
		Any have no such equivalent. Octet and WChar are separate types even though UInt8 and Char have the
		same facets, so that export writes octet and wchar again.
		References: UML 2.5.1 PrimitiveType; docs/IDL-MAPPING.md.
		*/

	attribute def Octet :> Natural {
		doc
		/*
		IDL octet: an opaque 8-bit byte that the middleware passes unchanged, not an arithmetic uint8.

		It has the facets of UInt8 but is a separate type, so it is exported as octet.
		*/
		@Facets { bitWidth = 8; isSigned = false; minInclusive = 0; maxInclusive = 255; }
	}
	attribute def WChar :> String {
		doc /* IDL wchar: one wide character; a separate type from Char, so it is exported as wchar. */
		@Facets { minLength = 1; maxLength = 1; }
	}
	attribute def WString :> String {
		doc /* IDL wstring: a wide-character string; wstring<N> adds @Facets { maxLength = N; }. */
	}
	attribute def LongDouble :> Real {
		doc /* IDL long double: an extended-precision floating point number. */
	}
	attribute def Any :> Base::DataValue {
		doc
		/*
		IDL any: a self-describing value of any IDL type.

		Any specializes Base::DataValue, so an Any value is a data value: a basic type, struct, union, enum
		or typedef value. Items, to which exceptions and interfaces map, are occurrences, and occurrences
		are disjoint from data values, so an Any cannot hold them.
		References: KerML 9.2.2; KerML 9.2.4.
		*/
	}

	comment UnionDesign about Union, idlUnions, UnionMetadata, Discriminator, Case
		/*
		Discriminated unions. The #union keyword makes an attribute def a Union, which is a UML3Core
		DataType, so a union is a value without identity, like a struct. In its body, @Discriminator marks
		the attribute whose value selects the branch, and @Case gives each branch its labels or marks the
		default branch. Branches have multiplicity [0..1] because at most one branch holds a value.
		References: UML 2.5.1 DataType; KerML 9.2.16; SysML 7.27.3.
		*/

	abstract attribute def Union :> DataType {
		doc
		/*
		IDL discriminated union: a value whose discriminator selects the branch, if any, that holds a value.

		Usage: mark exactly one attribute @Discriminator; every other attribute is a branch with
		multiplicity [0..1] and @Case { labels = (...); } or @Case { isDefault = true; }.
		  #union attribute def PaymentDetail {
		    attribute discriminator : Int32 { @Discriminator; }
		    attribute cardNumber : String[0..1] { @Case { labels = ("1"); } }
		    attribute walletId : String[0..1] { @Case { labels = ("2", "3"); } }
		    attribute none : Boolean[0..1] { @Case { isDefault = true; } }
		  }
		References: UML 2.5.1 DataType; UML3Core::DataType; SysML 7.7.
		*/
	}
	abstract attribute idlUnions : Union[0..*] nonunique :> dataTypes {
		doc /* All IDL union values; #union usages subset this feature, which subsets UML3Core dataTypes. */
	}

	metadata def <union> UnionMetadata :> SemanticMetadata {
		doc /* Keyword #union: an IDL Union (a definition specializes Union, a usage subsets idlUnions). */
		:>> baseType = idlUnions meta SysML::Usage;
	}

	metadata def Discriminator {
		doc /* Marks the discriminator of a #union: the attribute whose value selects the branch. */
	}

	metadata def Case {
		doc
		/*
		The case labels of a union branch: the branch holds the value when the discriminator equals one of
		its labels, and the default branch holds it when no label of the union matches.

		Usage: attribute walletId : String[0..1] { @Case { labels = ("2", "3"); } }
		*/
		attribute labels : String[0..*] ordered {
			doc /* The case labels in declaration order, each an IDL constant expression as text. */
		}
		attribute isDefault : Boolean default false {
			doc /* True for the default branch (IDL 'default:'). */
		}
	}

	comment IdlDeclarationDetailDesign about IdlSequence, IdlArray, IdlMemberId, IdlAnnotation, IdlFile
		/*
		Declaration details, so that nothing is lost on export. These metadata record IDL facts that the
		SysML v2 elements alone do not show: that an attribute def is a sequence typedef, the dimensions of
		an array (the multiplicity holds only their product), explicit member ids, annotations without a
		UML3 mapping, and the name of the source file. The exporter reads them to write canonical IDL.
		References: KerML 7.4.13; SysML 7.27.2; E09; docs/DESIGN.md.
		*/

	metadata def IdlSequence {
		doc
		/*
		Marks an attribute def as an IDL sequence typedef, whose single attribute 'items' holds the elements.

		Usage: typedef sequence<Sku> SkuList; is imported as
		  attribute def SkuList { @IdlSequence; attribute items : Sku[0..*] ordered nonunique; }
		A bounded typedef sequence<long, 10> gets @IdlSequence { bound = 10; } and items : Int32[0..10].
		*/
		attribute bound : Natural[0..1] {
			doc /* The bound N of sequence<T, N>, which export writes; absent for an unbounded sequence. */
		}
	}

	metadata def IdlArray {
		doc
		/*
		The array dimensions of an attribute, or of the 'items' attribute of an array typedef.

		Usage: the struct member long matrix[2][3]; is imported as
		  attribute matrix : Int32[6] ordered nonunique { @IdlArray { dimensions = (2, 3); } }
		The multiplicity gives the number of elements; the dimensions give the shape.
		*/
		attribute dimensions : Natural[1..*] ordered nonunique {
			doc /* The size of each dimension, in declaration order. */
		}
	}

	metadata def IdlMemberId {
		doc
		/*
		The explicit member id of an IDL member, from its @id(n) annotation.

		Usage: attribute orderId : String { @IdlMemberId { memberId = 1; } }
		*/
		attribute memberId : Natural {
			doc /* The member id n. */
		}
	}

	metadata def IdlAnnotation {
		doc
		/*
		An IDL annotation that has no UML3 mapping, kept as text so that export writes it again.

		Usage: the struct annotation @topic is imported as @IdlAnnotation { text = "@topic"; } in its body.
		*/
		attribute text : String {
			doc /* The annotation as IDL text: @name or @name(arguments), with spacing normalized. */
		}
	}

	metadata def IdlFile {
		doc
		/*
		Marks the root package that the importer creates for one IDL file and names after that file.

		Usage: package shop_order { @IdlFile { fileName = "shop_order.idl"; } }
		*/
		attribute fileName : String {
			doc /* The name of the IDL file, without its directory. */
		}
	}

	comment IdlOperationDesign about IdlOneway, IdlReturn, RaisesDependency
		/*
		Operations. An IDL interface operation is an abstract #operation action (UML3Core) of the
		interface, with in, out and inout parameters as in IDL. These elements carry what the action does
		not state by itself: @IdlReturn marks the out parameter that holds the return value (a void
		operation has none), @IdlOneway marks a oneway operation, and each exception in the raises clause
		is a #raises dependency from the operation to the exception.
		  abstract #operation action getOrder { in orderId : String; out result : Order { @IdlReturn; } }
		  #raises dependency from OrderService::getOrder to NotFound;
		References: UML 2.5.1 Operation; UML 2.5.1 Parameter; UML 2.5.1 Operation.raisedException; SysML 7.17.
		*/

	metadata def IdlOneway {
		doc
		/*
		Marks an IDL oneway operation: no reply, no out or inout parameters, no return value, no raises.

		Usage: abstract #operation action ping { @IdlOneway; }
		*/
	}

	metadata def IdlReturn {
		doc
		/*
		Marks the out parameter that carries the return value of an IDL operation.

		Usage: out result : Order { @IdlReturn; }
		*/
	}

	metadata def <raises> RaisesDependency :> DependencyKind {
		doc
		/*
		Keyword #raises (IDL raises clause): the client operation can raise the supplier #exceptionType.

		Usage: one dependency per exception, from the operation to the exception:
		  #raises dependency from OrderService::cancel to InvalidState;
		Rationale: SysML v2 actions have no property for the exceptions they raise, so the link is a
		dependency classified by a keyword, like the UML3Core dependency keywords.
		References: UML 2.5.1 Operation.raisedException; UML3Core::DependencyKind; SysML 7.3.
		*/
	}
}
