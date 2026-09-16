/* EXPECT-CAMEO: ERROR
 * PREDICTION: #mapsTo restricts annotatedElement to SysML::Dependency; applying it to an item def -> error. Confidence: medium. */
package UML3ProbeMapsToOnItemDef {
	private import UML3Data::*;
	#mapsTo item def Customer;
}
