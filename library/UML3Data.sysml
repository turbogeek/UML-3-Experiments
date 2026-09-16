library package UML3Data {
	doc
	/*
	 * UML3Data - conceptual/logical data modeling (entities, value objects,
	 * relationships, keys) and physical relational modeling (tables, columns,
	 * indexes, foreign keys, views), plus logical-to-physical mapping.
	 *
	 *   Logical:   #entity item def Customer { #primaryKey attribute customerId : Uuid; }
	 *   Relation:  #relationship connection def Places { end [1] ref customer : Customer; end [0..*] ref order : Order; }
	 *   Physical:  #table item def CUSTOMER { #column attribute CUSTOMER_ID : Uuid { @Column { sqlType = "UUID"; } } }
	 *   Mapping:   #mapsTo dependency from CUSTOMER to Customer;
	 *
	 * Cardinality is the native multiplicity of relationship ends; optional
	 * (nullable) attributes use [0..1].
	 */

	private import ScalarValues::*;
	private import Base::Anything;
	private import Metaobjects::SemanticMetadata;
	private import UML3Core::*;

	/* ---------------------------------------------------------------------
	 * Logical / conceptual
	 * --------------------------------------------------------------------- */

	abstract item def Entity :> Class {
		doc /* Business object with identity and lifecycle, persisted as a unit. */
	}
	abstract item entities : Entity[0..*] nonunique :> classes;

	abstract item def AggregateRoot :> Entity {
		doc /* DDD aggregate root: the only entry point for changes to its aggregate. */
	}
	abstract item aggregateRoots : AggregateRoot[0..*] nonunique :> entities;

	abstract attribute def ValueObject :> DataType {
		doc /* DDD value object: immutable, compared by value, embedded in its owner. */
	}
	abstract attribute valueObjects : ValueObject[0..*] nonunique :> dataTypes;

	abstract connection def Relationship :> Association {
		doc /* Entity relationship; end multiplicities give the cardinality (1:1, 1:N, M:N). */
	}
	abstract connection relationships : Relationship[0..*] nonunique :> associations;

	/* ---------------------------------------------------------------------
	 * Physical / relational
	 * --------------------------------------------------------------------- */

	abstract item def Table {
		doc /* A relational table. Columns are attribute usages marked #column. */
	}
	abstract item tables : Table[0..*] nonunique;

	abstract item def DatabaseView :> Table {
		doc /* A (possibly materialized) view; 'view' is a reserved SysML word. */
		attribute isMaterialized : Boolean default false;
		attribute queryText : String[0..1];
	}
	abstract item databaseViews : DatabaseView[0..*] nonunique :> tables;

	abstract attribute columns : Base::DataValue[0..*] nonunique {
		doc /* Base of every #column attribute usage. */
	}

	abstract part def Database {
		doc /* A deployed database (schema container). Tables are its nested items. */
		attribute engine : String[0..1];
	}
	abstract part databases : Database[0..*] nonunique;

	enum def ReferentialAction {
		enum noAction;
		enum restrict;
		enum cascade;
		enum setNull;
		enum setDefault;
	}

	enum def KeyGeneration {
		enum assigned;
		enum identity;
		enum sequenceGenerated;
		enum uuidGenerated;
	}

	/* ---------------------------------------------------------------------
	 * Semantic keywords
	 * --------------------------------------------------------------------- */

	metadata def <entity> EntityMetadata :> SemanticMetadata {
		:>> baseType = entities meta SysML::Usage;
	}
	metadata def <aggregateRoot> AggregateRootMetadata :> SemanticMetadata {
		:>> baseType = aggregateRoots meta SysML::Usage;
	}
	metadata def <valueObject> ValueObjectMetadata :> SemanticMetadata {
		:>> baseType = valueObjects meta SysML::Usage;
	}
	metadata def <relationship> RelationshipMetadata :> SemanticMetadata {
		:>> baseType = relationships meta SysML::Usage;
	}
	metadata def <table> TableMetadata :> SemanticMetadata {
		:>> baseType = tables meta SysML::Usage;
	}
	metadata def <dbView> DatabaseViewMetadata :> SemanticMetadata {
		:>> baseType = databaseViews meta SysML::Usage;
	}
	metadata def <column> ColumnMetadata :> SemanticMetadata {
		:>> baseType = columns meta SysML::Usage;
	}
	metadata def <database> DatabaseMetadata :> SemanticMetadata {
		:>> baseType = databases meta SysML::Usage;
	}

	/* ---------------------------------------------------------------------
	 * Key, constraint and physical-detail metadata
	 * --------------------------------------------------------------------- */

	/* Marker keywords are semantic so they show as labels («#primaryKey») and form queryable
	 * sets; baseType typed by Anything (see UML3Core), valid on attributes and ref items. */
	abstract ref primaryKeyFeatures : Anything[0..*] nonunique;
	abstract ref foreignKeyFeatures : Anything[0..*] nonunique;
	abstract ref uniqueFeatures : Anything[0..*] nonunique;
	abstract ref indexedFeatures : Anything[0..*] nonunique;
	abstract ref transientFeatures : Anything[0..*] nonunique;
	abstract ref auditedElements : Anything[0..*] nonunique;

	metadata def <primaryKey> PrimaryKey :> SemanticMetadata {
		doc /* The attribute is (part of) the primary key. Several #primaryKey attributes form a composite key. */
		:>> baseType = primaryKeyFeatures meta SysML::Usage;
		attribute generation : KeyGeneration default KeyGeneration::assigned;
	}

	metadata def <foreignKey> ForeignKey :> SemanticMetadata {
		doc
		/*
		 * Applied to a 'ref' feature (logical) or a #column (physical) that refers to
		 * another entity/table. Referential actions via @ForeignKey { onDelete = ...; }.
		 */
		:>> baseType = foreignKeyFeatures meta SysML::Usage;
		attribute onDelete : ReferentialAction default ReferentialAction::noAction;
		attribute onUpdate : ReferentialAction default ReferentialAction::noAction;
		attribute referencedTable : String[0..1];
		attribute referencedColumn : String[0..1];
	}

	metadata def <unique> Unique :> SemanticMetadata {
		doc /* Values of the attribute are unique across all instances. */
		:>> baseType = uniqueFeatures meta SysML::Usage;
	}

	metadata def <indexed> Indexed :> SemanticMetadata {
		doc /* A single-column index exists on the attribute. */
		:>> baseType = indexedFeatures meta SysML::Usage;
	}

	metadata def Index {
		doc /* Multi-column index declared on a table/entity: @Index { indexName = "ix_x"; columnNames = ("A", "B"); } */
		attribute indexName : String;
		attribute columnNames : String[1..*] ordered;
		attribute isUnique : Boolean default false;
	}

	metadata def Column {
		doc /* Physical column details. */
		attribute columnName : String[0..1];
		attribute sqlType : String[0..1];
		attribute columnDefault : String[0..1];
	}

	metadata def <transient> Transient :> SemanticMetadata {
		doc /* Attribute is derived / computed and not persisted. */
		:>> baseType = transientFeatures meta SysML::Usage;
	}

	metadata def <audited> Audited :> SemanticMetadata {
		doc /* Changes to the element are recorded in an audit trail. */
		:>> baseType = auditedElements meta SysML::Usage;
	}

	metadata def Sensitivity {
		doc /* Data classification for privacy/security (e.g. "PII", "PCI", "PHI"). */
		attribute classification : String;
	}

	metadata def <mapsTo> MapsTo {
		doc /* On a dependency from a physical element (client) to the logical element (supplier) it implements. */
		:>> annotatedElement : SysML::Dependency;
	}
}
