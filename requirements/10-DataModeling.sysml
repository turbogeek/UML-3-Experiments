package UML3DataModelingRequirements {
	doc
	/*
	DATA: requirements on data modeling with SysUML: conceptual, logical and physical data models, keys and
	constraints, relationships and cardinality, mapping between levels, schema evolution, data governance,
	non-relational models and lineage.

	Contents:
	- Logical and conceptual models: logicalDataModel, conceptualDataModel, relationshipCardinality.
	- Keys and physical schemas: keysAndIndexes, foreignKeys, physicalSchema, schemaConstraints.
	- Mapping between levels: levelMapping, mappingConsistency.
	- Evolution and design intent: schemaEvolution, normalizationIntent.
	- Governance and beyond relational: dataGovernance, nonRelationalModels, dataLineage.
	- UseCases: how data modelers, DevOps and security engineers use these capabilities.
	- Realization: the library elements that realize the done and tbc requirements.
	Value types and facets are DT requirements; security classification rules are SEC requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; SysML 7.13; SysML 7.21; SysML 7.27.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Data::*;

	requirement <'UML3-DATA-001'> logicalDataModel {
		doc
		/*
		SysUML shall provide entities (business objects with identity and a lifecycle), aggregate roots and value
		objects for logical data models, and marking an element with one of them shall make it specialize the
		corresponding library base. Attributes that are not persisted shall be markable as transient. SysUML tooling
		shall report an entity or aggregate root that has no identity.
		Verified by: tests/cameo/implied-specializations.json; tests/cameo/view-predictions.json; tools/run_tests.py suite cameo; tests/rules/r02-entity-without-identity.sysml; tools/run_tests.py suite rules-tests.
		*/
		@Rationale { text = "Entity-relationship and domain-driven design concepts are the basis of software data design and have no SysML v2 equivalent."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-002'> conceptualDataModel {
		doc
		/*
		SysUML shall support conceptual data models of business concepts and their relationships that need no
		attributes, keys or types. A tool shall be able to tell to which level (conceptual, logical or physical) a
		data model element belongs, and a logical element shall be traceable to the conceptual element it refines.
		*/
		@Rationale { text = "Conceptual models are agreed with the business before logical design; today a conceptual entity would be an entity without identity, which the identity rule reports as a defect."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-DATA-003'> relationshipCardinality {
		doc
		/*
		SysUML shall provide relationships between entities whose end multiplicities state the cardinality (one to
		one, one to many, many to many) and which may own attributes. SysUML tooling shall warn about a relationship
		that does not have exactly two ends.
		Verified by: tests/rules/r04-ternary-association.sysml; tools/run_tests.py suite rules-tests; tests/cameo/view-predictions.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Cardinality decides keys and join tables; using native end multiplicities avoids a second, inconsistent way to state it."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-004'> keysAndIndexes {
		doc
		/*
		SysUML shall let attributes and columns be marked as primary key (several marked features forming a composite
		key, with a key generation strategy), as unique or as indexed, and shall let a table or entity declare named
		indexes over several columns. SysUML tooling shall report a table without a primary key.
		Verified by: tests/rules/r01-table-without-pk.sysml; tools/run_tests.py suite rules-tests; tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Keys and indexes define identity, integrity and access paths; key features must be queryable as sets to generate schemas and check designs."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-005'> foreignKeys {
		doc
		/*
		A reference between entities and a column of a table shall be markable as a foreign key with referential
		actions on delete and on update (no action, restrict, cascade, set null, set default). SysUML tooling shall
		report a foreign key reference whose target is not an entity or table, and a foreign key column that names
		a table that does not exist.
		Verified by: tests/rules/r03-foreign-keys.sysml; tools/run_tests.py suite rules-tests; tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Referential integrity and its actions are part of every relational design and must be stated in the model to generate correct DDL."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-006'> physicalSchema {
		doc
		/*
		SysUML shall provide databases, tables, columns with physical details (column name, SQL type and default
		value) and database views with their query text and materialization. SysUML tooling shall warn about a
		database view without query text.
		Verified by: tests/rules/r11-dbview-without-query.sysml; tools/run_tests.py suite rules-tests; tests/cameo/view-predictions.json; tests/cameo/implied-specializations.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Physical schemas are what databases run; modeling them next to the logical model keeps both in one verifiable place."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-007'> schemaConstraints {
		doc
		/*
		SysUML shall let a physical schema declare named primary key, foreign key, unique and check constraints over
		one or more columns, including composite foreign keys. Referenced tables, referenced columns and indexed
		columns shall be model references, not text, so that renaming an element keeps constraints valid.
		*/
		@Rationale { text = "Referenced tables, columns and index columns are strings today and a composite foreign key cannot be expressed, so constraints break silently on renames and some schemas cannot be modeled."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-008'> levelMapping {
		doc
		/*
		A physical table, database view or column shall be traceable to the logical entity or attribute it
		implements through a mapping dependency, and tools shall be able to select these mappings.
		Verified by: examples/04-OnlineStoreDatabase.sysml; tests/cameo/view-predictions.json; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Mappings keep logical and physical models aligned; table to entity mappings are verified in a view, while column to attribute mappings are allowed but neither exemplified nor tested."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-009'> mappingConsistency {
		doc
		/*
		SysUML tooling shall report logical entities and attributes that no physical element implements, mapped
		columns whose type or multiplicity does not match the attribute they implement, and mapping dependencies
		whose client is not a physical element or whose supplier is not a logical element.
		*/
		@Rationale { text = "Mappings that are not checked drift as either model changes, and the drift is found only when generated schemas and code disagree."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-DATA-010'> schemaEvolution {
		doc
		/*
		A data model shall carry a schema version, and SysUML shall let migrations be modeled as ordered changes from
		one schema version to the next, each stating whether it is backward compatible and how existing data is
		transformed.
		*/
		@Rationale { text = "Every production schema evolves; without versions and migrations in the model, generated schemas cannot be applied safely to existing databases."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-DATA-011'> dataGovernance {
		doc
		/*
		Entities, attributes, tables and columns shall be able to state their data owner, data steward, retention
		period and disposal rule, and whether changes to them are audited. Tools shall be able to list the elements
		governed by each owner and each retention rule.
		*/
		@Rationale { text = "Data management practice and regulation require ownership and retention to be known per data element; SysUML provides only the audited marker today."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-DATA-012'> normalizationIntent {
		doc
		/*
		SysUML shall let a logical or physical model state the normal form it is designed to, and shall let each
		deliberate denormalization (a duplicated attribute, a precomputed aggregate or a merged table) name the
		elements it duplicates and give its rationale.
		*/
		@Rationale { text = "Reviewers cannot tell an intended denormalization from a design error unless the intent is recorded next to the duplicated data."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-DATA-013'> nonRelationalModels {
		doc
		/*
		SysUML shall support document, key-value, wide-column and graph data models: collections of documents with
		embedded and referenced sub-documents, partition and sort keys, time to live, and nodes and edges with
		properties, each mappable from logical entities in the same way as relational schemas.
		*/
		@Rationale { text = "Many services persist data in non-relational stores; a data modeling standard limited to tables cannot describe them or map them to the logical model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-DATA-014'> dataLineage {
		doc
		/*
		A derived data element (a column, a database view column, a message field or a report field) shall be able
		to state the source data elements it is derived from and the transformation that derives it, so that tools
		can compute its lineage end to end and the impact of changing a source.
		*/
		@Rationale { text = "Lineage answers where data comes from and what a change breaks; data integration and governance depend on it."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	package UseCases {
		doc
		/*
		UseCases: how data modelers, DevOps engineers and security engineers use SysUML data modeling.

		Contents:
		- DesignLayeredDataModels: a data modeler designs conceptual, logical and physical models and maps them.
		- EvolveDatabaseSchemas: a data modeler and a DevOps engineer version a schema and migrate databases.
		- GovernEnterpriseData: a data modeler and a security engineer state ownership, retention, lineage and
		  classification of data.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DesignLayeredDataModels {
			doc
			/*
			A data modeler captures business concepts, refines them into entities, aggregates, value objects and
			relationships with keys, designs the relational or non-relational physical schema with constraints and
			indexes, records deliberate denormalizations, and maps every physical element to the logical element it
			implements.
			*/
			subject environment : UML3Environment;
			actor modeler : DataModeler;
			objective {
				doc /* Each data model level is complete, consistent and traceable to the level above it. */
			}
		}

		use case def EvolveDatabaseSchemas {
			doc
			/*
			A data modeler changes the data model, records the new schema version and the migration from the
			previous one, and a DevOps engineer releases the migration with the software version that needs it.
			*/
			subject environment : UML3Environment;
			actor modeler : DataModeler;
			actor devOps : DevOpsEngineer;
			objective {
				doc /* Existing databases move to the new schema without losing data or breaking compatible clients. */
			}
		}

		use case def GovernEnterpriseData {
			doc
			/*
			A data modeler records owners, stewards, retention and lineage of data elements, and a security engineer
			classifies them, so that governance and privacy obligations can be listed per element.
			*/
			subject environment : UML3Environment;
			actor modeler : DataModeler;
			actor securityEngineer : SecurityEngineer;
			objective {
				doc /* For every data element, who owns it, how long it is kept, where it comes from and how sensitive it is are known. */
			}
		}

		#traces dependency from DesignLayeredDataModels to 'UML3-DATA-001', 'UML3-DATA-002', 'UML3-DATA-003',
			'UML3-DATA-004', 'UML3-DATA-005', 'UML3-DATA-006', 'UML3-DATA-007', 'UML3-DATA-008', 'UML3-DATA-009',
			'UML3-DATA-012', 'UML3-DATA-013';
		#traces dependency from EvolveDatabaseSchemas to 'UML3-DATA-007', 'UML3-DATA-008', 'UML3-DATA-010',
			UML3DevOpsRequirements::'UML3-OPS-006';
		#traces dependency from GovernEnterpriseData to 'UML3-DATA-011', 'UML3-DATA-014',
			UML3SecurityRequirements::'UML3-SEC-005', UML3SecurityRequirements::'UML3-SEC-006',
			UML3SecurityRequirements::'UML3-SEC-007';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done and tbc DATA requirements.

		Contents:
		- #realizes dependencies from UML3Data elements to DATA requirements.
		*/
		#realizes dependency from UML3Data::entity to 'UML3-DATA-001';
		#realizes dependency from UML3Data::aggregateRoot to 'UML3-DATA-001';
		#realizes dependency from UML3Data::valueObject to 'UML3-DATA-001';
		#realizes dependency from UML3Data::transient to 'UML3-DATA-001';
		#realizes dependency from UML3Data::relationship to 'UML3-DATA-003';
		#realizes dependency from UML3Data::primaryKey to 'UML3-DATA-004';
		#realizes dependency from UML3Data::KeyGeneration to 'UML3-DATA-004';
		#realizes dependency from UML3Data::unique to 'UML3-DATA-004';
		#realizes dependency from UML3Data::indexed to 'UML3-DATA-004';
		#realizes dependency from UML3Data::Index to 'UML3-DATA-004';
		#realizes dependency from UML3Data::foreignKey to 'UML3-DATA-005';
		#realizes dependency from UML3Data::ReferentialAction to 'UML3-DATA-005';
		#realizes dependency from UML3Data::database to 'UML3-DATA-006';
		#realizes dependency from UML3Data::table to 'UML3-DATA-006';
		#realizes dependency from UML3Data::column to 'UML3-DATA-006';
		#realizes dependency from UML3Data::Column to 'UML3-DATA-006';
		#realizes dependency from UML3Data::dbView to 'UML3-DATA-006';
		#realizes dependency from UML3Data::mapsTo to 'UML3-DATA-008';
	}
}
