/* EXPECT: APPLICABILITY  (CATIA Magic builder accepts this silently - see tests/cameo-negative)
 * PREDICTION: #operation (baseType is an action usage) on an attribute usage -> attribute subsets an action -> error. Confidence: medium. */
package N13ProbeOperationOnAttribute {
	private import UML3Core::*;
	item def Customer {
		#operation attribute rename : ScalarValues::String;
	}
}
