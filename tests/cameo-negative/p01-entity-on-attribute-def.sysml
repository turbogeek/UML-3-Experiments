/* EXPECT-CAMEO: OK  (observed 2026-09-16: builder accepts; UML3 APPLICABILITY check rejects)
 * ORIGINAL PREDICTION (refuted): error. #entity (baseType is an item usage) on an attribute def makes a DataType subclassify a Class -> error. Confidence: high. */
package UML3ProbeEntityOnAttributeDef {
	private import UML3Data::*;
	#entity attribute def Money;
}
