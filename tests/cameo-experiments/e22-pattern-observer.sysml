/* Experiment E22 probe (not a library): can UML3 represent a design pattern the way OMG SPMS 1.4 structures it,
 * with native SysML v2 constructs and existing UML3 keywords only? The Observer pattern is written as a pattern
 * definition with typed roles (SPMS Definitions), applied twice (SPMS Observations: a type-level and an
 * instance-level PatternInstance with its Bindings), documented with sections and an observation record,
 * related to another pattern (SPMS Relationships), and constrained by native requirements (the part of SPMS
 * Formalisms that a model can carry). Load after the UML3 libraries.
 * Predictions: tests/cameo-experiments/e22-predictions.json, recorded before the run. */
package UML3ProbePatternObserver {
	private import ScalarValues::*;
	private import SequenceFunctions::*;
	private import UML3Core::*;

	/* ---- SPMS Definitions: the pattern, its roles and the role types ---- */

	#interfaceType item def Subject {
		abstract #operation action attach { in observer : Observer; }
		abstract #operation action detach { in observer : Observer; }
		abstract #operation action notifyObservers;
	}

	#interfaceType item def Observer {
		abstract #operation action update;
	}

	/* the pattern definition (SPMS PatternDefinition): a template whose parameters are the roles */
	abstract #template part def ObserverPattern {
		/* SPMS Role, here with a type and a multiplicity, which SPMS roles do not have */
		abstract ref #templateParameter item observable : Subject[1];
		abstract ref #templateParameter item observers : Observer[1..*];
		/* a relationship between roles, which SPMS can express only in a formalism */
		connection notification connect observable to observers;
	}

	/* SPMS PatternSection: a named comment about the pattern definition */
	comment intent about ObserverPattern
		/* Intent: keep the objects that depend on one object informed of its changes without coupling it to their concrete types. */
	comment consequences about ObserverPattern
		/* Consequences: subject and observers vary independently; the order of notification is not specified. */

	/* ---- SPMS Formalisms, the part a model can carry: solution constraints as native requirements ---- */

	requirement def ObserversAreNotified {
		subject app : ObserverPattern;
		require constraint { size(app.observers) >= 1 }
	}

	/* structural conformance on the model level: the type that plays the observable role owns notifyObservers */
	requirement def SubjectTypeOwnsNotify {
		subject subjectType : KerML::Type;
		require constraint { subjectType.ownedFeature->exists { in f : KerML::Feature; f.name == "notifyObservers" } }
	}

	/* ---- the design that applies the pattern ---- */

	#classType item def OrderService :> Subject {
		action :>> attach;
		action :>> detach;
		action :>> notifyObservers;
	}

	#classType item def EmailNotifier :> Observer {
		action :>> update;
	}

	#classType item def AuditLog :> Observer {
		action :>> update;
	}

	/* ---- SPMS Observations: pattern instances with their bindings ---- */

	metadata def PatternObservation {
		attribute whenObserved : String;
		attribute observer : String;
		attribute tool : String;
	}

	/* type-level instance, the GoF class-diagram reading: roles bound by redefinition with design types; the
	 * observer role is fulfilled by two types, one subsetting feature each (SPMS Binding.fulfilledBy[*]) */
	part def OrderObservation :> ObserverPattern {
		@PatternObservation { whenObserved = "2026-09-17"; observer = "architect"; tool = "UML3 probe E22"; }
		ref item :>> observable : OrderService;
		ref item :>> observers : Observer[1..*];
		ref item emailObservers : EmailNotifier[0..*] :> observers;
		ref item auditObservers : AuditLog[0..*] :> observers;
		/* the metaobject of the observable role's player, for the model-level requirement */
		attribute subjectPlayer : KerML::Type = OrderService meta KerML::Type;
		satisfy requirement subjectConforms : SubjectTypeOwnsNotify by subjectPlayer;
	}

	/* instance-level instance, the UML CollaborationUse reading: roles bound to the items of a configuration */
	part def StoreConfiguration {
		item orderService : OrderService;
		item mailer : EmailNotifier;
		item audit : AuditLog;
		part orderObservation : ObserverPattern {
			ref item :>> observable = orderService;
			ref item :>> observers = (mailer, audit);
		}
		satisfy requirement notified : ObserversAreNotified by orderObservation;
	}

	/* ---- SPMS Relationships: a related pattern with its nature ---- */

	enum def Nature {
		enum childOf;
		enum parentOf;
		enum peerOf;
		enum requires;
		enum requiredBy;
		enum variantOf;
	}

	metadata def RelatedPattern {
		attribute nature : Nature;
	}

	abstract #template part def PublishSubscribePattern {
		abstract ref #templateParameter item publisher : Subject[1];
		abstract ref #templateParameter item subscribers : Observer[0..*];
	}

	dependency from PublishSubscribePattern to ObserverPattern {
		@RelatedPattern { nature = Nature::variantOf; }
	}
}
