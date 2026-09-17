library package UML3Data {
	doc
	/*
	UML3Data: data modeling for UML3, from conceptual and logical models (entities, value objects,
	relationships, keys) to physical relational models (databases, tables, columns, indexes, foreign
	keys, views), and the logical-to-physical mapping.

	Logical model; the end multiplicities of a relationship give its cardinality:
	  #entity item def Customer { #primaryKey attribute customerId : Uuid; }
	  #relationship connection def Places {
	    end [1] ref customer : Customer;
	    end [0..*] ref order : Order;
	  }
	Physical model, mapped to the logical model:
	  #table item def CUSTOMER {
	    #column #primaryKey attribute CUSTOMER_ID : Uuid { @Column { sqlType = "UUID"; } }
	  }
	  #mapsTo dependency from CUSTOMER to Customer;
	Cardinality is the native multiplicity of the relationship ends, and an optional (nullable)
	attribute has multiplicity [0..1], so UML3 adds no cardinality or nullability metadata.

	Contents:
	- Logical model: Entity, AggregateRoot, ValueObject, Relationship.
	- Physical model: Database, Table, DatabaseView, columns.
	- Keywords: #entity, #aggregateRoot, #valueObject, #relationship, #database, #table, #dbView, #column.
	- Keys: #primaryKey, #foreignKey, #unique, #indexed, @Index, KeyGeneration, ReferentialAction.
	- Physical details and governance: @Column, #transient, #audited, @Sensitivity.
	- Logical-to-physical mapping: #mapsTo.

	Rationale: an entity specializes UML3Core::Class and a relationship UML3Core::Association, so a
	logical data model is also a UML3 class model; keys and constraints are keywords on ordinary
	attributes and ref items.
	References: UML 2.5.1 Class; UML 2.5.1 Association; UML 2.5.1 Property.isID; SysML 7.27.3; docs/DESIGN.md.
	*/

	private import ScalarValues::*;
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;

	comment DataLogicalModelDesign about Entity, AggregateRoot, ValueObject, Relationship
		/*
		Logical data model. Entities are UML3Core classes (item defs): business objects with identity
		that are stored and referenced. Value objects are UML3Core data types (attribute defs): values
		without identity, embedded in the entity that owns them. KerML keeps objects and data values
		disjoint, so the two kinds cannot be mixed: #entity on an attribute def is an error
		(check_names.py APPLICABILITY; CATIA Magic reports validateDataTypeSpecialization).
		Relationships are UML3Core associations whose end multiplicities give the cardinality. An M:N
		relationship maps to a join table, and attributes of the relationship, which make it an
		association class, become columns of that table. check_rules.py R02 warns when an entity has
		no identity, and R04 when a relationship is not binary.
		References: UML 2.5.1 Class; UML 2.5.1 DataType; UML 2.5.1 AssociationClass; KerML 7.3.2.5; E05.
		*/

	abstract item def Entity :> Class {
		doc
		/*
		A business object with identity and a lifecycle, persisted as a unit: the entity of an
		entity-relationship or domain-driven design model.

		Usage: give the entity an identity with #primaryKey (or #id) on one or more of its attributes:
		  #entity item def Tag { #primaryKey attribute tagId : Int32; #unique attribute label : String; }

		Rationale: an item def through UML3Core::Class, because an entity is an object with identity
		that can be stored, referenced and passed in messages.
		References: UML 2.5.1 Class; UML 2.5.1 Property.isID; SysML 7.10; E05.
		*/
	}
	abstract item entities : Entity[0..*] nonunique :> classes {
		doc /* All entities; #entity usages, and #aggregateRoot usages indirectly, subset this feature. */
	}

	abstract item def AggregateRoot :> Entity {
		doc
		/*
		The root entity of a domain-driven design aggregate: the only entry point for changes to the
		aggregate, which is kept consistent as a whole.

		Usage: the entities inside the aggregate are composite items of the root; other aggregates are
		referenced with 'ref' features:
		  #aggregateRoot item def PurchaseOrder {
		    #primaryKey attribute orderId : Uuid;
		    item lines : PurchaseOrderLine[1..*] ordered;
		    ref #foreignKey item account : CustomerAccount[1];
		  }
		References: UML 2.5.1 Class; UML 2.5.1 Property.aggregation.
		*/
	}
	abstract item aggregateRoots : AggregateRoot[0..*] nonunique :> entities {
		doc /* All aggregate roots; #aggregateRoot usages subset this feature. */
	}

	abstract attribute def ValueObject :> DataType {
		doc
		/*
		A domain-driven design value object: an immutable value without identity, compared by its
		contents and embedded in the entity that owns it.

		Usage: #valueObject attribute def PostalAddress { attribute line1 : Text; attribute city : Text; }
		and, in the owner, attribute billingAddress : PostalAddress[0..1];
		References: UML 2.5.1 DataType; KerML 7.4.2; SysML 7.7.
		*/
	}
	abstract attribute valueObjects : ValueObject[0..*] nonunique :> dataTypes {
		doc /* All value objects; #valueObject usages subset this feature. */
	}

	abstract connection def Relationship :> Association {
		doc
		/*
		An entity relationship: a binary association between entities whose end multiplicities give the
		cardinality (1:1, 1:N or M:N).

		Usage:
		  #relationship connection def AccountOrders {
		    end [1] ref account : CustomerAccount;
		    end [0..*] ref purchaseOrder : PurchaseOrder;
		  }
		Attributes of a relationship, such as the time an M:N link was made, make it an association class.
		References: UML 2.5.1 Association; UML 2.5.1 AssociationClass; KerML 7.4.5; SysML 7.13.
		*/
	}
	abstract connection relationships : Relationship[0..*] nonunique :> associations {
		doc /* All relationship links; #relationship usages subset this feature. */
	}

	comment DataPhysicalModelDesign about Table, DatabaseView, columns, Database
		/*
		Physical relational model. A database is a part def whose tables and views are nested items. A
		table is an item def whose columns are attribute usages marked #column. Table does not
		specialize UML3Core::Class, so physical tables stay out of class queries; a #mapsTo dependency
		links a table to the entity that it implements. DatabaseView specializes Table: a view has
		columns like a table, plus the query that defines it. check_rules.py R01 requires a #primaryKey
		column in every #table, and R11 warns when a #dbView does not set queryText.
		References: SysML 7.7; SysML 7.10; SysML 7.11; UML3Data::MapsTo.
		*/

	abstract item def Table {
		doc
		/*
		A relational table: rows of values in named, typed columns, identified by a primary key.

		Usage: declare each column as an attribute usage marked #column, and mark the key columns
		#primaryKey:
		  #table item def CUSTOMER_ACCOUNT {
		    #column #primaryKey attribute ACCOUNT_ID : Uuid { @Column { sqlType = "UUID"; } }
		    #column attribute EMAIL : EmailAddress { @Column { sqlType = "VARCHAR(254)"; } }
		  }
		References: SysML 7.10; UML3Data::MapsTo.
		*/
	}
	abstract item tables : Table[0..*] nonunique {
		doc /* All tables; #table usages subset this feature, and #dbView usages through databaseViews. */
	}

	abstract item def DatabaseView :> Table {
		doc
		/*
		A database view, possibly materialized: a named query whose result has columns like a table.

		Usage:
		  #dbView item def OPEN_ORDERS_V {
		    attribute :>> queryText = "SELECT ORDER_ID FROM PURCHASE_ORDER WHERE STATUS = 'OPEN'";
		    #column attribute ORDER_ID : Uuid;
		  }

		Rationale: the keyword is #dbView because 'view' is a reserved SysML word; a database view is
		unrelated to SysML views.
		References: SysML 7.10; SysML 7.26.
		*/
		attribute isMaterialized : Boolean default false {
			doc
			/*
			True when the database stores the query result (a materialized view) instead of computing it
			on each read; default false.
			*/
		}
		attribute queryText : String[0..1] {
			doc
			/*
			The SQL query that defines the view, in the dialect of the database. check_rules.py R11 warns
			when a #dbView does not set it.
			*/
		}
	}
	abstract item databaseViews : DatabaseView[0..*] nonunique :> tables {
		doc /* All database views; #dbView usages subset this feature. */
	}

	abstract attribute columns : Base::DataValue[0..*] nonunique {
		doc
		/*
		All table columns: the base of every attribute usage marked #column.

		Rationale: typed by Base::DataValue, the most general value type, so #column applies to
		attributes of any value type and is an error on items and parts, because KerML keeps data
		values and objects disjoint (CATIA Magic reports #column on an item def as
		validateClassSpecialization).
		References: KerML 7.3.2.5; KerML 9.2.2; SysML 7.7.
		*/
	}

	abstract part def Database {
		doc
		/*
		A deployed database: the container of the tables and views of a schema.

		Usage: the tables are nested items of the database:
		  #database part def StoreDb {
		    attribute :>> engine = "PostgreSQL 16";
		    item purchaseOrder : PURCHASE_ORDER;
		  }
		References: SysML 7.11.
		*/
		attribute engine : String[0..1] {
			doc
			/*
			The database product and version, for example "PostgreSQL 16"; it sets the SQL dialect of
			sqlType, columnDefault and queryText.
			*/
		}
	}
	abstract part databases : Database[0..*] nonunique {
		doc /* All databases; #database usages subset this feature. */
	}

	enum def ReferentialAction {
		doc
		/*
		What the database does with referencing rows when the referenced row is deleted or its key is
		updated: the SQL referential actions, used by @ForeignKey onDelete and onUpdate.
		*/
		enum noAction {
			doc
			/*
			NO ACTION, the SQL default: the change fails if referencing rows remain when the constraint
			is checked, which can be deferred to commit.
			*/
		}
		enum restrict {
			doc
			/*
			RESTRICT: the change fails at once if a referencing row exists; unlike noAction, the check
			cannot be deferred.
			*/
		}
		enum cascade {
			doc
			/*
			CASCADE: deleting the referenced row deletes the referencing rows, and updating its key
			updates their foreign keys.
			*/
		}
		enum setNull {
			doc
			/*
			SET NULL: the foreign key of the referencing rows is set to null, so it must be optional
			([0..1]).
			*/
		}
		enum setDefault {
			doc
			/*
			SET DEFAULT: the foreign key of the referencing rows is set to its column default
			(@Column columnDefault).
			*/
		}
	}

	enum def KeyGeneration {
		doc /* How the values of a primary key are produced; the value of @PrimaryKey generation. */
		enum assigned {
			doc
			/*
			The application assigns the value before the row is inserted, for example a natural key; the
			default.
			*/
		}
		enum identity {
			doc /* The database generates the value in an identity (auto-increment) column. */
		}
		enum sequenceGenerated {
			doc /* The value is taken from a database sequence. */
		}
		enum uuidGenerated {
			doc /* A UUID is generated for the key, by the database or by the persistence layer. */
		}
	}

	comment DataKeywordDesign about EntityMetadata, AggregateRootMetadata, ValueObjectMetadata,
		RelationshipMetadata, TableMetadata, DatabaseViewMetadata, ColumnMetadata, DatabaseMetadata
		/*
		Semantic keywords for data models, built like those of UML3Core: a keyworded definition
		specializes the library definition and a keyworded usage subsets its collection. Verified in
		CATIA Magic: an #aggregateRoot definition is an AggregateRoot and an Entity, and a #column
		attribute subsets columns. The keyword of DatabaseView is #dbView because 'view' is a reserved
		SysML word. UML3Views::EntityRelationshipDiagram selects elements by these keywords.
		References: KerML 7.4.13; KerML 9.2.16; SysML 7.27.3.
		*/

	metadata def <entity> EntityMetadata :> SemanticMetadata {
		doc
		/*
		Keyword #entity: the item is a UML3 Entity (a definition specializes Entity, a usage subsets
		entities).
		*/
		:>> baseType = entities meta SysML::Usage;
	}
	metadata def <aggregateRoot> AggregateRootMetadata :> SemanticMetadata {
		doc /* Keyword #aggregateRoot: the item is the AggregateRoot of a domain-driven design aggregate. */
		:>> baseType = aggregateRoots meta SysML::Usage;
	}
	metadata def <valueObject> ValueObjectMetadata :> SemanticMetadata {
		doc /* Keyword #valueObject: the attribute def or attribute is a ValueObject; not valid on items. */
		:>> baseType = valueObjects meta SysML::Usage;
	}
	metadata def <relationship> RelationshipMetadata :> SemanticMetadata {
		doc
		/*
		Keyword #relationship: the connection is an entity Relationship whose end multiplicities give
		the cardinality.
		*/
		:>> baseType = relationships meta SysML::Usage;
	}
	metadata def <table> TableMetadata :> SemanticMetadata {
		doc
		/*
		Keyword #table: the item is a relational Table, which needs a #primaryKey column
		(check_rules.py R01).
		*/
		:>> baseType = tables meta SysML::Usage;
	}
	metadata def <dbView> DatabaseViewMetadata :> SemanticMetadata {
		doc /* Keyword #dbView: the item is a DatabaseView and should set queryText (check_rules.py R11). */
		:>> baseType = databaseViews meta SysML::Usage;
	}
	metadata def <column> ColumnMetadata :> SemanticMetadata {
		doc
		/*
		Keyword #column: the attribute is a column of its table and subsets columns. It is valid on
		attributes only.
		*/
		:>> baseType = columns meta SysML::Usage;
	}
	metadata def <database> DatabaseMetadata :> SemanticMetadata {
		doc /* Keyword #database: the part is a deployed Database that contains tables. */
		:>> baseType = databases meta SysML::Usage;
	}

	comment DataMarkerKeywordDesign about primaryKeyFeatures, foreignKeyFeatures, uniqueFeatures,
		indexedFeatures, transientFeatures, auditedElements, PrimaryKey, ForeignKey, Unique, Indexed,
		Transient, Audited, KeyGeneration, ReferentialAction
		/*
		Marker keywords for keys, constraints and governance. They are semantic keywords, so CATIA Magic
		shows them as labels («#primaryKey») and the marked features form queryable sets. As for the
		UML3Core markers, the baseType is a reference usage typed by Base::Anything, so a marker is
		valid on attributes and on ref items alike (E01). Options such as @PrimaryKey generation (a
		KeyGeneration) or @ForeignKey onDelete (a ReferentialAction) are set in body form, because the
		'#' prefix form cannot set values:
		  attribute tagId : Int32 { @PrimaryKey { generation = KeyGeneration::identity; } }
		CATIA Magic applies only the first semantic keyword of an element (E02, E03): with
		'#column #primaryKey attribute ACCOUNT_ID' the attribute subsets columns but not
		primaryKeyFeatures, and the reverse order gives the reverse result. Put first the keyword that
		queries need most; check_rules.py R12 warns when a usage stacks semantic keywords.
		References: KerML 7.4.13; KerML 9.2.16; SysML 7.27.3; E01; E02; E03.
		*/

	abstract ref primaryKeyFeatures : Anything[0..*] nonunique {
		doc /* All features marked #primaryKey. */
	}
	abstract ref foreignKeyFeatures : Anything[0..*] nonunique {
		doc /* All features marked #foreignKey. */
	}
	abstract ref uniqueFeatures : Anything[0..*] nonunique {
		doc /* All features marked #unique. */
	}
	abstract ref indexedFeatures : Anything[0..*] nonunique {
		doc /* All features marked #indexed. */
	}
	abstract ref transientFeatures : Anything[0..*] nonunique {
		doc /* All features marked #transient. */
	}
	abstract ref auditedElements : Anything[0..*] nonunique {
		doc /* All usages marked #audited; on a definition the keyword is a label only (see Audited). */
	}

	metadata def <primaryKey> PrimaryKey :> SemanticMetadata {
		doc
		/*
		Keyword #primaryKey: the attribute or ref item is the primary key of its entity or table, or
		part of it; several #primaryKey features form a composite key.

		Usage:
		  #entity item def OrderTag {
		    #primaryKey attribute orderId : Uuid;
		    #primaryKey attribute tagId : Int32;
		  }
		check_rules.py R01 requires a #primaryKey column in every #table, and R02 warns when an entity
		has neither #primaryKey nor #id.

		Rationale: stronger than #id (UML3Core::Identifier, UML isID): it marks a database key and
		states how its values are generated.
		References: UML 2.5.1 Property.isID; E02; E03.
		*/
		:>> baseType = primaryKeyFeatures meta SysML::Usage;
		attribute generation : KeyGeneration default KeyGeneration::assigned {
			doc
			/*
			How the key values are produced; default assigned. Set it in body form:
			  @PrimaryKey { generation = KeyGeneration::identity; }
			*/
		}
	}

	metadata def <foreignKey> ForeignKey :> SemanticMetadata {
		doc
		/*
		Keyword #foreignKey: the feature refers to another entity or table. In a logical model mark the
		'ref' feature typed by the entity; in a physical model mark the #column and name the referenced
		table.

		Usage, logical ('ref' comes before the keyword):
		  ref #foreignKey item account : CustomerAccount[1] {
		    @ForeignKey { onDelete = ReferentialAction::restrict; }
		  }
		Usage, physical:
		  #column #foreignKey attribute ACCOUNT_ID : Uuid {
		    @ForeignKey { referencedTable = "CUSTOMER_ACCOUNT"; referencedColumn = "ACCOUNT_ID"; }
		  }
		check_rules.py R03 checks that a #foreignKey ref refers to an #entity, #aggregateRoot or
		#table, and that the referencedTable of a #foreignKey column names a #table.
		References: UML 2.5.1 Association; UML 2.5.1 Property; E02.
		*/
		:>> baseType = foreignKeyFeatures meta SysML::Usage;
		attribute onDelete : ReferentialAction default ReferentialAction::noAction {
			doc /* The action on referencing rows when the referenced row is deleted; default noAction. */
		}
		attribute onUpdate : ReferentialAction default ReferentialAction::noAction {
			doc /* The action on referencing rows when the referenced key is updated; default noAction. */
		}
		attribute referencedTable : String[0..1] {
			doc
			/*
			Name of the referenced #table, for a physical #column. A logical 'ref' feature needs none,
			because its type is the referenced entity. check_rules.py R03 warns when a #foreignKey
			column does not set it.
			*/
		}
		attribute referencedColumn : String[0..1] {
			doc
			/*
			Name of the referenced column in referencedTable, normally its primary key or a unique
			column.
			*/
		}
	}

	metadata def <unique> Unique :> SemanticMetadata {
		doc
		/*
		Keyword #unique: no two instances of the owner have the same value of the feature (a UNIQUE
		constraint).

		Usage: #unique attribute email : EmailAddress;
		For a unique combination of several columns, use @Index with isUnique = true.
		Not to be confused with isUnique of a multiplicity (written 'nonunique' when false), which
		concerns the values of one feature of one instance.
		References: UML 2.5.1 MultiplicityElement.
		*/
		:>> baseType = uniqueFeatures meta SysML::Usage;
	}

	metadata def <indexed> Indexed :> SemanticMetadata {
		doc
		/*
		Keyword #indexed: the database keeps a single-column index on the feature.

		Usage: #indexed attribute placedAt : Timestamp;
		Declare indexes over several columns, or named indexes, with @Index on the table or entity.
		*/
		:>> baseType = indexedFeatures meta SysML::Usage;
	}

	comment DataPlainMetadataDesign about Index, Column, Sensitivity, MapsTo
		/*
		Plain metadata. Index, Column and Sensitivity carry configuration values, and MapsTo classifies
		dependencies, which are not types and so cannot carry semantic metadata. Plain metadata implies
		no specialization and does not appear in the keyword labels of CATIA Magic diagrams.
		References: KerML 7.4.13; SysML 7.3; SysML 7.27.
		*/

	metadata def Index {
		doc
		/*
		An index declared on a table or entity, usually over several columns, with its name and
		uniqueness.

		Usage, in the body of the table:
		  @Index { indexName = "ix_purchase_order_account_placed";
		    columnNames = ("ACCOUNT_ID", "PLACED_AT"); }
		References: KerML 7.4.13; SysML 7.27.
		*/
		attribute indexName : String {
			doc /* The name of the index in the database; required. */
		}
		attribute columnNames : String[1..*] ordered {
			doc
			/*
			The indexed columns (or attributes, on an entity) in index key order, which decides the
			queries the index can serve.
			*/
		}
		attribute isUnique : Boolean default false {
			doc /* True for a unique index: no two rows share the values in columnNames; default false. */
		}
	}

	metadata def Column {
		doc
		/*
		Physical details of a #column attribute: its name in the database, its SQL type and its default.

		Usage:
		  #column attribute CREATED_AT : Timestamp {
		    @Column { sqlType = "TIMESTAMPTZ"; columnDefault = "now()"; }
		  }
		As plain metadata, @Column does not add a second semantic keyword to the attribute (E02, E03).
		References: KerML 7.4.13; SysML 7.27.
		*/
		attribute columnName : String[0..1] {
			doc
			/*
			The column name in the database, when it differs from the attribute name (for example a
			quoted or reserved name).
			*/
		}
		attribute sqlType : String[0..1] {
			doc
			/*
			The SQL type in the dialect of the database, for example "UUID", "VARCHAR(254)" or
			"TIMESTAMPTZ".
			*/
		}
		attribute columnDefault : String[0..1] {
			doc
			/*
			The SQL default expression of the column, in the dialect of the database, for example
			"now()".
			*/
		}
	}

	metadata def <transient> Transient :> SemanticMetadata {
		doc
		/*
		Keyword #transient: the attribute is not persisted; its value is derived, computed or held only
		at runtime.

		Usage: #transient attribute lineCount : Natural;
		Native 'derived' states that a value is computed from other features; #transient states that it
		is not stored.
		*/
		:>> baseType = transientFeatures meta SysML::Usage;
	}

	metadata def <audited> Audited :> SemanticMetadata {
		doc
		/*
		Keyword #audited: changes to the element are recorded in an audit trail.

		Usage: '@Audited;' in the body of an entity, or #audited on a single attribute. On a definition
		the implied specialization is to Base::Anything, which adds nothing, so only marked usages join
		auditedElements.
		*/
		:>> baseType = auditedElements meta SysML::Usage;
	}

	metadata def Sensitivity {
		doc
		/*
		The data classification of an element for privacy and security, for example personal data that
		privacy law such as the GDPR protects.

		Usage: #unique attribute email : EmailAddress { @Sensitivity { classification = "PII"; } }
		References: KerML 7.4.13; SysML 7.27.
		*/
		attribute classification : String {
			doc
			/*
			The classification label, from a set agreed in the organization, for example "PII"
			(personally identifiable information), "PCI" (payment card data) or "PHI" (protected health
			information).
			*/
		}
	}

	metadata def <mapsTo> MapsTo {
		doc
		/*
		Keyword #mapsTo: the dependency links a physical element (the client) to the logical element
		(the supplier) that it implements, such as a table to its entity.

		Usage: #mapsTo dependency customerMapping from CUSTOMER_ACCOUNT to Logical::CustomerAccount;

		Rationale: plain metadata restricted to dependencies. Semantic metadata requires a type, and a
		dependency is not one; the keyword classifies the dependency for queries and views.
		References: UML 2.5.1 Abstraction; UML 2.5.1 Dependency; KerML 7.4.13; SysML 7.3.
		*/
		:>> annotatedElement : SysML::Dependency;
	}
}
