package UML3ValidationRequirements {
	doc
	/*
	VAL: requirements on validating that a software design meets the needs of its stakeholders: use cases and
	their traces to requirements, stakeholder concerns and acceptance criteria, scenarios that walk through
	the design and their simulation, and reviews with their findings and acceptance decisions.
	Checking that a model is well-formed and consistent is in UML3VerificationRequirements (VER).

	Contents:
	- Use cases: useCaseModel, useCaseRequirementTraces, useCaseComposition.
	- Stakeholders: stakeholderConcerns, concernCoverage, acceptanceCriteria.
	- Scenarios: scenarioModels, scenarioUseCaseLinks, scenarioSimulation.
	- Reviews: reviewRecords, acceptanceStatus.
	- UseCases: how product owners, architects and reviewers validate a design with its stakeholders.
	- Realization: the SysML v2 and UML3 elements that realize the done requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/UML2-to-UML3-Traceability.md; SysML 7.21; SysML 7.25.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-VAL-001'> useCaseModel {
		doc
		/*
		UML3 shall model how actors use a software system with native SysML v2 use case definitions and usages,
		each with its subject, its actors and an objective that states what the actors obtain, and shall add no
		UML3 keyword for use cases.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite cameo; tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "SysML v2 use cases already have subjects, actors and objectives and can be included and specialized; a UML3 copy would create a second way to say the same thing."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VAL-002'> useCaseRequirementTraces {
		doc
		/*
		A use case shall trace the requirements it needs, and UML3 tooling shall report use cases without a
		subject, an actor, an objective or a traced requirement, and requirements that no use case traces.
		Verified by: tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "A requirement that no use case needs may have no stakeholder, and a use case that needs no requirement is not yet understood; both are questions for the product owner."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VAL-003'> useCaseComposition {
		doc
		/*
		UML3 shall express the common and optional parts of use cases with native included use cases, an optional
		part being an inclusion with multiplicity 0..1 or a guarded succession, and shall not add an extend
		relationship.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "SysML v2 has no extend relationship; inclusion with a multiplicity keeps one mechanism with defined semantics instead of an emulation without any."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VAL-004'> stakeholderConcerns {
		doc
		/*
		UML3 shall model the stakeholders of a software system and their concerns with native SysML v2
		stakeholders and concern definitions, and shall relate each concern to the requirements and use cases
		that address it.
		*/
		@Rationale { text = "Validation asks whether a design answers what each stakeholder cares about, and that question cannot be asked of a model that does not record the stakeholders and their concerns."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-VAL-005'> concernCoverage {
		doc
		/*
		UML3 tooling shall report the stakeholder concerns that no requirement, use case or viewpoint addresses.
		*/
		@Rationale { text = "An unaddressed concern is a gap that stakeholders otherwise find late, in acceptance, when it is expensive to close."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-VAL-006'> acceptanceCriteria {
		doc
		/*
		UML3 shall let a product owner state the acceptance criteria of a requirement or use case as constraints
		that evaluate to true or false for a design or a test result, and each criterion shall be linked to the
		requirement or use case it belongs to.
		*/
		@Rationale { text = "Criteria written only as prose cannot be evaluated or traced to the tests that check them; SysML v2 constraints can be both."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-VAL-007'> scenarioModels {
		doc
		/*
		A scenario shall be expressible over the elements of a software design, either as a native SysML v2
		interaction (an occurrence definition whose lifelines are parts typed by design elements and whose
		messages connect their event occurrences) or as an action flow whose actions design elements perform.
		Verified by: tools/run_tests.py suite traceability; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Walking through a scenario over the real design elements shows missing operations, messages and responsibilities before they are built."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VAL-008'> scenarioUseCaseLinks {
		doc
		/*
		Each scenario used to validate a use case shall be linked to that use case, so that the scenarios of a
		use case can be found from the use case and walked through.
		*/
		@Rationale { text = "Without the link a reviewer cannot tell which use cases have been walked through against the design and which have not."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-VAL-009'> scenarioSimulation {
		doc
		/*
		UML3 shall define execution semantics for scenarios that are sufficient for a tool to simulate a scenario
		against the design, sending and accepting its messages, taking its state transitions and performing its
		actions, and to report the messages, states and results the simulation produced.
		*/
		@Rationale { text = "Stakeholders validate behavior more reliably by watching it run than by reading diagrams, and simulation finds deadlocks and missing transitions that walkthroughs miss."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-VAL-010'> reviewRecords {
		doc
		/*
		UML3 shall record review findings as model content attached to the reviewed elements, each with its
		text, severity, reviewer, decision and status and the version of the model that was reviewed.
		*/
		@Rationale { text = "Findings kept outside the model lose their link to the elements they concern and cannot be checked again when those elements change."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-VAL-011'> acceptanceStatus {
		doc
		/*
		UML3 shall record whether the stakeholders have accepted each requirement and use case, separately from
		its implementation status, and UML3 tooling shall report the accepted, rejected and pending ones.
		*/
		@Rationale { text = "Implemented is not the same as accepted: a done requirement can still be the wrong one, and only stakeholder acceptance closes validation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	package UseCases {
		doc
		/*
		UseCases: how product owners, architects and reviewers validate a design with its stakeholders.

		Contents:
		- CaptureStakeholderNeeds: a product owner and an architect record stakeholders, concerns, use cases and
		  acceptance criteria and trace them to requirements.
		- WalkThroughDesignScenarios: an architect walks through or simulates the scenarios of each use case
		  over the design.
		- ReviewDesignWithStakeholders: a reviewer and the product owner record findings and acceptance.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def CaptureStakeholderNeeds {
			doc
			/*
			A product owner and a software architect record the stakeholders of a software system and their
			concerns, the use cases with their actors and objectives, and the acceptance criteria, and trace the
			use cases and concerns to the requirements.
			*/
			subject environment : UML3Environment;
			actor owner : ProductOwner;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Every requirement serves a use case or a stakeholder concern, and every use case has criteria for its acceptance. */
			}
		}

		use case def WalkThroughDesignScenarios {
			doc
			/*
			A software architect models the scenarios of each use case as interactions or action flows over the
			design elements, links them to the use case, walks through them with the product owner and, where a
			tool supports it, simulates them.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor owner : ProductOwner;
			objective {
				doc /* Each use case has scenarios that run through the design without missing elements, operations or messages. */
			}
		}

		use case def ReviewDesignWithStakeholders {
			doc
			/*
			A reviewer and the product owner review a version of the design against its use cases and acceptance
			criteria, record their findings on the reviewed elements and record which requirements and use cases
			the stakeholders accept.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			actor owner : ProductOwner;
			objective {
				doc /* The acceptance of each requirement and use case is recorded together with the findings that led to it. */
			}
		}

		#traces dependency from CaptureStakeholderNeeds to 'UML3-VAL-001', 'UML3-VAL-002', 'UML3-VAL-003', 'UML3-VAL-004',
			'UML3-VAL-005', 'UML3-VAL-006';
		#traces dependency from WalkThroughDesignScenarios to 'UML3-VAL-007', 'UML3-VAL-008', 'UML3-VAL-009',
			UML3ViewRequirements::'UML3-VIEW-004';
		#traces dependency from ReviewDesignWithStakeholders to 'UML3-VAL-006', 'UML3-VAL-010', 'UML3-VAL-011',
			UML3ReportRequirements::'UML3-RPT-008';
	}

	package Realization {
		doc
		/*
		Realization: the SysML v2 and UML3 elements that realize the done and tbc VAL requirements.

		Contents:
		- #realizes dependencies to VAL requirements. A requirement met by a native SysML v2 construct used as-is
		  is realized by the SysML metaclass, as in the UML 2.x to UML3 traceability.
		*/
		#realizes dependency from SysML::UseCaseDefinition to 'UML3-VAL-001';
		#realizes dependency from SysML::UseCaseUsage to 'UML3-VAL-001';
		#realizes dependency from UML3Core::TracesDependency to 'UML3-VAL-002';
		#realizes dependency from SysML::IncludeUseCaseUsage to 'UML3-VAL-003';
		#realizes dependency from SysML::OccurrenceDefinition to 'UML3-VAL-007';
		#realizes dependency from SysML::EventOccurrenceUsage to 'UML3-VAL-007';
		#realizes dependency from SysML::ActionDefinition to 'UML3-VAL-007';
	}
}
