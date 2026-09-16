/* EXPECT-CAMEO: ERROR
 * PREDICTION: #entity (baseType is an item usage) on an attribute def makes a DataType subclassify a Class -> error. Confidence: high. */
package UML3ProbeEntityOnAttributeDef {
	private import UML3Data::*;
	#entity attribute def Money;
}
