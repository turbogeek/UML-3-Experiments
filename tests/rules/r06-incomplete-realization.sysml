/* EXPECT-RULES: R06 */
package RulesR06 {
	private import UML3Core::*;
	#interfaceType item def Api {
		abstract #operation action doIt;
		abstract #query calc ask { return r : ScalarValues::Boolean; }
	}
	#classType part def PartialImpl :> Api {
		action :>> doIt;
	}
}
