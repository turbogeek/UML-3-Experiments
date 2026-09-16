/* EXPECT: APPLICABILITY  (CATIA Magic builder accepts this silently - see tests/cameo-negative)
 * PREDICTION: #mapsTo restricts annotatedElement to SysML::Dependency; applying it to an item def -> error. Confidence: medium. */
package N14ProbeMapsToOnItemDef {
	private import UML3Data::*;
	#mapsTo item def Customer;
}
