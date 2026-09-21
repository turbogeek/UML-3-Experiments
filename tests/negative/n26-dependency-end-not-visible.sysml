/* EXPECT: DEPENDENCY  - the ends of a dependency must resolve: 'Sensr' is a misspelling of Sensor and 'RFP-9.9' does
 * not exist. The ANTLR validator accepts both, and check_names used to check only qualified dependency ends, so a
 * trace or refinement to a missing element passed every local check (found while tracing DogFoodUML3 refinements). */
package N26DependencyEndNotVisible {
	private import ModelingMetadata::*;
	part def Sensor;
	requirement <'REQ-1'> sensing;
	dependency from Sensr to 'REQ-1';
	#refinement dependency from sensing to 'RFP-9.9';
}
