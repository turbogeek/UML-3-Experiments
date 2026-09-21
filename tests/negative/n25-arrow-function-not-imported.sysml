/* EXPECT: FUNCTION  - a function invoked with the arrow notation must be visible: 'exists' is defined in
 * ControlFunctions, which this package does not import. CATIA Magic rejects the load ("couldn't resolve reference to
 * Element 'exists'"); the ANTLR validator accepts it. Found by experiment E22. */
package N25ArrowFunctionNotImported {
	private import ScalarValues::*;
	part def Holder {
		attribute values : Integer[0..*];
		assert constraint { values->exists { in v : Integer; v > 0 } }
	}
}
