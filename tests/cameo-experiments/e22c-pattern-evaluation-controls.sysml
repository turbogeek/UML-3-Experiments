/* Experiment E22 evaluation controls (not a library): requirements that must evaluate to FALSE, so that a true
 * result for the probe's own requirements (P5) cannot be an artifact of the evaluator. The instance-level control
 * asks for three observers where the configuration binds two; the model-level control asks for an operation that
 * OrderService does not own. Load after e22-pattern-observer.sysml.
 * Predictions: tests/cameo-experiments/e22-predictions.json (P5), recorded before the run. EXPECT-CAMEO: OK */
package UML3ProbePatternEvaluationControls {
	private import SequenceFunctions::*;
	private import ControlFunctions::*;
	private import UML3ProbePatternObserver::*;

	requirement def AtLeastThreeObservers {
		subject app : ObserverPattern;
		require constraint { size(app.observers) >= 3 }
	}

	requirement def SubjectTypeOwnsNotifyAll {
		subject subjectType : KerML::Type;
		require constraint { subjectType.ownedFeature->exists { in f : KerML::Feature; f.name == "notifyAll" } }
	}

	part def ControlConfiguration :> StoreConfiguration {
		satisfy requirement tooFew : AtLeastThreeObservers by orderObservation;
	}

	part def ControlObservation :> OrderObservation {
		satisfy requirement noNotifyAll : SubjectTypeOwnsNotifyAll by subjectPlayer;
	}
}
