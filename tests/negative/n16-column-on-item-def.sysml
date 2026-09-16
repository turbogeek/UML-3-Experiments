/* EXPECT: APPLICABILITY  (CATIA Magic builder accepts this silently - see tests/cameo-negative)
 * PREDICTION: #column (baseType columns : DataValue) on an item def makes an Item subclassify DataValue -> error. Confidence: low (may be accepted). */
package N16ProbeColumnOnItemDef {
	private import UML3Data::*;
	#column item def CUSTOMER;
}
