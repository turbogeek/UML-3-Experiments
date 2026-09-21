package DogFoodTraceability {
	doc
	/*
	DogFoodTraceability: which requirements the elements of the effort satisfy today, and which they are
	allocated to because they are responsible for them but not built yet (UML3-REQ-010, UML3-REQ-011).

	Contents:
	- effort: the modeling languages and the verification toolchain, with the satisfy relationships of the
	  toolchain and the allocations of the planned components.
	References: requirements/06-Verification.sysml; requirements/22-Implementations.sysml; SysML 7.21; SysML 7.15.
	*/
	private import DogFoodImplementations::*;
	private import DogFoodToolchain::*;

	part effort {
		doc /* The effort as one part: what it builds and what verifies it. */
		part languages : ModelingLanguages {
			doc /* SysUML, UML3 and the transformation. */
		}
		part toolchain : VerificationToolchain {
			doc /* The checkers, the harness and the test runner. */
		}
		comment Satisfaction about toolchain
			/*
			Satisfaction. The checkers exist and run in every suite run, so they satisfy the verification
			requirements they implement: syntax and well-formedness, names, design rules, evidence of requirements,
			and the unattended regression.
			*/
		satisfy UML3VerificationRequirements::'UML3-VER-001' by toolchain.cameoCheck;
		satisfy UML3VerificationRequirements::'UML3-VER-002' by toolchain.nameChecker;
		satisfy UML3VerificationRequirements::'UML3-VER-003' by toolchain.ruleChecker;
		satisfy UML3VerificationRequirements::'UML3-VER-011' by toolchain.requirementChecker;
		satisfy UML3VerificationRequirements::'UML3-VER-012' by toolchain.runner;
		comment Allocation about languages
			/*
			Allocation. UML3 and the transformation do not exist yet, so they carry the responsibility for their
			requirements as allocations; a satisfy relationship would claim what is not built.
			*/
		allocate UML3ImplementationRequirements::'UML3-IMPL-002' to languages.uml3;
		allocate UML3ImplementationRequirements::'UML3-IMPL-005' to languages.transformation;
		allocate UML3ImplementationRequirements::'UML3-IMPL-007' to languages.transformation;
	}
}
