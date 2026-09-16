/* EXPECT-CAMEO: OK
 * Experiment E03 (follow-up to E02): is the rule "only the FIRST semantic metadata of an element is applied",
 * independent of prefix vs body form? Predictions: e03-predictions.json (committed before running). */
package UML3ExperimentBodyKeywords {
	private import UML3Types::*;
	private import UML3Data::*;

	#table item def BODYFORM {
		/* F: single semantic keyword, body form only */
		attribute F : Uuid { @PrimaryKey; }
		/* G: two semantic keywords, both body form */
		attribute G : Uuid { @Unique; @Indexed; }
	}
}
