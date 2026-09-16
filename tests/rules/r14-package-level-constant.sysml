/* EXPECT-RULES: R14  - package-level constant (CATIA Magic validateFeatureConstantIsVariable) */
package RulesR14 {
	private import ScalarValues::*;
	constant attribute LIMIT : Integer = 5;
	item def Holder {
		constant attribute fine : Integer = 1;
	}
}
