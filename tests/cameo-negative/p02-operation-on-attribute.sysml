/* EXPECT-CAMEO: OK  (observed 2026-09-16: builder accepts; UML3 APPLICABILITY check rejects)
 * ORIGINAL PREDICTION (refuted): error. #operation (baseType is an action usage) on an attribute usage -> attribute subsets an action -> error. Confidence: medium. */
package UML3ProbeOperationOnAttribute {
	private import UML3Core::*;
	item def Customer {
		#operation attribute rename : ScalarValues::String;
	}
}
