/* EXPECT-RULES: R03  - ref FK to a non-entity (ERROR), unknown referencedTable (ERROR), column FK without referencedTable (WARNING) */
package RulesR03 {
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Data::*;
	item def PlainThing;
	#entity item def Holder {
		#primaryKey attribute holderId : Uuid;
		ref #foreignKey item thing : PlainThing[1];
	}
	#table item def ORDERS {
		#column #primaryKey attribute ORDER_ID : Uuid;
		#column #foreignKey attribute CUSTOMER_ID : Uuid { @foreignKey { referencedTable = "NO_SUCH_TABLE"; } }
		#column #foreignKey attribute OTHER_ID : Uuid;
	}
}
