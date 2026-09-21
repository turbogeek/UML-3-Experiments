package UML3PatternRequirements {
	doc
	/*
	PAT: requirements on design, architecture and integration patterns in UML3: pattern definitions with typed
	roles, role relationships, documentation sections, the concerns a pattern addresses and the requirements its
	solution must meet; pattern instances at type and instance level with their role bindings, composition and
	observations; conformance checks; relationships between patterns, catalogs and anti-patterns; views, tool
	support and queries; and alignment and interchange with the OMG Structured Patterns Metamodel Standard (SPMS)
	and UML 2.5.1 collaborations.
	Patterns build on the native requirement constructs of UML3RequirementModelingRequirements (REQ): the
	solution of a pattern is stated as requirements, and applying a pattern satisfies them. docs/PATTERNS.md
	maps SPMS 1.4 onto SysUML and records the evidence (experiment E22). Individual integration patterns as
	components are in UML3MessagingRequirements (MSG).

	Contents:
	- Pattern definitions: patternDefinitions, typedRoles, roleCollaboration, patternSections, patternConcerns,
	  patternRequirements.
	- Pattern instances: typeLevelInstances, instanceLevelInstances, compositePatterns, patternObservations.
	- Conformance: roleBindingConformance, everyRoleBound, roleContracts, roleConnectionCorrespondence,
	  modelLevelConformance.
	- Relationships and catalogs: patternRelationships, patternCatalogs, antiPatterns, patternDetection.
	- Views and tools: patternViews, applyPatternCommand, patternQueries.
	- Standards: spmsInterchange, spmsKerMLAlignment, collaborationMapping.
	- UseCases: how architects, developers, reviewers and tool vendors define, apply, check and exchange patterns.
	References: docs/PATTERNS.md; docs/REQUIREMENTS-GUIDE.md; SysML 7.13; SysML 7.21; SysML 7.27; KerML 9.2.16.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-PAT-001'> patternDefinitions {
		doc
		/*
		SysUML shall represent a pattern definition as an abstract definition whose features are the roles of the
		pattern, marked by a SysUML keyword that identifies it as a pattern, so that pattern definitions are ordinary
		model elements that can be specialized, queried, documented and kept in libraries.
		*/
		@Rationale { text = "SPMS PatternDefinition and UML Collaboration both describe a solution as roles; as a definition with role features, a pattern gets specialization, typing and queries from SysML v2 instead of a separate metamodel. E22 shows the structure with the existing #template keyword; a dedicated keyword lets a query find all patterns."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-002'> typedRoles {
		doc
		/*
		Each role of a pattern definition shall have a type and a multiplicity. The type of a role shall be a SysUML
		definition, typically an #interfaceType, whose features state what an element must provide to play the
		role.
		*/
		@Rationale { text = "SPMS roles are names only, so a tool cannot tell whether an element may play a role; a role type makes the contract explicit and lets the existing design rules check it."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-003'> roleCollaboration {
		doc
		/*
		A pattern definition shall be able to state how its roles work together: connections, flows and messages
		between role features, and the behavior of the collaboration as an interaction or an action over the
		roles.
		*/
		@Rationale { text = "The relationships between roles are the heart of most patterns, yet SPMS can express them only in an external formalism; UML collaborations and SysML v2 features express them in the model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-004'> patternSections {
		doc
		/*
		The documentation of a pattern shall be recorded as named sections about the pattern definition, such as
		intent, problem, context, forces, solution, consequences, known uses and related patterns, without a fixed
		list, so that each pattern community can use its own template.
		*/
		@Rationale { text = "SPMS PatternSection deliberately fixes no template (the GoF and Hillside templates are examples); named comments and metadata keep the sections queryable and exportable to SPMS."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-005'> patternConcerns {
		doc
		/*
		The problem and the forces that a pattern resolves shall be expressible as SysML v2 concerns that the
		pattern definition addresses, so that a stakeholder concern in a design leads to the patterns that
		address it.
		*/
		@Rationale { text = "Choosing a pattern is answering a concern; modeling forces as concerns connects pattern catalogs to the stakeholder model of VAL-004 and makes the choice traceable."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-006'> patternRequirements {
		doc
		/*
		The constraints that a correct application of a pattern must meet shall be stated as requirement
		definitions whose subject is typed by the pattern definition, and each pattern instance shall satisfy the
		requirements of its pattern.
		*/
		@Rationale { text = "Native requirements give patterns what SPMS leaves to external formalisms and UML to prose: a checkable statement of the solution, and satisfaction as the claim that an application meets it (E22: ObserversAreNotified)."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-007'> typeLevelInstances {
		doc
		/*
		A pattern shall be applicable at type level, as in a class diagram of the pattern: a specialization of the
		pattern definition redefines each role with the design type that plays it, and a role played by several
		types is bound through features that subset the role, one per type.
		*/
		@Rationale { text = "Design patterns are usually stated and reviewed as class structures; binding by redefinition reuses SysUML template binding (STR-011) and gives SPMS Binding.fulfilledBy with several elements a typed form."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-008'> instanceLevelInstances {
		doc
		/*
		A pattern shall be applicable at instance level, as a UML collaboration use: a usage of the pattern
		definition inside a context binds each role to features of that context, and one feature may play roles
		in several pattern instances.
		*/
		@Rationale { text = "Architecture and integration patterns are applied to configurations of parts rather than to types; the instance-level reading is what UML CollaborationUse expresses."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-009'> compositePatterns {
		doc
		/*
		A pattern composed of other patterns shall contain instances of them and bind the roles that one element
		plays in several of them with binding connectors, as Decorator binds the Recurser of ObjectRecursion to
		the OriginalBehavior of ExtendMethod.
		*/
		@Rationale { text = "Composition is how pattern languages build larger patterns; SPMS expresses role equality only in its notation and in prose, while a binding connector makes it part of the model."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-010'> patternObservations {
		doc
		/*
		A pattern instance shall be able to record how it was found or applied, with when, by whom and by which
		tool, and a pattern definition shall be able to record known uses with a narrative, a reference and the
		element that shows the use.
		*/
		@Rationale { text = "SPMS PatternObservation and KnownUse make pattern evidence traceable, which matters when instances are found by analysis tools rather than drawn by the architect."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-011'> roleBindingConformance {
		doc
		/*
		SysUML tooling shall report each role that is bound to an element whose type does not conform to the role
		type.
		*/
		@Rationale { text = "KerML derives the types of a redefining feature from its own typings and from the feature it redefines, so a non-conforming binding silently narrows the role to an intersection instead of failing (confirmed in CATIA Magic, E22 P4); only a rule reports it."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-012'> everyRoleBound {
		doc
		/*
		SysUML tooling shall report each pattern instance that leaves a role with a lower multiplicity above zero
		unbound.
		*/
		@Rationale { text = "UML states this as the constraint every_role of CollaborationUse and SPMS as the rule that an instance has a binding for each role; an unbound role means the pattern is not applied."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-013'> roleContracts {
		doc
		/*
		SysUML tooling shall report each element that plays a role whose type is an #interfaceType without
		implementing every operation of that type.
		Verified by: tools/run_tests.py suite rules-tests; tests/rules/r06-incomplete-realization.sysml; tests/cameo-experiments/e22-pattern-observer.sysml.
		*/
		@Rationale { text = "The contract of a role is the core of pattern conformance. Design rule R06 already reports an incomplete realization, and E22 showed that it catches a class playing the observable role without notifyObservers; its fixture is general, not pattern-specific."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-014'> roleConnectionCorrespondence {
		doc
		/*
		SysUML tooling shall report each connection between roles of a pattern that has no corresponding
		connection, of the same or a more general type, between the elements bound to those roles in an
		instance-level pattern instance.
		*/
		@Rationale { text = "This is the connectors constraint of UML CollaborationUse: without it, a configuration can claim a pattern whose parts are not actually wired as the pattern requires."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-015'> modelLevelConformance {
		doc
		/*
		Structural conformance rules of a pattern, such as a role player owning an operation, shall be expressible
		as requirements over metaobjects of the reflective KerML library, so that a SysML v2 tool can evaluate
		them without UML3-specific checkers.
		*/
		@Rationale { text = "Checker rules are tied to one tool; constraints in the model travel with it. CATIA Magic's evaluation engine evaluates such a requirement correctly, true for the Observer probe and false for a missing operation (E22 P5); the pattern library still has to provide them."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-016'> patternRelationships {
		doc
		/*
		Relationships between pattern definitions shall record their nature, with at least the SPMS natures
		child of, parent of, peer of, requires, required by, variant of, can also be, mitigated by, mitigates,
		compensated by and compensates, and a community shall be able to add natures, categories and perspectives.
		*/
		@Rationale { text = "Pattern languages are defined by these relationships; keeping the SPMS vocabulary makes SysUML catalogs exchangeable, and extensibility is what SPMS itself asks of communities."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-017'> patternCatalogs {
		doc
		/*
		SysUML shall provide pattern catalogs as library packages: the object-oriented design patterns of Gamma et
		al., common architecture patterns such as layers, broker and pipes and filters, the enterprise integration
		patterns of UML3-MSG-014, and domain-driven design patterns such as repository and aggregate.
		*/
		@Rationale { text = "A pattern standard is only useful with patterns in it; shipped catalogs give architects a common vocabulary and give the conformance rules something to check."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-018'> antiPatterns {
		doc
		/*
		SysUML shall represent anti-patterns as pattern definitions marked as anti-patterns, related to the patterns
		that mitigate or compensate them, and shall be able to import the weakness catalogs of the CISQ quality and
		security measures, which are published as SPMS data.
		*/
		@Rationale { text = "Reviews look for anti-patterns more often than for patterns; SPMS has no anti-pattern class but supports them through relationship natures, and the CISQ measures already publish hundreds of weaknesses in SPMS form."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-019'> patternDetection {
		doc
		/*
		SysUML tooling shall be able to detect instances of a pattern or an anti-pattern in a model, record each one
		as a pattern instance with its bindings and an observation, and state the detection rule as the pattern's
		formal definition.
		*/
		@Rationale { text = "SPMS was created for architecture-driven modernization, where patterns are found in existing systems rather than drawn; how far detection can go on SysML v2 models is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-020'> patternViews {
		doc
		/*
		SysUML shall provide views of pattern instances that show the pattern with its roles and the elements bound
		to them, in a collapsed form that names the pattern and an expanded form that shows the role structure,
		corresponding to the SPMS pattern instance notation and the UML collaboration use.
		*/
		@Rationale { text = "Patterns explain designs only if a reader can see them on a diagram; SPMS defines its notation on Diagram Definition, which SysML v2 does not use, so the views are SysUML view definitions and tool customizations."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-PAT-021'> applyPatternCommand {
		doc
		/*
		A SysUML tool customization shall offer a command that applies a catalog pattern to the selected elements:
		it creates the pattern instance and binds the selected elements to its roles.
		*/
		@Rationale { text = "Applying a pattern by hand means several redefinitions per role; a command makes the correct form the easy one, as the SysUML palettes do for single keywords."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-PAT-022'> patternQueries {
		doc
		/*
		Tooling shall answer from the model which patterns a design element takes part in and in which roles,
		which pattern instances apply a pattern, and which patterns address a given concern.
		*/
		@Rationale { text = "These questions are why patterns are recorded at all: they explain a design element to a reader and show the impact of changing a pattern."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-023'> spmsInterchange {
		doc
		/*
		SysUML shall import and export pattern definitions and pattern instances as SPMS XMI: at least the required
		Definitions package, and the Observations and Relationships packages where the model contains them.
		*/
		@Rationale { text = "Export and import of SPMS XMI is the conformance point of the standard; it connects SysUML models to pattern repositories and to analysis tools that report patterns and weaknesses in SPMS form."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-PAT-024'> spmsKerMLAlignment {
		doc
		/*
		The SysUML representation of patterns shall remain mappable to SPMS, and shall adopt the resolution of the
		SPMS 1.5 issues on KerML support (SPMS15-1, SPMS15-2) once it is published.
		*/
		@Rationale { text = "SPMS references UML Element and Property; until the revision says how KerML elements are referenced, interchange with SysML v2 models rests on an unstated bridge. SysUML can contribute its mapping and E22 evidence to that revision."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-PAT-025'> collaborationMapping {
		doc
		/*
		The UML 2.5.1 Collaboration and CollaborationUse shall map to the SysUML pattern definition and the
		instance-level pattern instance, including their role bindings and their constraints every_role and
		connectors, and the UML 2.x traceability shall record the mapping.
		*/
		@Rationale { text = "Collaborations are the one UML 2.5.1 concept whose traceability is PARTIAL with no SysUML construct; patterns are what collaborations were introduced for."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	package UseCases {
		doc
		/*
		UseCases: how architects, developers, reviewers and tool vendors define, apply, check and exchange patterns.

		Contents:
		- DefinePattern: an architect defines a pattern with typed roles, role collaboration, sections, concerns and
		  requirements, and relates it to other patterns.
		- ApplyPattern: an architect or developer applies a catalog pattern to a design and records the decision.
		- CheckPatternConformance: a reviewer checks that the pattern instances of a design conform to their
		  patterns.
		- UsePatternCatalog: a developer finds patterns and anti-patterns by concern, category and relationship.
		- ExchangePatterns: a tool vendor exchanges pattern definitions and detected instances with SPMS tools.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DefinePattern {
			doc
			/*
			A software architect or a language maintainer defines a pattern for a catalog: its roles with their
			types and multiplicities, how the roles work together, its documentation sections, the concerns it
			addresses and the requirements a correct application must meet, and its relationships to other
			patterns.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor maintainer : LanguageMaintainer;
			objective {
				doc /* The pattern can be applied and checked without reading prose to find out what its roles must provide. */
			}
		}

		use case def ApplyPattern {
			doc
			/*
			A software architect or developer applies a pattern from a catalog to a design, at type level for a
			class structure or at instance level for a configuration, binds the design elements to its roles,
			records the design decision as a requirement, and lets the pattern instance satisfy it.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Each pattern in the design is an explicit instance whose bindings and purpose a reader can follow. */
			}
		}

		use case def CheckPatternConformance {
			doc
			/*
			A reviewer checks the pattern instances of a design: every role is bound to an element of a conforming
			type that implements the role's contract, the role connections exist between the bound elements, and
			the pattern's requirements are satisfied.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			objective {
				doc /* A design that claims a pattern actually has its structure, or the review finding says where it does not. */
			}
		}

		use case def UsePatternCatalog {
			doc
			/*
			A software developer looks for a pattern that addresses a concern, compares related patterns and their
			variants, finds the anti-patterns that a review reported and the patterns that mitigate them, and sees
			which parts of the design already use a pattern.
			*/
			subject environment : UML3Environment;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* The developer chooses a pattern from its documented concerns and consequences instead of from memory. */
			}
		}

		use case def ExchangePatterns {
			doc
			/*
			A tool vendor exchanges pattern definitions and detected pattern instances between SysUML models and
			SPMS tools and repositories, including anti-pattern catalogs such as the CISQ weaknesses.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			objective {
				doc /* Patterns defined or found in one tool can be used in another without rewriting them. */
			}
		}

		#traces dependency from DefinePattern to 'UML3-PAT-001', 'UML3-PAT-002', 'UML3-PAT-003', 'UML3-PAT-004',
			'UML3-PAT-005', 'UML3-PAT-006', 'UML3-PAT-016';
		#traces dependency from ApplyPattern to 'UML3-PAT-007', 'UML3-PAT-008', 'UML3-PAT-009', 'UML3-PAT-010',
			'UML3-PAT-021', UML3RequirementModelingRequirements::'UML3-REQ-018';
		#traces dependency from CheckPatternConformance to 'UML3-PAT-011', 'UML3-PAT-012', 'UML3-PAT-013',
			'UML3-PAT-014', 'UML3-PAT-015';
		#traces dependency from UsePatternCatalog to 'UML3-PAT-017', 'UML3-PAT-018', 'UML3-PAT-020',
			'UML3-PAT-022';
		#traces dependency from ExchangePatterns to 'UML3-PAT-019', 'UML3-PAT-023', 'UML3-PAT-024',
			'UML3-PAT-025';
	}
}
