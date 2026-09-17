library package UML3Types {
	doc
	/*
	UML3Types: sized and formatted value types for software, messaging and database models.

	The ScalarValues library gives mathematical types (Integer, Real, String, Boolean) with unbounded
	ranges, while software needs machine-sized numbers and formatted text. Each type here is an attribute
	def that specializes the closest ScalarValues type. The @Facets metadata records machine limits (bit
	width, range, length, precision, pattern) in the style of XML Schema and JSON Schema facets.
	  attribute placedAt : Timestamp;
	  attribute rating : UInt8 { @Facets { minInclusive = 1; maxInclusive = 5; } }

	Collection kinds need no new types; they are multiplicities with the ordered and nonunique keywords:
	  Set [*]    OrderedSet [*] ordered    Bag [*] nonunique    List [*] ordered nonunique
	  Optional (nullable) [0..1]
	Collections nested in collections use the KerML Collections library instead.

	Rationale: because every type specializes a ScalarValues type, all standard expressions and functions
	keep working on UML3 values.

	Contents:
	- Facets: value-space metadata (range, length, precision and scale, pattern, bit width, signedness).
	- Integer family: Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, sized by @Facets.
	- Floating point and exact decimal: Float32, Float64, Decimal, Money.
	- Text and identifiers: Char, Text, Uuid, Uri, EmailAddress, CurrencyCode, JsonText.
	- Binary and temporal text: Bytes (base64), Date, TimeOfDay, Timestamp, DurationValue (ISO 8601).
	- Generic map entry: MapEntry, bound by redefining mapKey and mapValue.
	References: UML 2.5.1 PrimitiveType; UML 2.5.1 MultiplicityElement; KerML 9.3.2; KerML 9.3.3; KerML 7.3.4.2.
	*/

	private import ScalarValues::*;

	metadata def Facets {
		doc
		/*
		Facets: restrictions on the value space of a type or of an attribute usage.

		Usage: apply it in the body of an attribute def or an attribute usage, with only the facets that apply.
		  attribute def Sku :> String { @Facets { maxLength = 32; } }
		  attribute price : Decimal { @Facets { precision = 12; scale = 2; } }

		Facets are plain metadata, not constraints: they record limits for readers and for tools such as
		the IDL importer and exporter, and model evaluation does not check values against them.

		Rationale: the names are those of XML Schema facets (minInclusive, maxInclusive, minLength,
		maxLength, pattern) and of SQL decimal types (precision, scale), so limits carry over to schemas
		and databases.
		References: UML 2.5.1 PrimitiveType; KerML 7.4.13; SysML 7.27.2.
		*/
		attribute minInclusive : Real[0..1] {
			doc /* The smallest allowed value, inclusive. */
		}
		attribute maxInclusive : Real[0..1] {
			doc /* The largest allowed value, inclusive. */
		}
		attribute minLength : Natural[0..1] {
			doc /* The smallest allowed number of characters of a text value. */
		}
		attribute maxLength : Natural[0..1] {
			doc /* The largest allowed number of characters of a text value, as in VARCHAR(n) or string<n>. */
		}
		attribute precision : Natural[0..1] {
			doc /* The total number of significant decimal digits of a decimal value. */
		}
		attribute scale : Natural[0..1] {
			doc /* The number of decimal digits after the decimal point. */
		}
		attribute pattern : String[0..1] {
			doc
			/*
			A regular expression that the whole text form of a value must match. The patterns in this
			library are anchored with ^ and $.
			*/
		}
		attribute bitWidth : Natural[0..1] {
			doc /* The number of bits of the machine representation. */
		}
		attribute isSigned : Boolean[0..1] {
			doc /* True for a signed machine representation, false for an unsigned one. */
		}
	}

	comment IntegerTypeDesign about Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64
		/*
		Integer family: fixed-width integers. Signed types specialize Integer and unsigned types specialize
		Natural, so integer arithmetic and functions apply unchanged. @Facets on each type records the bit
		width, the signedness and, up to 32 bits, the inclusive range; the 64-bit types record only bitWidth
		and isSigned, which imply the range.

		Rationale for the literal forms: CATIA Magic stores integer literals as Java int and rejects larger
		ones ("Integer number too large"), so a bound whose digits exceed 2147483647 is written as a Real
		literal in exponent form: -2.147483648E9 and 4.294967295E9. The facets are typed Real, so the values
		are the same. The LINT check of tools/check_names.py reports integer literals above 2147483647.
		References: UML 2.5.1 PrimitiveType; KerML 9.3.2; docs/DESIGN.md.
		*/

	attribute def Int8 :> Integer {
		doc /* Signed 8-bit integer, -128 to 127 (IDL int8). */
		@Facets { bitWidth = 8; isSigned = true; minInclusive = -128; maxInclusive = 127; }
	}
	attribute def Int16 :> Integer {
		doc /* Signed 16-bit integer, -32768 to 32767 (IDL short). */
		@Facets { bitWidth = 16; isSigned = true; minInclusive = -32768; maxInclusive = 32767; }
	}
	attribute def Int32 :> Integer {
		doc /* Signed 32-bit integer, -2147483648 to 2147483647 (IDL long). */
		@Facets { bitWidth = 32; isSigned = true; minInclusive = -2.147483648E9; maxInclusive = 2147483647; }
	}
	attribute def Int64 :> Integer {
		doc /* Signed 64-bit integer, -2^63 to 2^63-1 (IDL long long). */
		@Facets { bitWidth = 64; isSigned = true; }
	}
	attribute def UInt8 :> Natural {
		doc /* Unsigned 8-bit integer, 0 to 255 (IDL uint8). */
		@Facets { bitWidth = 8; isSigned = false; minInclusive = 0; maxInclusive = 255; }
	}
	attribute def UInt16 :> Natural {
		doc /* Unsigned 16-bit integer, 0 to 65535 (IDL unsigned short). */
		@Facets { bitWidth = 16; isSigned = false; minInclusive = 0; maxInclusive = 65535; }
	}
	attribute def UInt32 :> Natural {
		doc /* Unsigned 32-bit integer, 0 to 4294967295 (IDL unsigned long). */
		@Facets { bitWidth = 32; isSigned = false; minInclusive = 0; maxInclusive = 4.294967295E9; }
	}
	attribute def UInt64 :> Natural {
		doc /* Unsigned 64-bit integer, 0 to 2^64-1 (IDL unsigned long long). */
		@Facets { bitWidth = 64; isSigned = false; }
	}

	comment RealTypeDesign about Float32, Float64, Decimal, Money
		/*
		Floating point and exact decimal. Float32 and Float64 are IEEE 754 binary floating point numbers,
		which cannot represent most decimal fractions exactly. Decimal and Money are exact decimal numbers
		sized by the precision and scale facets, for amounts that must not be rounded. All four specialize
		Real, which includes positive and negative infinity but has no value for the IEEE 754 NaN.
		References: UML 2.5.1 PrimitiveType; KerML 9.3.2.
		*/

	attribute def Float32 :> Real {
		doc /* IEEE 754 binary32 floating point number (IDL float). */
		@Facets { bitWidth = 32; }
	}
	attribute def Float64 :> Real {
		doc /* IEEE 754 binary64 floating point number, double precision (IDL double). */
		@Facets { bitWidth = 64; }
	}
	attribute def Decimal :> Real {
		doc
		/*
		Exact decimal number. Set precision and scale with @Facets on a specialization or on the usage.

		Usage: attribute def Amount :> Decimal { @Facets { precision = 12; scale = 2; } }
		IDL fixed<d, s> is imported as Decimal with precision d and scale s.
		*/
	}
	attribute def Money :> Decimal {
		doc
		/*
		Monetary amount: a Decimal with precision 19 and scale 4.

		The currency is modeled separately, for example with CurrencyCode:
		  #dataType attribute def Price { attribute amount : Money; attribute currency : CurrencyCode; }
		*/
		@Facets { precision = 19; scale = 4; }
	}

	comment TextTypeDesign about Char, Text, Uuid, Uri, EmailAddress, CurrencyCode, JsonText
		/*
		Text and identifiers: String specializations whose name says what the text holds. A fixed length
		or syntax is stated with @Facets (Char, Uuid, CurrencyCode); the other types state at most a
		maximum length, and their format is given by the type and its documentation.
		References: UML 2.5.1 PrimitiveType; KerML 9.3.2.
		*/

	attribute def Char :> String {
		doc /* A single character: a String of length 1 (IDL char). */
		@Facets { minLength = 1; maxLength = 1; }
	}
	attribute def Text :> String {
		doc /* Unbounded text (SQL CLOB or TEXT). Bound it with @Facets { maxLength = n; } for VARCHAR(n). */
	}
	attribute def Uuid :> String {
		doc
		/*
		Universally unique identifier as 36-character text: hexadecimal digits in groups of 8-4-4-4-12,
		separated by hyphens (RFC 9562, formerly RFC 4122).

		Usage: #id attribute customerId : Uuid;
		*/
		@Facets { minLength = 36; maxLength = 36; pattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"; }
	}
	attribute def Uri :> String {
		doc /* A Uniform Resource Identifier as text (RFC 3986). */
	}
	attribute def EmailAddress :> String {
		doc /* An e-mail address; 254 is the longest address that the SMTP path limit allows (RFC 5321). */
		@Facets { maxLength = 254; }
	}
	attribute def CurrencyCode :> String {
		doc /* ISO 4217 alphabetic currency code: three upper-case letters, such as EUR or USD. */
		@Facets { minLength = 3; maxLength = 3; pattern = "^[A-Z]{3}$"; }
	}
	attribute def JsonText :> String {
		doc /* A serialized JSON document (RFC 8259) stored or transported as text. */
	}

	comment EncodedTextDesign about Bytes, Date, TimeOfDay, Timestamp, DurationValue
		/*
		Binary and temporal values as text: String specializations that hold a standard text encoding,
		base64 for Bytes and ISO 8601 for dates, times and durations.

		They are data formats, not physical quantities: for time in physical analysis, use the SysML Time
		and ISQ libraries. Time::Date, Time::TimeOfDay and ISQ::DurationValue have the same simple names as
		UML3Types::Date, UML3Types::TimeOfDay and UML3Types::DurationValue, so qualify the name where a
		model imports both libraries.
		References: UML 2.5.1 PrimitiveType; UML 2.5.1 Duration; KerML 9.3.2; SysML 9.8.4; SysML 9.8.8.
		*/

	attribute def Bytes :> String {
		doc
		/*
		Binary content, such as a SQL BLOB or bytea value, as base64 text.

		Rationale: it specializes String because ScalarValues has no octet-sequence type; the lexical form
		is base64, the usual form of binary content in JSON.
		*/
	}

	attribute def Date :> String {
		doc /* Calendar date as ISO 8601 text, 'YYYY-MM-DD'; the pattern checks the layout, not the calendar. */
		@Facets { pattern = "^\\d{4}-\\d{2}-\\d{2}$"; }
	}
	attribute def TimeOfDay :> String {
		doc /* Local time of day as ISO 8601 text, 'hh:mm:ss[.fff]'. */
	}
	attribute def Timestamp :> String {
		doc /* Instant in time with its UTC offset, as ISO 8601 / RFC 3339 text, e.g. '2026-09-17T14:30:00Z'. */
	}
	attribute def DurationValue :> String {
		doc /* Duration as ISO 8601 text, such as 'PT30S'. Use ISQ::duration for physical analysis. */
	}

	abstract attribute def MapEntry {
		doc
		/*
		MapEntry: a key/value pair; a map is a multi-valued attribute typed by a specialization of MapEntry.

		Usage: bind the key and value types by redefinition, then type the map attribute with the result.
		  attribute def StockEntry :> MapEntry {
		    attribute :>> mapKey : String;
		    attribute :>> mapValue : Int32;
		  }
		  attribute stockBySku : StockEntry[*];
		The multiplicity makes entries unique, not keys; unique keys need a constraint or a modeling rule.

		Rationale: binding by redefinition types the key and the value, in the template style of
		UML3Core::Template; KerML Collections::Map is the untyped alternative (key and value are Anything).
		References: UML 2.5.1 TemplateBinding; KerML 7.3.4.5; KerML 9.3.3.
		*/
		abstract attribute mapKey {
			doc /* The key of the entry; a specialization redefines it with the key type. */
		}
		abstract attribute mapValue {
			doc /* The value of the entry; a specialization redefines it with the value type. */
		}
	}
}
