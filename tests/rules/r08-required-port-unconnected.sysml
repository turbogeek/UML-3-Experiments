/* EXPECT-RULES: R08 */
package RulesR08 {
	private import UML3Components::*;
	port def P :> ServicePort;
	#component part def Needy { #required port dep : ~P; }
	#subsystem part def Unwired { part needy : Needy; }
}
