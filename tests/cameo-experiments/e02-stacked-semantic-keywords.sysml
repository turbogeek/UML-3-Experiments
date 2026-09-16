/* EXPECT-CAMEO: OK
 * Experiment E02: when several SEMANTIC keywords are stacked on one element, does CATIA Magic
 * apply the implied specialization of each one (KerML 9.2.16), or only of the first?
 * Trigger: M15 failed - '#column #primaryKey attribute ACCOUNT_ID' subsets columns but not
 * primaryKeyFeatures. Predictions: e02-predictions.json (committed before running). */
package UML3ExperimentStackedKeywords {
	private import UML3Types::*;
	private import UML3Data::*;

	#table item def STACKED {
		/* A: column first, key second (the M15 shape) */
		#column #primaryKey attribute A : Uuid;
		/* B: same keywords, reversed order */
		#primaryKey #column attribute B : Uuid;
		/* C: first keyword as prefix, second in body form */
		#column attribute C : Uuid { @PrimaryKey; }
		/* D: single keyword (positive control) */
		#primaryKey attribute D : Uuid;
		/* E: two markers of the same pattern (both Anything-typed bases) */
		#unique #indexed attribute E : Uuid;
	}
}
