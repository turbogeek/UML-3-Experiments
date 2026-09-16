/* EXPECT-CAMEO: OK  (observed 2026-09-16: builder accepts; UML3 APPLICABILITY check rejects)
 * ORIGINAL PREDICTION (refuted): error. #mapsTo restricts annotatedElement to SysML::Dependency; applying it to an item def -> error. Confidence: medium. */
package UML3ProbeMapsToOnItemDef {
	private import UML3Data::*;
	#mapsTo item def Customer;
}
