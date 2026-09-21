/* Experiment E22 control probe (not a library): a pattern role bound to a type that does not conform to the role
 * type. EmailNotifier plays the observable role although it does not specialize Subject. KerML derives the types of
 * a redefining feature from its own typings AND the types of the feature it redefines, so the prediction is that
 * this is not an error but an intersection (observable must be both a Subject and an EmailNotifier), which only a
 * UML3 design rule can report. Load after e22-pattern-observer.sysml.
 * Predictions: tests/cameo-experiments/e22-predictions.json, recorded before the run. EXPECT-CAMEO: OK */
package UML3ProbePatternWrongBinding {
	private import UML3ProbePatternObserver::*;

	part def MisboundObservation :> ObserverPattern {
		ref item :>> observable : EmailNotifier;
		ref item :>> observers : AuditLog[1..*];
	}
}
