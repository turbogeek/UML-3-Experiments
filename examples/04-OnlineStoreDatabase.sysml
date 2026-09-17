package OnlineStoreDatabase {
	doc
	/*
	Example 4: the online store's customer and order data, as a logical data model and as the physical
	PostgreSQL schema that implements it (UML3Data).

	The logical model says what the store must keep, independent of any database: aggregates, entities,
	value objects, keys, and relationships whose end multiplicities give the cardinality. The physical
	model says how the data is stored: a database with tables, typed columns, an index and a view.
	#mapsTo dependencies link each table to the logical element it implements, so a change on either
	side can be traced to the other.

	Contents:
	- Logical: PostalAddress (#valueObject), CustomerAccount and PurchaseOrder (#aggregateRoot),
	  PurchaseOrderLine and Tag (#entity), AccountOrders (1 : N) and OrderTagging (M : N) (#relationship);
	  keys and constraints with #primaryKey, #foreignKey, #unique, #indexed, #transient and @Audited.
	- Physical: StoreDb (#database), CUSTOMER_ACCOUNT and PURCHASE_ORDER (#table, #column, @Column, @Index,
	  @ForeignKey), OPEN_ORDERS_V (#dbView).
	- Mapping: customerMapping and orderMapping (#mapsTo dependencies from a table to a logical element).
	References: UML3Data::Entity; UML3Data::Table; UML3Data::MapsTo; SysML 7.27; docs/DESIGN.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Data::*;

	comment StackedKeyKeywords about Logical::PurchaseOrderLine::parentOrder,
		Physical::CUSTOMER_ACCOUNT::ACCOUNT_ID, Physical::CUSTOMER_ACCOUNT::EMAIL,
		Physical::PURCHASE_ORDER::ORDER_ID, Physical::PURCHASE_ORDER::ACCOUNT_ID
		/*
		Keyword order on keys. Each of these features has two semantic keywords, and CATIA Magic 2026x
		applies the implied subsetting of the first one only (E02, E03): parentOrder is found among the
		primary keys but not among the foreign keys, and the physical key columns among the columns but
		not among the keys. The second keyword still shows as a label. The usage rule in docs/DESIGN.md is
		to write first the keyword whose query matters most; check_rules.py R12 warns about each case.
		References: E02; E03; docs/DESIGN.md.
		*/

	package Logical {
		doc
		/*
		The logical data model: the customer and order data that the store must keep, free of database detail.

		Aggregates follow domain-driven design. CustomerAccount and PurchaseOrder are aggregate roots, each
		changed as a whole through its root; PurchaseOrderLine exists only inside its PurchaseOrder; Tag is
		an entity shared by many orders. Keys are declared on this business model, and the physical tables
		take their key columns from them.

		Contents:
		- Value object: PostalAddress, embedded in CustomerAccount.
		- Aggregate roots: CustomerAccount (@Audited, e-mail classified as PII) and PurchaseOrder (foreign key
		  to its account, owned order lines).
		- Entities: PurchaseOrderLine (composite key) and Tag (database-generated key).
		- Relationships: AccountOrders (1 : N) and OrderTagging (M : N with an attribute).
		References: UML3Data::AggregateRoot; UML3Data::Entity; UML3Data::Relationship; UML 2.5.1 Class.
		*/

		#valueObject attribute def PostalAddress {
			doc
			/*
			A postal address, used as the billing address of a customer account.

			Rationale: a value object (an attribute def), because an address has no identity or lifecycle of
			its own: two equal addresses are the same value, and it is stored inside the account that owns it.
			The physical model therefore flattens it into BILLING_ columns of CUSTOMER_ACCOUNT, not a table.
			References: UML3Data::ValueObject; UML 2.5.1 DataType; SysML 7.7.
			*/
			attribute line1 : Text {
				doc /* First address line: street and house number. */
			}
			attribute city : Text {
				doc /* City or town. */
			}
			attribute postalCode : String {
				doc /* Postal code; a string, because codes can contain letters and leading zeros. */
			}
		}

		#aggregateRoot item def CustomerAccount {
			doc
			/*
			A customer's account: its identity, login e-mail and billing address.

			Key choices: accountId is a surrogate UUID key, so the identity never changes when the e-mail
			does; email is also unique, a natural key for finding the account. The account is an aggregate
			root because it is created and changed independently of any order. @Audited records every change,
			because the account holds personal data.
			References: UML3Data::AggregateRoot; UML3Data::Audited; UML3Data::Sensitivity.
			*/
			@Audited;
			#primaryKey attribute accountId : Uuid {
				doc /* Surrogate primary key, assigned by the application (the default key generation). */
			}
			#unique attribute email : EmailAddress {
				doc /* Login and contact e-mail; unique, and classified as PII by @Sensitivity. */
				@Sensitivity { classification = "PII"; }
			}
			attribute billingAddress : PostalAddress[0..1] {
				doc /* Billing address, embedded as a value; [0..1] makes it optional (nullable). */
			}
		}

		#aggregateRoot item def PurchaseOrder {
			doc
			/*
			An order placed from a customer account, with its order lines.

			Key choices: orderId is a surrogate UUID key; placedAt is #indexed because orders are looked up
			by date. The account is referenced, not owned, because it is another aggregate; its foreign key
			has onDelete = restrict, so an account cannot be deleted while it still has orders and order
			history is never orphaned. The lines are owned (composite), so each line belongs to one order.
			References: UML3Data::AggregateRoot; UML3Data::ForeignKey; UML 2.5.1 Property.aggregation.
			*/
			#primaryKey attribute orderId : Uuid {
				doc /* Surrogate primary key of the order, assigned by the application. */
			}
			#indexed attribute placedAt : Timestamp {
				doc /* When the order was placed; indexed for listing orders by date. */
			}
			ref #foreignKey item account : CustomerAccount[1] {
				doc
				/*
				The account that placed the order. A reference, because the account is another aggregate;
				onDelete = restrict makes deleting that account fail while this order refers to it.
				*/
				@ForeignKey { onDelete = ReferentialAction::restrict; }
			}
			item lines : PurchaseOrderLine[1..*] ordered {
				doc /* The order lines, owned by the order: at least one, in entry order. */
			}
			#transient attribute lineCount : Natural {
				doc /* Number of lines, derived from lines; #transient: not stored, so it has no column. */
			}
		}

		#entity item def PurchaseOrderLine {
			doc
			/*
			One line of a purchase order: which product (sku), how many, and at what unit price.

			Key choice: a composite primary key (parentOrder, lineNumber). A line has no identity outside its
			order, so its key is the order's key plus the line's position; several #primaryKey features form
			one composite key. It is an entity, not an aggregate root, because it changes only through its
			order.
			References: UML3Data::Entity; UML3Data::PrimaryKey.
			*/
			ref #primaryKey #foreignKey item parentOrder : PurchaseOrder[1] {
				doc
				/*
				The order this line belongs to: the first part of the composite key and a foreign key to
				PurchaseOrder. No @ForeignKey values are given, so onDelete keeps its default, noAction; that
				lines are removed with their order follows from the composition PurchaseOrder::lines.
				*/
			}
			#primaryKey attribute lineNumber : UInt16 {
				doc /* Position of the line within its order; the second part of the composite key. */
			}
			attribute sku : String {
				doc /* Stock-keeping unit of the ordered product, kept as a value inside the order aggregate. */
			}
			attribute quantity : UInt32 {
				doc /* Number of units ordered. */
			}
			attribute unitPrice : Money {
				doc /* Unit price at the time of ordering, so later price changes do not alter the order. */
			}
		}

		#relationship connection def AccountOrders {
			doc
			/*
			The 1 : N relationship between a customer account and the orders placed from it.

			The cardinality is given by the end multiplicities: exactly one account per order, any number of
			orders per account. PurchaseOrder::account is the same link seen from the order; declaring the
			relationship as well makes it a first-class element that entity-relationship diagrams and
			queries can show.
			References: UML3Data::Relationship; UML 2.5.1 Association; KerML 7.4.5; SysML 7.13.
			*/
			end [1] ref account : CustomerAccount {
				doc /* The account end: each order belongs to exactly one account. */
			}
			end [0..*] ref purchaseOrder : PurchaseOrder {
				doc /* The order end: an account has any number of orders, including none. */
			}
		}

		#entity item def Tag {
			doc
			/*
			A label that can be attached to purchase orders for grouping and search.

			Key choices: tagId is generated by the database (identity), because a tag is created there and no
			other system needs its id in advance; label is unique, so each tag text exists only once.
			References: UML3Data::Entity; UML3Data::KeyGeneration.
			*/
			#primaryKey attribute tagId : Int32 {
				doc /* Surrogate key, generated by the database as an identity column. */
				@PrimaryKey { generation = KeyGeneration::identity; }
			}
			#unique attribute label : String {
				doc /* The tag text; unique. */
			}
		}

		#relationship connection def OrderTagging {
			doc
			/*
			The M : N relationship between purchase orders and tags, with the time each tag was applied.

			Both ends are [0..*]: an order can have many tags, and a tag can be on many orders. The attribute
			taggedAt belongs to the link, not to either end, which makes the relationship an association
			class. In a relational schema it becomes a join table keyed by the two foreign keys; that table
			is not modeled in Physical.
			References: UML3Data::Relationship; UML 2.5.1 AssociationClass; SysML 7.13.
			*/
			end [0..*] ref taggedOrder : PurchaseOrder {
				doc /* The tagged order end: a tag can be on any number of orders. */
			}
			end [0..*] ref tag : Tag {
				doc /* The tag end: an order can have any number of tags. */
			}
			attribute taggedAt : Timestamp {
				doc /* When the tag was applied to the order. */
			}
		}
	}

	package Physical {
		doc
		/*
		The physical schema on PostgreSQL 16: the database, tables, columns, index and view that are deployed.

		Names follow SQL conventions (upper case with underscores), so the model reads like the DDL. Storage
		details that value types cannot express (SQL types, column defaults, index columns, referential
		actions) are metadata values. Only the customer account and purchase order tables are modeled, and
		each has a #mapsTo dependency to the logical element it implements.

		Contents:
		- Database: StoreDb (#database), with one item for each table and view.
		- Tables: CUSTOMER_ACCOUNT and PURCHASE_ORDER (#table; #column with @Column; @Index; @ForeignKey).
		- Database view: OPEN_ORDERS_V (#dbView with its query text).
		- Mapping: customerMapping and orderMapping (#mapsTo), explained by LogicalToPhysicalMapping.
		References: UML3Data::Database; UML3Data::Table; UML3Data::Column; UML3Data::MapsTo.
		*/

		#database part def StoreDb {
			doc
			/*
			The store's database: one PostgreSQL 16 schema holding the account and order tables and the
			open orders view.

			A part def, because a database is a deployed structure; its tables and views are nested items,
			so the model states which objects the schema contains.
			References: UML3Data::Database; SysML 7.11.
			*/
			attribute :>> engine = "PostgreSQL 16";
			item customerAccount : CUSTOMER_ACCOUNT {
				doc /* The CUSTOMER_ACCOUNT table of this database. */
			}
			item purchaseOrder : PURCHASE_ORDER {
				doc /* The PURCHASE_ORDER table of this database. */
			}
			item openOrders : OPEN_ORDERS_V {
				doc /* The OPEN_ORDERS_V view of this database. */
			}
		}

		#table item def CUSTOMER_ACCOUNT {
			doc
			/*
			Table of customer accounts; implements Logical::CustomerAccount (customerMapping).

			Mapping choices: each logical attribute becomes a column with the same meaning and value type, and
			@Column adds the SQL type. The billing address value object is flattened into BILLING_ columns of
			this table instead of a table of its own, because it has no identity; only BILLING_LINE1 is
			modeled here. CREATED_AT exists only in the physical model and is filled by the database.
			References: UML3Data::Table; UML3Data::Column.
			*/
			#column #primaryKey attribute ACCOUNT_ID : Uuid {
				doc /* Primary key column for CustomerAccount::accountId, in the native UUID type. */
				@Column { sqlType = "UUID"; }
			}
			#column #unique attribute EMAIL : EmailAddress {
				doc /* Unique column for CustomerAccount::email; VARCHAR(254) is the EmailAddress limit. */
				@Column { sqlType = "VARCHAR(254)"; }
			}
			#column attribute BILLING_LINE1 : Text[0..1] {
				doc /* First billing address line; nullable ([0..1]) because billingAddress is optional. */
				@Column { sqlType = "VARCHAR(200)"; }
			}
			#column attribute CREATED_AT : Timestamp {
				doc /* Row creation time, filled by the column default now(); TIMESTAMPTZ stores an instant. */
				@Column { sqlType = "TIMESTAMPTZ"; columnDefault = "now()"; }
			}
		}

		#table item def PURCHASE_ORDER {
			doc
			/*
			Table of purchase orders; implements Logical::PurchaseOrder (orderMapping).

			Mapping choices: the logical account reference becomes the foreign key column ACCOUNT_ID with the
			same onDelete = restrict. The order lines are not columns: they need a table of their own, which is
			not modeled here. lineCount is #transient and has no column. The two-column @Index supports
			listing one account's orders by date.
			References: UML3Data::Table; UML3Data::Index; UML3Data::ForeignKey.
			*/
			@Index { indexName = "ix_purchase_order_account_placed"; columnNames = ("ACCOUNT_ID", "PLACED_AT"); }
			#column #primaryKey attribute ORDER_ID : Uuid {
				doc /* Primary key column for PurchaseOrder::orderId. */
				@Column { sqlType = "UUID"; }
			}
			#column #foreignKey attribute ACCOUNT_ID : Uuid {
				doc
				/*
				Foreign key column for PurchaseOrder::account. A column holds only the key value, so the
				target is named by referencedTable and referencedColumn; onDelete = restrict repeats the
				logical rule, so the database itself refuses to delete an account row that orders refer to.
				*/
				@Column { sqlType = "UUID"; }
				@ForeignKey { referencedTable = "CUSTOMER_ACCOUNT"; referencedColumn = "ACCOUNT_ID"; onDelete = ReferentialAction::restrict; }
			}
			#column attribute PLACED_AT : Timestamp {
				doc /* Column for PurchaseOrder::placedAt, the time the order was placed. */
				@Column { sqlType = "TIMESTAMPTZ"; }
			}
		}

		#dbView item def OPEN_ORDERS_V {
			doc
			/*
			Database view of the orders that are still open, so that every query for open orders shares one
			definition.

			isMaterialized = false: the view is evaluated on every read, so it is never stale. queryText is
			opaque SQL text; the model does not check it against the columns of PURCHASE_ORDER. Only the
			ORDER_ID column of the view is modeled.
			References: UML3Data::DatabaseView.
			*/
			attribute :>> isMaterialized = false;
			attribute :>> queryText = "SELECT * FROM PURCHASE_ORDER WHERE STATUS = 'OPEN'";
			#column attribute ORDER_ID : Uuid {
				doc /* Id of an open order. */
			}
		}

		comment LogicalToPhysicalMapping about customerMapping, orderMapping
			/*
			Logical-to-physical mapping. Each #mapsTo dependency goes from the physical table (client) to the
			logical element it implements (supplier). The physical model depends on the logical model and not
			the reverse, so the logical model stays free of storage detail and could be mapped to another
			schema. The mapping is per table; how attributes become columns is described in each table's doc.
			customerMapping: CUSTOMER_ACCOUNT implements Logical::CustomerAccount.
			orderMapping: PURCHASE_ORDER implements Logical::PurchaseOrder.
			References: UML3Data::MapsTo; UML 2.5.1 Abstraction; SysML 7.3.
			*/

		#mapsTo dependency customerMapping from CUSTOMER_ACCOUNT to Logical::CustomerAccount {
			doc /* The CUSTOMER_ACCOUNT table implements the logical entity CustomerAccount. */
		}
		#mapsTo dependency orderMapping from PURCHASE_ORDER to Logical::PurchaseOrder {
			doc /* The PURCHASE_ORDER table implements the logical entity PurchaseOrder. */
		}
	}
}
