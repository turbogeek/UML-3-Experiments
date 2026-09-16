/* EXPECT-RULES: R07 */
package RulesR07 {
	private import UML3Components::*;
	port def P :> ServicePort;
	#component part def Wrong {
		#provided port offered : ~P;
		#required port needed : P;
	}
}
