/* EXPECT-CAMEO: ERROR
 * PREDICTION: #column (baseType columns : DataValue) on an item def makes an Item subclassify DataValue -> error. Confidence: low (may be accepted). */
package UML3ProbeColumnOnItemDef {
	private import UML3Data::*;
	#column item def CUSTOMER;
}
