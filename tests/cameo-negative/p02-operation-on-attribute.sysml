/* EXPECT-CAMEO: ERROR
 * PREDICTION: #operation (baseType is an action usage) on an attribute usage -> attribute subsets an action -> error. Confidence: medium. */
package UML3ProbeOperationOnAttribute {
	private import UML3Core::*;
	item def Customer {
		#operation attribute rename : ScalarValues::String;
	}
}
