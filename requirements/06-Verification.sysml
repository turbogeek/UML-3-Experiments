package UML3VerificationRequirements {
	doc
	/*
	VER: requirements on verifying UML3 models and the UML3 tooling: standard well-formedness, name resolution,
	design rules and completeness, consistency of diagrams with their views, coverage of requirements by
	verification, the findings that checks report, and the regression and conformance testing of UML3 itself.
	Testing the software that a UML3 model describes is in UML3TestingRequirements (TEST).

	Contents:
	- Checks on a model: standardWellFormedness, nameResolution, designRules, portableDesignRules,
	  completenessChecks, viewDiagramConsistency, requirementVerificationCoverage.
	- Findings: findingDiagnostics, acceptedFindings.
	- Verification of UML3 and its tools: checkEffectiveness, requirementEvidence, toolingRegression,
	  implementationBaselines, conformanceTests.
	- UseCases: how architects, language maintainers and tool vendors verify UML3 models and tools.
	- Realization: the library elements that realize the done requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; SysML 7.24.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3Components::*;
	private import UML3Messaging::*;
	private import UML3Data::*;

	requirement <'UML3-VER-001'> standardWellFormedness {
		doc
		/*
		Verification of a UML3 model shall include every well-formedness check that KerML and SysML v2 define:
		syntax, name resolution, typing and the validation constraints of the specifications. UML3 checks shall
		add to these checks and shall not replace any of them.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite cameo; tools/run_tests.py suite cameo-probes.
		*/
		@Rationale { text = "A UML3 model is a SysML v2 model first; a verification that knows only UML3 rules would pass models that no conforming tool can load."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-002'> nameResolution {
		doc
		/*
		Verification shall resolve every name in a UML3 model (imports, types, specializations, redefinitions,
		keywords, feature chains and qualified names in expressions) against the model, the UML3 libraries and
		the SysML v2 standard library, and shall report each name that does not resolve, with its location.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite checker-calibration; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "The reference ANTLR validator accepts unresolved names, so a model can pass its syntax check and still fail to load in a tool or mean something else than intended."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-003'> designRules {
		doc
		/*
		UML3 shall define design rules that report models that are valid SysML v2 but inconsistent as software
		designs, for example a table without a primary key, a realization that does not redefine every abstract
		operation of its interface, or a provided port that is conjugated. Each rule shall have a stable
		identifier, a severity (error or warning) and a statement of the condition it reports.
		Verified by: tools/run_tests.py suite rules-tests; tools/run_tests.py suite rules-examples; tools/run_tests.py suite rules-library.
		*/
		@Rationale { text = "SysML v2 validation cannot know what a UML3 keyword promises, such as a key on every table; severities let errors stop a model while warnings only inform."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-004'> portableDesignRules {
		doc
		/*
		UML3 design rules shall be part of the UML3 definition in a machine-readable form that any conforming tool
		can evaluate, for example as constraint definitions in a UML3 library, and not only as code of one
		checker.
		*/
		@Rationale { text = "Rules that exist only in one checker are not part of the standard, and tools that implement them from prose would disagree about which UML3 models are correct."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-VER-005'> completenessChecks {
		doc
		/*
		Verification shall report, as warnings, elements that are valid but incomplete for their UML3 keyword: an
		entity or aggregate root without identity, a message type without payload, a topic or queue without
		quality of service, a database view without query text, and a required port of a part that is not
		connected.
		Verified by: tools/run_tests.py suite rules-tests; tools/run_tests.py suite rules-examples.
		*/
		@Rationale { text = "Incomplete designs are normal while modeling and must not block work, but they have to be visible before code, schemas or contracts are generated from them."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-006'> viewDiagramConsistency {
		doc
		/*
		Verification shall report a diagram or table that presents an element its view does not select through
		expose and filter, or that omits an element its view selects.
		*/
		@Rationale { text = "A diagram can replace a UML diagram only if it shows what its view selects; manual additions and removals would otherwise make diagrams disagree with the model unnoticed."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-007'> requirementVerificationCoverage {
		doc
		/*
		Verification shall report each requirement of a UML3 model that no verification case, analysis or recorded
		inspection verifies, and each verification case that verifies no requirement.
		*/
		@Rationale { text = "Unverified requirements and verification without a purpose are the two gaps that traceability from requirements to verification exists to expose."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-VER-008'> findingDiagnostics {
		doc
		/*
		Each verification finding shall identify the check that produced it, its location (the file and line or
		the qualified name of the element) and the problem it reports. Findings shall be available both as
		readable text and as a machine-readable report.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite rules-tests; tools/run_tests.py suite docs.
		*/
		@Rationale { text = "People fix findings from their text, while regression suites, editors and AI assistants read them from reports; both need the same check identity and location."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-009'> acceptedFindings {
		doc
		/*
		A modeler shall be able to accept a warning for a specific element with a recorded justification that is
		part of the model, and verification shall report accepted findings separately from new ones.
		*/
		@Rationale { text = "Some warnings are correct but deliberate, such as stacked keywords whose order was chosen; unless their acceptance is recorded they hide new findings and are reviewed again on every run."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-010'> checkEffectiveness {
		doc
		/*
		Every UML3 check shall be demonstrated by test models that make it report each kind of finding it targets
		and by a clean control model that it accepts. A check of names or keyword use shall also report no
		findings on the official SysML v2 validation, example and training models.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite rules-tests; tools/run_tests.py suite docs; tools/run_tests.py suite checker-calibration.
		*/
		@Rationale { text = "A check that has never been seen to fail may check nothing, and a check that flags valid SysML v2 drives modelers away from the standard."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-011'> requirementEvidence {
		doc
		/*
		Each UML3 requirement shall state its verification method, and each requirement that is done or to be
		confirmed shall name the evidence that verifies it: a regression suite, an experiment or a repository
		file. Verification shall report evidence that does not resolve.
		Verified by: tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "A requirement marked done without checkable evidence is a claim, not a result; resolving the evidence keeps the claim true as suites and files change."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-012'> toolingRegression {
		doc
		/*
		The UML3 libraries and tools (checkers, importers, exporters and generators) shall be verified by an
		automated regression suite that runs unattended once its tools are available, records every result in a
		machine-readable report and fails when a result differs from the expected one.
		Verified by: tools/run_tests.py; tools/run_tests.py suite idl-corpus; tools/run_tests.py suite idl-codegen.
		*/
		@Rationale { text = "UML3 is defined by libraries and checked by tools that change together; only an unattended regression shows that a change to one did not break the other."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-013'> implementationBaselines {
		doc
		/*
		Where verification of UML3 depends on a SysML v2 implementation, each known deviation of that
		implementation (a valid construct it rejects, an invalid construct it accepts, or keyword semantics it
		does not apply) shall be recorded with evidence, and the regression suite shall fail when the
		implementation no longer behaves as recorded.
		Verified by: tools/run_tests.py suite validator-gaps; tools/run_tests.py suite cameo-probes; tests/validator-known-gaps.json.
		*/
		@Rationale { text = "Implementations deviate from KerML and SysML v2, for example by applying only the first semantic keyword; recorded deviations keep workarounds honest and show when a fix makes them unnecessary."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-VER-014'> conformanceTests {
		doc
		/*
		UML3 shall provide conformance test models for each conformance point: valid models that a conforming
		implementation shall accept and invalid models that it shall reject, each stating its expected outcome in
		the model in a form that does not depend on a particular checker.
		*/
		@Rationale { text = "Implementations can only demonstrate conformance against shared tests; the current negative and rule tests expect the finding codes of the UML3 checkers, which other tools do not produce."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how architects, language maintainers and tool vendors verify UML3 models and tools.

		Contents:
		- VerifyUML3DesignModel: an architect or developer verifies a design model before it is shared or used
		  for generation.
		- QualifyUML3Tooling: a language maintainer shows that a change to the libraries or tools breaks nothing.
		- ClaimUML3VerificationConformance: a tool vendor shows that a tool verifies UML3 models as the standard
		  requires.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def VerifyUML3DesignModel {
			doc
			/*
			A software architect or developer verifies a UML3 design model: SysML v2 well-formedness, names,
			keyword applicability, design rules and completeness, the verification of its requirements and the
			consistency of its diagrams. The errors are fixed and deliberate warnings are accepted with a reason.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* The model has no verification errors, and every remaining warning is either fixed or accepted with a reason. */
			}
		}

		use case def QualifyUML3Tooling {
			doc
			/*
			A language maintainer changes a UML3 library or tool and runs the regression suite: every check is
			shown to fire and to accept valid models, recorded implementation deviations still hold, and every
			done requirement still resolves its evidence.
			*/
			subject environment : UML3Environment;
			actor maintainer : LanguageMaintainer;
			objective {
				doc /* The change is released only when the regression passes and every difference from a baseline is explained. */
			}
		}

		use case def ClaimUML3VerificationConformance {
			doc
			/*
			A tool vendor runs the UML3 conformance test models in a SysML v2 tool that implements the UML3 checks
			and design rules, and compares the tool's findings with the outcomes the tests state.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			objective {
				doc /* The tool reports the findings the conformance tests expect, in a form that users and other tools can read. */
			}
		}

		#traces dependency from VerifyUML3DesignModel to 'UML3-VER-001', 'UML3-VER-002', 'UML3-VER-003', 'UML3-VER-005',
			'UML3-VER-006', 'UML3-VER-007', 'UML3-VER-008', 'UML3-VER-009', UML3CoreRequirements::'UML3-CORE-008';
		#traces dependency from QualifyUML3Tooling to 'UML3-VER-010', 'UML3-VER-011', 'UML3-VER-012', 'UML3-VER-013',
			UML3CoreRequirements::'UML3-CORE-003', UML3CoreRequirements::'UML3-CORE-010';
		#traces dependency from ClaimUML3VerificationConformance to 'UML3-VER-001', 'UML3-VER-004', 'UML3-VER-008',
			'UML3-VER-014', UML3CoreRequirements::'UML3-CORE-011';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done and tbc VER requirements.

		Contents:
		- #realizes dependencies from UML3 library elements to VER requirements. A check that tools perform is
		  realized by the library definitions the check is defined on.
		*/
		#realizes dependency from UML3Core to 'UML3-VER-001';
		#realizes dependency from UML3Core to 'UML3-VER-002';
		#realizes dependency from UML3Data::table to 'UML3-VER-003';
		#realizes dependency from UML3Core::interfaceType to 'UML3-VER-003';
		#realizes dependency from UML3Components::provided to 'UML3-VER-003';
		#realizes dependency from UML3Data::entity to 'UML3-VER-005';
		#realizes dependency from UML3Messaging::messageType to 'UML3-VER-005';
		#realizes dependency from UML3Messaging::QualityOfService to 'UML3-VER-005';
		#realizes dependency from UML3Data::dbView to 'UML3-VER-005';
		#realizes dependency from UML3Components::required to 'UML3-VER-005';
		#realizes dependency from UML3Requirements to 'UML3-VER-011';
		#realizes dependency from UML3Core to 'UML3-VER-012';
		#realizes dependency from UML3IDL to 'UML3-VER-012';
		#realizes dependency from UML3Core to 'UML3-VER-013';
	}
}
