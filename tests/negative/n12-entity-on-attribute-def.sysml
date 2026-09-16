/* EXPECT: APPLICABILITY  (CATIA Magic builder accepts this silently - see tests/cameo-negative)
 * PREDICTION: #entity (baseType is an item usage) on an attribute def makes a DataType subclassify a Class -> error. Confidence: high. */
package N12ProbeEntityOnAttributeDef {
	private import UML3Data::*;
	#entity attribute def Money;
}
