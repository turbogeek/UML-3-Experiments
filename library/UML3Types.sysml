library package UML3Types {
	doc
	/*
	 * UML3Types - software primitive types and value facets.
	 *
	 * SysML v2 ScalarValues gives mathematical types (Integer, Real, String, Boolean)
	 * with unbounded ranges. Software, messaging and database models need sized and
	 * formatted types. Each type here specializes the closest ScalarValues type, so
	 * all standard expressions and functions keep working. Machine-level limits are
	 * recorded with the @Facets metadata (XSD/JSON-Schema style facets).
	 *
	 * Collection kinds use native SysML multiplicity modifiers (no new types needed):
	 *   Set  = [*]                   OrderedSet = [*] ordered
	 *   Bag  = [*] nonunique         List/Seq   = [*] ordered nonunique
	 *   Optional / nullable = [0..1]
	 */

	private import ScalarValues::*;

	/* ---------------------------------------------------------------------
	 * Facets: constraints on the value space of a type or an attribute usage
	 * --------------------------------------------------------------------- */

	metadata def Facets {
		doc
		/*
		 * Value-space restrictions. Apply inside a definition or usage body, e.g.
		 *   attribute price : Decimal { @Facets { precision = 12; scale = 2; } }
		 */
		attribute minInclusive : Real[0..1];
		attribute maxInclusive : Real[0..1];
		attribute minLength : Natural[0..1];
		attribute maxLength : Natural[0..1];
		attribute precision : Natural[0..1];
		attribute scale : Natural[0..1];
		attribute pattern : String[0..1];
		attribute bitWidth : Natural[0..1];
		attribute isSigned : Boolean[0..1];
	}

	/* ---------------------------------------------------------------------
	 * Integer family
	 * --------------------------------------------------------------------- */

	attribute def Int8 :> Integer {
		@Facets { bitWidth = 8; isSigned = true; minInclusive = -128; maxInclusive = 127; }
	}
	attribute def Int16 :> Integer {
		@Facets { bitWidth = 16; isSigned = true; minInclusive = -32768; maxInclusive = 32767; }
	}
	attribute def Int32 :> Integer {
		@Facets { bitWidth = 32; isSigned = true; minInclusive = -2147483648; maxInclusive = 2147483647; }
	}
	attribute def Int64 :> Integer {
		@Facets { bitWidth = 64; isSigned = true; }
	}
	attribute def UInt8 :> Natural {
		@Facets { bitWidth = 8; isSigned = false; minInclusive = 0; maxInclusive = 255; }
	}
	attribute def UInt16 :> Natural {
		@Facets { bitWidth = 16; isSigned = false; minInclusive = 0; maxInclusive = 65535; }
	}
	attribute def UInt32 :> Natural {
		@Facets { bitWidth = 32; isSigned = false; minInclusive = 0; maxInclusive = 4294967295; }
	}
	attribute def UInt64 :> Natural {
		@Facets { bitWidth = 64; isSigned = false; }
	}

	/* ---------------------------------------------------------------------
	 * Floating point and exact decimal
	 * --------------------------------------------------------------------- */

	attribute def Float32 :> Real {
		doc /* IEEE 754 binary32. */
		@Facets { bitWidth = 32; }
	}
	attribute def Float64 :> Real {
		doc /* IEEE 754 binary64 (double). */
		@Facets { bitWidth = 64; }
	}
	attribute def Decimal :> Real {
		doc /* Exact decimal number. Set precision/scale with @Facets on the usage or a subtype. */
	}
	attribute def Money :> Decimal {
		doc /* Monetary amount (currency is modeled separately, e.g. with CurrencyCode). */
		@Facets { precision = 19; scale = 4; }
	}

	/* ---------------------------------------------------------------------
	 * Text and identifiers
	 * --------------------------------------------------------------------- */

	attribute def Char :> String {
		@Facets { minLength = 1; maxLength = 1; }
	}
	attribute def Text :> String {
		doc /* Unbounded text (CLOB / TEXT). Bound with @Facets { maxLength = n; } for VARCHAR(n). */
	}
	attribute def Uuid :> String {
		@Facets { minLength = 36; maxLength = 36; pattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"; }
	}
	attribute def Uri :> String;
	attribute def EmailAddress :> String {
		@Facets { maxLength = 254; }
	}
	attribute def CurrencyCode :> String {
		doc /* ISO 4217 alphabetic code. */
		@Facets { minLength = 3; maxLength = 3; pattern = "^[A-Z]{3}$"; }
	}
	attribute def JsonText :> String {
		doc /* A serialized JSON document stored or transported as text. */
	}

	/* ---------------------------------------------------------------------
	 * Binary and temporal
	 * --------------------------------------------------------------------- */

	attribute def Bytes :> String {
		doc
		/*
		 * Binary content (BLOB / bytea / base64 in JSON). Specializes String because
		 * ScalarValues has no octet-sequence type; the lexical form is base64.
		 */
	}

	attribute def Date :> String {
		doc /* Calendar date, ISO 8601 'YYYY-MM-DD'. */
		@Facets { pattern = "^\\d{4}-\\d{2}-\\d{2}$"; }
	}
	attribute def TimeOfDay :> String {
		doc /* Local time of day, ISO 8601 'hh:mm:ss[.fff]'. */
	}
	attribute def Timestamp :> String {
		doc /* Instant in time with offset, ISO 8601 / RFC 3339. */
	}
	attribute def DurationValue :> String {
		doc /* ISO 8601 duration, e.g. 'PT30S'. Use ISQ::duration for physical analysis. */
	}

	/* ---------------------------------------------------------------------
	 * Generic map entry (template-style: bind by redefinition)
	 * --------------------------------------------------------------------- */

	abstract attribute def MapEntry {
		doc
		/*
		 * Key/value pair. A Map is 'attribute m : MyEntry[*]' where
		 *   attribute def MyEntry :> MapEntry { attribute :>> mapKey : String; attribute :>> mapValue : Int32; }
		 */
		abstract attribute mapKey;
		abstract attribute mapValue;
	}
}
