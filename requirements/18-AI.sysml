package UML3AIRequirements {
	doc
	/*
	AI: requirements on artificial intelligence with and in SysUML: AI assistants that draft, check, review and
	explain SysUML models under human control, the machine-readable feedback that validation loops need, the
	provenance, review and guardrails for AI-produced model content, and the modeling of machine-learning and
	agent systems as SysUML and SysML v2 elements.

	Contents:
	- AI-assisted modeling: sameChecksForAIContent, machineReadableDiagnostics, draftingTracedToSource,
	  modelReviewAndExplanation.
	- Provenance and guardrails: aiProvenanceMetadata, reviewBeforeBaseline, reversibleAutomatedChanges,
	  sensitiveContentProtection.
	- Modeling AI systems: mlComponentModeling, agentSystemModeling, aiComponentTraceability, mlReproducibility.
	- UseCases: how developers, reviewers, architects and AI assistants use these capabilities.
	- Realization: the elements that realize the done requirements.
	References: docs/REQUIREMENTS-GUIDE.md; SysML 7.21; SysML 7.24; SysML 7.27.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-AI-001'> sameChecksForAIContent {
		doc
		/*
		Model content that an AI assistant drafts or changes shall be checked with the same SysUML conformance
		checks as content written by people: syntax, name resolution, keyword applicability, documentation and
		design rules. The checks shall run on the textual notation without the user interface of a modeling tool,
		so that the assistant can run them before it proposes the content.
		Verified by: tools/run_tests.py suite requirements; tools/run_tests.py suite docs; tools/run_tests.py suite negative.
		*/
		@Rationale { text = "AI assistants produce plausible but wrong models; applying the human quality bar automatically and before review catches errors a reviewer would otherwise have to find."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-AI-002'> machineReadableDiagnostics {
		doc
		/*
		SysUML checkers, importers and generators shall report their results in a documented machine-readable form,
		with a finding or result code, the file and line or the model element concerned, and a message for each
		finding, and shall state overall success or failure, so that an AI assistant can repair a model in an
		automated validation loop.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite rules-tests; tools/run_tests.py suite idl-import; tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "An assistant that interprets free-form console output misreads failures; codes, locations and JSON reports make the validate, fix and revalidate loop reliable and let a harness decide pass or fail without a person."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-AI-003'> draftingTracedToSource {
		doc
		/*
		When an AI assistant drafts SysUML model content from natural-language sources such as requirements,
		interview notes or documentation, each drafted element shall be traced to the source passage it was
		derived from, and content without a source shall be marked as a proposal of the assistant.
		*/
		@Rationale { text = "A reviewer can judge a drafted model only against what the stakeholders said, and traces to the sources show where the assistant interpreted or invented content."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-AI-004'> modelReviewAndExplanation {
		doc
		/*
		An AI assistant that reviews or explains a SysUML model shall base each finding or explanation on identified
		model elements, their documentation, rule codes or requirements, and shall cite them, so that a person
		can check each statement against the model.
		*/
		@Rationale { text = "Explanations without references cannot be checked and may contain invented facts; citing resolvable model elements and rules makes AI review as verifiable as a human review."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-AI-005'> aiProvenanceMetadata {
		doc
		/*
		SysUML shall define metadata that records, for a model element, that its content was created or changed by
		an AI assistant, which assistant and model version did so, when and in response to which request, and the
		human review status of the content (unreviewed, accepted, changed or rejected) with its reviewer.
		*/
		@Rationale { text = "Accountability for a design stays with people; without provenance nobody can tell which parts of a model were machine-proposed and whether anyone checked them, which audits increasingly ask for."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-AI-006'> reviewBeforeBaseline {
		doc
		/*
		A model baseline, a release or a set of generated artifacts shall not include AI-produced content whose
		review status is unreviewed or rejected, and SysUML tooling shall report such content before the baseline
		is created.
		*/
		@Rationale { text = "A guardrail at the baseline keeps unreviewed AI output out of released designs and generated code without slowing down drafting and exploration."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-AI-007'> reversibleAutomatedChanges {
		doc
		/*
		Each change that an AI assistant or another automated tool makes to a model in a modeling tool shall be
		applied as an identifiable command that can be undone on its own, without undoing changes made by people
		or by other tools. An automated run shall stop, instead of undoing, when it finds a change it did not make.
		Verified by: tools/run_tests.py suite cameo; E07.
		*/
		@Rationale { text = "Automated tools act fast and at scale; if their changes cannot be isolated and reverted, one wrong run can destroy work that people did in the same model, as the E07 incident showed."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-AI-008'> sensitiveContentProtection {
		doc
		/*
		Model content whose data classification or project policy forbids disclosure shall not be sent to an AI
		service outside the permitted trust boundary, and SysUML tooling shall report each element it withheld from
		the assistant.
		*/
		@Rationale { text = "Models describe personal data, security controls and proprietary designs; sending them to external AI services can breach confidentiality, privacy law and export control."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-AI-009'> mlComponentModeling {
		doc
		/*
		SysUML shall provide library concepts for machine-learning systems: trained models with their version,
		framework, inputs, outputs and intended use; datasets with their origin, license, version and data
		classification; training, evaluation and inference pipelines; and evaluation results with their metrics
		and the datasets they were measured on.
		*/
		@Rationale { text = "Machine-learning components are now ordinary parts of software systems, and because their behavior comes from data and training rather than code, architecture models have to show models, data and pipelines explicitly."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-AI-010'> agentSystemModeling {
		doc
		/*
		SysUML shall provide library concepts for AI agent systems: agents, the language models they use, prompts
		and prompt templates, the tools and services an agent may call with its permissions, memory and knowledge
		sources, and the guardrail policies that constrain the agent.
		*/
		@Rationale { text = "Agent systems delegate decisions to language models that call tools, so their permissions, prompts and guardrails are architecture decisions that need the same review and traceability as services and interfaces."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-AI-011'> aiComponentTraceability {
		doc
		/*
		AI components, datasets, prompts and agents shall be traceable, with native SysML v2 relationships, to the
		requirements they satisfy, to the risks that concern them and to the evaluation results that verify them.
		*/
		@Rationale { text = "AI regulations and safety standards ask for evidence that each AI function is justified, risk-assessed and evaluated, and traceability in the model provides that evidence where the design is made."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-AI-012'> mlReproducibility {
		doc
		/*
		For each trained model SysUML shall record what is needed to reproduce it: the versions of the training
		code, the datasets and the base model, the hyperparameters, the random seeds and the training environment.
		*/
		@Rationale { text = "A model that cannot be retrained to the same result cannot be debugged, audited or safely updated, and its data and settings are not visible in the code."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	package UseCases {
		doc
		/*
		UseCases: how people and AI assistants work together on SysUML models, and how AI systems are modeled.

		Contents:
		- DraftModelWithAIAssistant: an AI assistant drafts and checks model content for a software developer.
		- ReviewAIProducedContent: a reviewer reviews AI-produced content and baselines only reviewed content.
		- ModelAIEnabledSystem: an architect, a data modeler and a security engineer model a system that uses AI.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def DraftModelWithAIAssistant {
			doc
			/*
			A software developer asks an AI assistant to draft SysUML model content from requirements text. The
			assistant drafts the content, runs the SysUML checks, repairs the findings in a bounded number of cycles
			and proposes the result, which enters the model only after the developer has reviewed it.
			*/
			subject environment : UML3Environment;
			actor assistant : AIAssistant;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* Drafted content passes the same checks as human content, is traced to its sources and enters the model reversibly. */
			}
		}

		use case def ReviewAIProducedContent {
			doc
			/*
			A reviewer uses an AI assistant to review and explain a model, checks the cited elements, records a
			review decision for each AI-produced element and creates a baseline that excludes unreviewed content.
			*/
			subject environment : UML3Environment;
			actor reviewer : Reviewer;
			actor assistant : AIAssistant;
			objective {
				doc /* Every AI-produced element in the baseline has been reviewed by a person, and every AI finding can be checked. */
			}
		}

		use case def ModelAIEnabledSystem {
			doc
			/*
			A software architect models a system that uses machine-learning models and agents, a data modeler
			describes the datasets, and a security engineer traces the AI components to risks, requirements and
			evaluations and controls what model content may be sent to AI services.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor dataModeler : DataModeler;
			actor security : SecurityEngineer;
			objective {
				doc /* The AI parts of the system are designed, traceable, reproducible and protected like the rest of its software. */
			}
		}

		#traces dependency from DraftModelWithAIAssistant to 'UML3-AI-001', 'UML3-AI-002', 'UML3-AI-003', 'UML3-AI-005',
			'UML3-AI-007', 'UML3-AI-008', UML3CoreRequirements::'UML3-CORE-007', UML3CoreRequirements::'UML3-CORE-008';
		#traces dependency from ReviewAIProducedContent to 'UML3-AI-002', 'UML3-AI-004', 'UML3-AI-005', 'UML3-AI-006',
			'UML3-AI-007', 'UML3-AI-008';
		#traces dependency from ModelAIEnabledSystem to 'UML3-AI-008', 'UML3-AI-009', 'UML3-AI-010', 'UML3-AI-011',
			'UML3-AI-012';
	}

	package Realization {
		doc
		/*
		Realization: the elements that realize the done AI requirements.

		Contents:
		- #realizes dependencies to AI requirements. The SysUML checkers and tools are not modeled as elements of
		  their own, so a tool capability is realized by UML3Environment, the element that represents them.
		*/
		#realizes dependency from UML3Actors::UML3Environment to 'UML3-AI-002';
	}
}
