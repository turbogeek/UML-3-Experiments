/* EXPECT-RULES: R04 */
package RulesR04 {
	private import UML3Core::*;
	item def A; item def B; item def C;
	#association connection def Ternary {
		end ref a : A;
		end ref b : B;
		end ref c : C;
	}
}
