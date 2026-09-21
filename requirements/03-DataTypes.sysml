package UML3DataTypeRequirements {
	doc
	/*
	DT: requirements on the value types of UML3: sized numbers and exact decimals, facets that restrict
	value spaces, text formats, temporal and binary values, enumerations, collections, maps, optional
	values, quantities with units and the basic types of OMG IDL.

	Contents:
	- Numbers: sizedNumbers, exactDecimals.
	- Value spaces: valueFacets, checkableValueSpaces.
	- Text, time and binary: textFormats, temporalLexicalForms, timeZonesAndTimeLibrary,
	  binaryAndCharacterEncodings.
	- Enumerations, collections and optional values: enumerationLiteralValues, multiplicityCollections,
	  absentVersusNull, typedMaps.
	- Quantities and interchange: quantitiesAndUnits, idlBasicTypes.
	- UseCases: how data modelers, integration engineers and systems engineers use the value types.
	- Realization: the library elements that realize the done and tbc requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/IDL-MAPPING.md; UML 2.5.1 PrimitiveType; KerML 9.3.3; SysML 9.8.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3IDL::*;

	requirement <'UML3-DT-001'> sizedNumbers {
		doc
		/*
		SysUML shall provide signed and unsigned integer types of 8, 16, 32 and 64 bits and IEEE 754 binary32 and
		binary64 floating-point types. Each type shall specialize the closest ScalarValues type and shall state
		its bit width and, for integer types, its signedness.
		Verified by: library/UML3Types.sysml; tools/run_tests.py suite idl-import; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Mathematical integers and reals are unbounded, while code, messages and databases store fixed-size numbers; specializing ScalarValues keeps the standard expressions and functions applicable."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-DT-002'> exactDecimals {
		doc
		/*
		SysUML shall provide an exact decimal type, distinct from binary floating point, whose precision and
		scale can be stated on a specialized type or on a single usage, and a monetary amount type based on it.
		Verified by: library/UML3Types.sysml; tools/run_tests.py suite idl-import.
		*/
		@Rationale { text = "Monetary and other exact amounts must not be rounded by binary floating point, and SQL DECIMAL, IDL fixed and the decimal classes of programming languages need precision and scale."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-003'> valueFacets {
		doc
		/*
		SysUML shall provide facets that record restrictions on the value space of a value type or of a single
		attribute usage: inclusive lower and upper bounds, minimum and maximum length, precision and scale, a
		pattern, bit width and signedness.
		Verified by: tools/run_tests.py suite idl-import; tools/run_tests.py suite cameo; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "Schemas, databases and IDL state limits in these terms, and recording them in the model lets importers, exporters and generators carry the limits without loss."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-004'> checkableValueSpaces {
		doc
		/*
		SysUML shall define the value space of each value type and the meaning of each facet precisely enough for
		a tool to decide whether a value conforms. The definition shall cover the regular-expression language
		of patterns, exclusive bounds, the limits of 64-bit integers and the IEEE 754 special values of
		floating-point types.
		*/
		@Rationale { text = "Limits that are only recorded cannot be checked against instance values and test data, and generators for different targets would otherwise interpret patterns, bounds and special values differently."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-005'> textFormats {
		doc
		/*
		SysUML shall provide text types for universally unique identifiers, URIs, e-mail addresses, ISO 4217
		currency codes and JSON documents. Each shall state its lexical form in a machine-readable way, as a
		pattern or as a named format that validators and schema generators recognize.
		*/
		@Rationale { text = "Identifiers and addresses are validated at system boundaries and correspond to named formats of JSON Schema and OpenAPI; a format that is only described in prose can be neither checked nor generated."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-006'> temporalLexicalForms {
		doc
		/*
		SysUML shall provide types for calendar dates, times of day, instants with a UTC offset and durations,
		each with a defined ISO 8601 or RFC 3339 lexical form.
		Verified by: library/UML3Types.sysml; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "Dates, timestamps and durations appear in almost every message and table, and their text forms must agree between producers, consumers and databases."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-DT-007'> timeZonesAndTimeLibrary {
		doc
		/*
		SysUML shall distinguish local dates and times, instants with a UTC offset and date-times in a named time
		zone. SysUML temporal types shall be convertible to the time instants and durations of the SysML v2 Time
		and ISQ libraries, and a model shall be able to use both without name conflicts.
		*/
		@Rationale { text = "Scheduling, billing and audit logic fail when local and zoned times are confused, and software in a SysML v2 system model must exchange time values with physical time analysis."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-008'> binaryAndCharacterEncodings {
		doc
		/*
		SysUML shall represent binary content as a sequence of octets distinct from text. SysUML shall state the
		character encoding of text types and the text encoding, such as base64, used when binary content is
		carried as text.
		*/
		@Rationale { text = "Treating bytes as strings and leaving character encodings implicit corrupts data at interfaces, and generators need the distinction to choose byte arrays, BLOB columns and base64 fields."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-009'> enumerationLiteralValues {
		doc
		/*
		SysUML shall express enumerations as native enumeration definitions and shall allow each literal to carry
		an explicit value, such as an integer code or a stored text, that importers, exporters and generators
		preserve.
		*/
		@Rationale { text = "Protocols, databases and IDL assign fixed codes to enumeration literals, and losing them changes the wire and storage formats."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-010'> multiplicityCollections {
		doc
		/*
		SysUML shall express optional values, sets, ordered sets, bags and lists through the multiplicity,
		ordering and uniqueness of features instead of collection types. A bounded collection shall use the
		upper bound of its multiplicity, and a fixed-size array shall record its dimensions.
		Verified by: tools/run_tests.py suite idl-import; tools/run_tests.py suite traceability; examples/01-OnlineStoreDomain.sysml.
		*/
		@Rationale { text = "KerML multiplicity already has the semantics of the UML collection kinds, and separate collection types would give two ways to say the same thing."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-011'> absentVersusNull {
		doc
		/*
		SysUML shall define whether and how a model distinguishes a value that is absent from a value that is
		present and null, for the target formats that make this distinction.
		*/
		@Rationale { text = "KerML treats null as an empty sequence of values, so a multiplicity of 0..1 cannot tell a missing JSON property from an explicit null, which some APIs and update protocols rely on."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-DT-012'> typedMaps {
		doc
		/*
		SysUML shall express maps whose entries associate a key of one type with a value of another type, with
		at most one entry for each key, and shall relate them to the Map data type of the KerML Collections
		library.
		*/
		@Rationale { text = "Dictionaries are a basic structure of APIs, messages and code, and a map model that admits duplicate keys has no counterpart in target languages and schemas."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-013'> quantitiesAndUnits {
		doc
		/*
		SysUML shall use the quantities and units of the SysML v2 ISQ and SI libraries instead of defining its
		own. A quantity-valued attribute shall be able to state the unit and the sized numeric type that
		represent its value in software.
		*/
		@Rationale { text = "Unit mistakes are a classic cause of software failures, and code, messages and databases store a quantity as a number of a fixed type in a fixed unit, which the model has to state."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DT-014'> idlBasicTypes {
		doc
		/*
		SysUML shall provide the OMG IDL 4.2 basic types that its other value types do not cover, namely octet,
		wide character, wide string, long double and any, and shall map every IDL basic type to a SysUML or
		ScalarValues type.
		Verified by: tools/run_tests.py suite idl-import; tools/run_tests.py suite idl-corpus; docs/IDL-MAPPING.md.
		*/
		@Rationale { text = "IDL is the interface language of DDS and CORBA systems, and a lossless mapping of its basic types is the precondition for IDL import, export and code generation."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how data modelers, integration engineers and systems engineers use the SysUML value types.

		Contents:
		- DefineSoftwareValueTypes: a data modeler defines the value types of a domain.
		- MapValuesToExternalFormats: an integration engineer maps values to IDL, JSON, Avro and SQL.
		- RepresentQuantitiesInSoftware: engineers agree how physical and time quantities are represented.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DefineSoftwareValueTypes {
			doc
			/*
			A data modeler defines the value types of a domain: sized numbers, exact amounts, constrained text
			and identifiers, temporal values, enumerations with codes, collections and maps, reusing the SysUML
			types and restricting them with facets.
			*/
			subject environment : UML3Environment;
			actor modeler : DataModeler;
			objective {
				doc /* Every attribute has a value type precise enough to generate code, schemas and columns. */
			}
		}

		use case def MapValuesToExternalFormats {
			doc
			/*
			An integration engineer maps the values of a model to external formats such as IDL, JSON, Avro and
			SQL: checks values against their facets, chooses binary and character encodings, handles time
			zones and absent or null values, and imports and exports IDL types.
			*/
			subject environment : UML3Environment;
			actor integrator : IntegrationEngineer;
			objective {
				doc /* Values cross system boundaries without loss of range, precision, encoding, time zone or presence. */
			}
		}

		use case def RepresentQuantitiesInSoftware {
			doc
			/*
			A systems engineer and a software developer agree how the physical and time quantities of a SysML v2
			system model are represented in software: unit, numeric type and time scale.
			*/
			subject environment : UML3Environment;
			actor systemsEngineer : SystemsEngineer;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* System and software models share quantities with explicit units and representations. */
			}
		}

		#traces dependency from DefineSoftwareValueTypes to 'UML3-DT-001', 'UML3-DT-002', 'UML3-DT-003', 'UML3-DT-005',
			'UML3-DT-006', 'UML3-DT-009', 'UML3-DT-010', 'UML3-DT-012';
		#traces dependency from MapValuesToExternalFormats to 'UML3-DT-001', 'UML3-DT-003', 'UML3-DT-004', 'UML3-DT-007',
			'UML3-DT-008', 'UML3-DT-011', 'UML3-DT-014';
		#traces dependency from RepresentQuantitiesInSoftware to 'UML3-DT-001', 'UML3-DT-006', 'UML3-DT-007',
			'UML3-DT-013';
	}

	package Realization {
		doc
		/*
		Realization: the SysUML and SysML v2 library elements that realize the done and tbc DT requirements.

		Contents:
		- #realizes dependencies from library elements to DT requirements.
		*/
		#realizes dependency from UML3Types::Int8 to 'UML3-DT-001';
		#realizes dependency from UML3Types::Int16 to 'UML3-DT-001';
		#realizes dependency from UML3Types::Int32 to 'UML3-DT-001';
		#realizes dependency from UML3Types::Int64 to 'UML3-DT-001';
		#realizes dependency from UML3Types::UInt8 to 'UML3-DT-001';
		#realizes dependency from UML3Types::UInt16 to 'UML3-DT-001';
		#realizes dependency from UML3Types::UInt32 to 'UML3-DT-001';
		#realizes dependency from UML3Types::UInt64 to 'UML3-DT-001';
		#realizes dependency from UML3Types::Float32 to 'UML3-DT-001';
		#realizes dependency from UML3Types::Float64 to 'UML3-DT-001';
		#realizes dependency from UML3Types::Decimal to 'UML3-DT-002';
		#realizes dependency from UML3Types::Money to 'UML3-DT-002';
		#realizes dependency from UML3Types::Facets to 'UML3-DT-003';
		#realizes dependency from UML3Types::Date to 'UML3-DT-006';
		#realizes dependency from UML3Types::TimeOfDay to 'UML3-DT-006';
		#realizes dependency from UML3Types::Timestamp to 'UML3-DT-006';
		#realizes dependency from UML3Types::DurationValue to 'UML3-DT-006';
		#realizes dependency from SysML::MultiplicityRange to 'UML3-DT-010';
		#realizes dependency from UML3IDL::IdlArray to 'UML3-DT-010';
		#realizes dependency from UML3IDL::Octet to 'UML3-DT-014';
		#realizes dependency from UML3IDL::WChar to 'UML3-DT-014';
		#realizes dependency from UML3IDL::WString to 'UML3-DT-014';
		#realizes dependency from UML3IDL::LongDouble to 'UML3-DT-014';
		#realizes dependency from UML3IDL::Any to 'UML3-DT-014';
	}
}
