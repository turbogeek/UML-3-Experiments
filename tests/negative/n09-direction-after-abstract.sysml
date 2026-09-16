/* EXPECT: LINT  - direction after abstract (Cameo: no viable alternative at input abstractout) */
package N09 {
	private import ScalarValues::*;
	port def P {
		abstract out item msg : ScalarValues::String[0..*];
	}
}
