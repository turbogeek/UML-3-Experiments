package UML3BehaviorRequirements {
	doc
	/*
	BHV: requirements on the behavior of UML3 models: operations and their methods, activities, state
	machines, signals and time triggers, exceptions, active objects and concurrency, interactions between
	objects, behavior bodies and executable semantics.

	Contents:
	- Foundation: nativeBehaviors, operationMethods.
	- Activities and state machines: activityFlows, stateMachines.
	- Events: signalTriggers, timeAndChangeTriggers.
	- Errors: raisedExceptions, exceptionHandling.
	- Active objects: classifierBehaviors, callConcurrency, callTriggers.
	- Interactions, bodies and execution: objectInteractions, opaqueBodies, executableSemantics.
	- UseCases: how developers, architects and engineers use UML3 behavior.
	- Realization: the library elements that realize the done and tbc requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; UML 2.5.1 Behavior; SysML 7.17; SysML 7.18; KerML 9.2.14.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3IDL::*;

	requirement <'UML3-BHV-001'> nativeBehaviors {
		doc
		/*
		UML3 shall model behaviors, including activities, state machines, calculations and use cases, with the
		native SysML v2 action, state, calculation and use case definitions used as-is. Behavior definitions
		shall need no UML3 keyword, and no UML3 keyword shall make a behavior a class.
		Verified by: examples/06-OnlineStoreBehavior.sysml; tools/run_tests.py suite cameo; E05.
		*/
		@Rationale { text = "SysML v2 behaviors already are classifiers with features, specialization and performances, and KerML keeps objects disjoint from performances, so a class label on a behavior would be redundant and invalid (decision 2026-09-16)."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-BHV-002'> operationMethods {
		doc
		/*
		The method of an operation shall be a behavior bound to the operation, either as the body of the
		operation or as its redefinition in a specializing or realizing class. A behavior shall be able to call
		an operation of an object it references, and the method that runs shall be the one of the most
		specific class of that object.
		Verified by: examples/01-OnlineStoreDomain.sysml; tools/run_tests.py suite rules-tests.
		*/
		@Rationale { text = "Separating an operation from the methods that implement it is what makes interface realization and polymorphism work in object-oriented designs and in generated code."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-003'> activityFlows {
		doc
		/*
		UML3 shall model activities as native action definitions whose steps are ordered by control flow from
		a start to an end and exchange objects through their parameters, with decisions guarded by conditions,
		merges, forks, joins and loops.
		Verified by: examples/06-OnlineStoreBehavior.sysml; tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Activities describe algorithms, workflows and the steps of methods, and control nodes are needed to express choice, concurrency and repetition."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-004'> stateMachines {
		doc
		/*
		UML3 shall model state machines as native state definitions with entry, do and exit actions, nested and
		parallel states, and transitions that have a trigger, a guard and an effect.
		Verified by: examples/06-OnlineStoreBehavior.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "The lifecycle and protocol logic of objects is specified, reviewed and generated as state machines, and each of these elements has a counterpart in state machine implementations."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-005'> signalTriggers {
		doc
		/*
		UML3 shall provide signals, objects that a behavior sends asynchronously to a target. An accept action
		or a transition of the receiving behavior shall accept a signal as its trigger, selected by the signal
		type and optionally by a guard.
		Verified by: examples/06-OnlineStoreBehavior.sysml; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Asynchronous signals decouple objects in event-driven and embedded software, and the model must show which behavior sends and which behavior reacts to each signal."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-006'> timeAndChangeTriggers {
		doc
		/*
		Behaviors shall be able to be triggered after a duration, at a time instant and when a condition
		becomes true, and to constrain the time between occurrences, such as a deadline, with the durations
		and time instants of the SysML v2 Time and ISQ libraries.
		Verified by: traceability/uml2-to-uml3.json; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Timeouts, periodic tasks and deadlines are part of most software behavior and must use the same time semantics as the SysML v2 system model around the software."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-007'> raisedExceptions {
		doc
		/*
		UML3 shall let an operation declare the exceptions it may raise, where each exception is an exception
		type that is also a signal.
		Verified by: tools/run_tests.py suite idl-import; tools/run_tests.py suite cameo; library/UML3IDL.sysml.
		*/
		@Rationale { text = "Callers and generated code must know which errors an operation can report, as throws clauses and IDL raises clauses state."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-008'> exceptionHandling {
		doc
		/*
		UML3 shall define how a behavior raises an exception, how the exception propagates to the calling or
		enclosing behavior, and how a handler in an activity or a state machine catches it and continues.
		*/
		@Rationale { text = "Error handling is a large part of real software behavior, and without defined raising, propagation and handling a model can neither describe failure paths nor generate them."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-009'> classifierBehaviors {
		doc
		/*
		An active class shall own a classifier behavior, an action that it performs or a state machine that it
		exhibits, which runs during the lifetime of each of its instances.
		Verified by: examples/06-OnlineStoreBehavior.sysml; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "The classifier behavior is what makes an object active, and code generators turn it into the main loop or state machine of a thread, task or actor."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-010'> callConcurrency {
		doc
		/*
		UML3 shall state for each operation whether concurrent calls are allowed, serialized by the object or
		excluded by the callers, and whether a call on an active object is synchronous or queued.
		*/
		@Rationale { text = "Thread safety and message queuing are design decisions that code, reviews and tests depend on, and UML records them as the concurrency of operations."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-011'> callTriggers {
		doc
		/*
		A state machine or an activity of an object shall be able to accept a call of an operation of that
		object as a trigger and to return the results of the call to the caller.
		*/
		@Rationale { text = "Object designs often route operation calls into a state machine, as UML call events do, but SysML v2 has no call event, so UML3 must decide whether request signals suffice."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-012'> objectInteractions {
		doc
		/*
		UML3 shall model interactions between objects as native occurrence definitions with lifelines, event
		occurrences ordered by successions on each lifeline, and messages between event occurrences. The
		schemas, channels and quality of service of these messages shall be those specified by the messaging
		requirements.
		Verified by: examples/03-OnlineStoreMessaging.sysml; tools/run_tests.py suite cameo; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Sequence diagrams are the usual way to design and review collaborations, and native occurrences keep them consistent with the participating parts and the messages they exchange."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-BHV-013'> opaqueBodies {
		doc
		/*
		A behavior shall be able to carry its body, or a part of it, as text in a named language such as a
		programming language or OCL.
		Verified by: traceability/uml2-to-uml3.json; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "Method bodies are often written as code rather than modeled, and keeping them in the model together with their language keeps model and code aligned."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-BHV-014'> executableSemantics {
		doc
		/*
		UML3 behaviors shall have execution semantics, based on the KerML and SysML v2 semantic libraries, that
		are precise enough for a tool to simulate a UML3 model and for generated code to behave as the model.
		*/
		@Rationale { text = "Simulation and model-based testing find design errors before code exists, and generated code can only be trusted when it follows the semantics that simulation uses."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how developers, architects, integration, systems and test engineers use UML3 behavior.

		Contents:
		- DesignObjectBehavior: a software developer specifies how the objects of a component behave.
		- DesignConcurrentActiveObjects: a software architect designs the concurrent and timed parts.
		- SpecifyObjectInteractions: an architect and an integration engineer specify collaborations.
		- SimulateUML3Behavior: a systems or test engineer executes behaviors to check scenarios.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DesignObjectBehavior {
			doc
			/*
			A software developer specifies how the objects of a component behave: the methods of their
			operations, activities for algorithms and workflows, state machines for lifecycles, the signals they
			send and accept, the exceptions they raise and handle, and bodies written as code.
			*/
			subject environment : UML3Environment;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Each operation and lifecycle has a behavior precise enough to implement, generate or review. */
			}
		}

		use case def DesignConcurrentActiveObjects {
			doc
			/*
			A software architect designs the concurrent parts of the software: active objects and their
			classifier behaviors, the concurrency of calls, timeouts and periodic triggers, and how calls reach
			state machines.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Threads, queues and timing are explicit in the model and can be reviewed before implementation. */
			}
		}

		use case def SpecifyObjectInteractions {
			doc
			/*
			A software architect and an integration engineer specify how objects or services collaborate: the
			lifelines, the order of events on each lifeline and the messages between them, consistent with the
			signals and operations of the participants.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor integrator : IntegrationEngineer;
			objective {
				doc /* Collaborations are specified in an order that reviewers can follow and tests can check. */
			}
		}

		use case def SimulateUML3Behavior {
			doc
			/*
			A systems engineer or a test engineer executes the behaviors of a UML3 model, alone or inside a
			SysML v2 system model, to check scenarios before the code exists.
			*/
			subject environment : UML3Environment;
			actor systemsEngineer : SystemsEngineer;
			actor tester : TestEngineer;
			objective {
				doc /* Errors in activities, state machines and timing are found by simulation, not in the implementation. */
			}
		}

		#traces dependency from DesignObjectBehavior to 'UML3-BHV-001', 'UML3-BHV-002', 'UML3-BHV-003', 'UML3-BHV-004',
			'UML3-BHV-005', 'UML3-BHV-007', 'UML3-BHV-008', 'UML3-BHV-013', UML3StructureRequirements::'UML3-STR-005';
		#traces dependency from DesignConcurrentActiveObjects to 'UML3-BHV-006', 'UML3-BHV-009', 'UML3-BHV-010',
			'UML3-BHV-011', UML3StructureRequirements::'UML3-STR-002';
		#traces dependency from SpecifyObjectInteractions to 'UML3-BHV-002', 'UML3-BHV-005', 'UML3-BHV-012';
		#traces dependency from SimulateUML3Behavior to 'UML3-BHV-003', 'UML3-BHV-004', 'UML3-BHV-006', 'UML3-BHV-014';
	}

	package Realization {
		doc
		/*
		Realization: the UML3 and SysML v2 library elements that realize the done and tbc BHV requirements.

		Contents:
		- #realizes dependencies from library elements to BHV requirements.
		*/
		#realizes dependency from Actions::Action to 'UML3-BHV-001';
		#realizes dependency from States::StateAction to 'UML3-BHV-001';
		#realizes dependency from Calculations::Calculation to 'UML3-BHV-001';
		#realizes dependency from UML3Core::Operation to 'UML3-BHV-002';
		#realizes dependency from UML3Core::OperationMetadata to 'UML3-BHV-002';
		#realizes dependency from Actions::Action to 'UML3-BHV-003';
		#realizes dependency from Actions::DecisionAction to 'UML3-BHV-003';
		#realizes dependency from Actions::MergeAction to 'UML3-BHV-003';
		#realizes dependency from Actions::ForkAction to 'UML3-BHV-003';
		#realizes dependency from Actions::JoinAction to 'UML3-BHV-003';
		#realizes dependency from Actions::WhileLoopAction to 'UML3-BHV-003';
		#realizes dependency from States::StateAction to 'UML3-BHV-004';
		#realizes dependency from States::StateTransitionAction to 'UML3-BHV-004';
		#realizes dependency from UML3Core::Signal to 'UML3-BHV-005';
		#realizes dependency from UML3Core::SignalMetadata to 'UML3-BHV-005';
		#realizes dependency from Actions::SendAction to 'UML3-BHV-005';
		#realizes dependency from Actions::AcceptAction to 'UML3-BHV-005';
		#realizes dependency from Triggers::TriggerAfter to 'UML3-BHV-006';
		#realizes dependency from Triggers::TriggerAt to 'UML3-BHV-006';
		#realizes dependency from Triggers::TriggerWhen to 'UML3-BHV-006';
		#realizes dependency from Time::DurationOf to 'UML3-BHV-006';
		#realizes dependency from UML3Core::ExceptionType to 'UML3-BHV-007';
		#realizes dependency from UML3Core::ExceptionTypeMetadata to 'UML3-BHV-007';
		#realizes dependency from UML3IDL::RaisesDependency to 'UML3-BHV-007';
		#realizes dependency from UML3Core::ActiveClass to 'UML3-BHV-009';
		#realizes dependency from SysML::PerformActionUsage to 'UML3-BHV-009';
		#realizes dependency from SysML::ExhibitStateUsage to 'UML3-BHV-009';
		#realizes dependency from SysML::OccurrenceDefinition to 'UML3-BHV-012';
		#realizes dependency from SysML::EventOccurrenceUsage to 'UML3-BHV-012';
		#realizes dependency from Flows::Message to 'UML3-BHV-012';
		#realizes dependency from SysML::TextualRepresentation to 'UML3-BHV-013';
	}
}
