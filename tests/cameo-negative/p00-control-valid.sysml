/* EXPECT-CAMEO: OK
 * PREDICTION: loads (control - proves the probe mechanism can pass). Confidence: high. */
package UML3ProbeValid {
	private import UML3Core::*;
	private import UML3Data::*;
	#entity item def Account {
		#primaryKey attribute accountId : ScalarValues::String;
	}
}
