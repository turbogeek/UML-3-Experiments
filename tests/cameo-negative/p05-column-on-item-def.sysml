/* EXPECT-CAMEO: OK  (observed 2026-09-16: builder accepts; UML3 APPLICABILITY check rejects)
 * ORIGINAL PREDICTION (refuted): error. #column (baseType columns : DataValue) on an item def makes an Item subclassify DataValue -> error. Confidence: low (may be accepted). */
package UML3ProbeColumnOnItemDef {
	private import UML3Data::*;
	#column item def CUSTOMER;
}
