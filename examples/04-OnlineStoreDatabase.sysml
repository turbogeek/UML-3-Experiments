package OnlineStoreDatabase {
	doc
	/*
	 * Example 4 - Data modeling: logical (entity-relationship / DDD) and physical
	 * (relational) models, plus logical-to-physical mapping.
	 */
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Data::*;

	/* =================================================================
	 * Logical model
	 * ================================================================= */
	package Logical {

		#valueObject attribute def PostalAddress {
			attribute line1 : Text;
			attribute city : Text;
			attribute postalCode : String;
		}

		#aggregateRoot item def CustomerAccount {
			@Audited;
			#primaryKey attribute accountId : Uuid;
			#unique attribute email : EmailAddress { @Sensitivity { classification = "PII"; } }
			attribute billingAddress : PostalAddress[0..1];
		}

		#aggregateRoot item def PurchaseOrder {
			#primaryKey attribute orderId : Uuid;
			#indexed attribute placedAt : Timestamp;
			ref #foreignKey item account : CustomerAccount[1] {
				@ForeignKey { onDelete = ReferentialAction::restrict; }
			}
			item lines : PurchaseOrderLine[1..*] ordered;
			#transient attribute lineCount : Natural;
		}

		#entity item def PurchaseOrderLine {
			/* composite key: (order, lineNumber) */
			ref #primaryKey #foreignKey item parentOrder : PurchaseOrder[1];
			#primaryKey attribute lineNumber : UInt16;
			attribute sku : String;
			attribute quantity : UInt32;
			attribute unitPrice : Money;
		}

		/* 1 : N relationship; cardinality is the end multiplicity. */
		#relationship connection def AccountOrders {
			end [1] ref account : CustomerAccount;
			end [0..*] ref purchaseOrder : PurchaseOrder;
		}

		/* M : N relationship with attributes (becomes a join table). */
		#entity item def Tag {
			#primaryKey attribute tagId : Int32 { @PrimaryKey { generation = KeyGeneration::identity; } }
			#unique attribute label : String;
		}
		#relationship connection def OrderTagging {
			end [0..*] ref taggedOrder : PurchaseOrder;
			end [0..*] ref tag : Tag;
			attribute taggedAt : Timestamp;
		}
	}

	/* =================================================================
	 * Physical model (PostgreSQL)
	 * ================================================================= */
	package Physical {

		#database part def StoreDb {
			attribute :>> engine = "PostgreSQL 16";
			item customerAccount : CUSTOMER_ACCOUNT;
			item purchaseOrder : PURCHASE_ORDER;
			item openOrders : OPEN_ORDERS_V;
		}

		#table item def CUSTOMER_ACCOUNT {
			#column #primaryKey attribute ACCOUNT_ID : Uuid { @Column { sqlType = "UUID"; } }
			#column #unique attribute EMAIL : EmailAddress { @Column { sqlType = "VARCHAR(254)"; } }
			#column attribute BILLING_LINE1 : Text[0..1] { @Column { sqlType = "VARCHAR(200)"; } }
			#column attribute CREATED_AT : Timestamp { @Column { sqlType = "TIMESTAMPTZ"; columnDefault = "now()"; } }
		}

		#table item def PURCHASE_ORDER {
			@Index { indexName = "ix_purchase_order_account_placed"; columnNames = ("ACCOUNT_ID", "PLACED_AT"); }
			#column #primaryKey attribute ORDER_ID : Uuid { @Column { sqlType = "UUID"; } }
			#column #foreignKey attribute ACCOUNT_ID : Uuid {
				@Column { sqlType = "UUID"; }
				@ForeignKey { referencedTable = "CUSTOMER_ACCOUNT"; referencedColumn = "ACCOUNT_ID"; onDelete = ReferentialAction::restrict; }
			}
			#column attribute PLACED_AT : Timestamp { @Column { sqlType = "TIMESTAMPTZ"; } }
		}

		#dbView item def OPEN_ORDERS_V {
			attribute :>> isMaterialized = false;
			attribute :>> queryText = "SELECT * FROM PURCHASE_ORDER WHERE STATUS = 'OPEN'";
			#column attribute ORDER_ID : Uuid;
		}

		/* Logical-to-physical mapping */
		#mapsTo dependency customerMapping from CUSTOMER_ACCOUNT to Logical::CustomerAccount;
		#mapsTo dependency orderMapping from PURCHASE_ORDER to Logical::PurchaseOrder;
	}
}
