package UML3Requirements {
	doc
	/*
	UML3Requirements: the requirements for UML-level software modeling in two implementations of one set of
	concepts.

	- SysUML models software in SysML v2: SysML v2 libraries and semantic keywords, with no extension of SysML v2.
	  It is the implementation that exists today; its libraries are in library/ (packages UML3Core, UML3Types, ...).
	- UML3 is a language that extends and subsets KerML as SysML v2 does, with its own textual syntax, grammar and
	  standard library. It is the next step, and a lossless transformation shall connect it with SysUML
	  (UML3ImplementationRequirements).

	The requirements are numbered "shall" statements grouped by area, in the style used to state the requirements
	for KerML and SysML v2. The prefix UML3- of the identifiers names this requirement set, not the implementation.
	Each requirement carries its rationale, status, priority and verification method as standard SysML v2 metadata
	and, where it is not a SysUML requirement, the implementations it applies to (AppliesTo). Done requirements name
	their verification evidence and the library elements that realize them. Use cases describe how practitioners
	work and trace the requirements they need. docs/REQUIREMENTS-GUIDE.md defines the rules;
	tools/check_requirements.py checks them and generates docs/UML3-Requirements.md.

	Contents:
	- Priority, PriorityKind: requirement priority (mandatory or optional).
	- AppliesTo, ImplementationKind: the implementations a requirement applies to (SysUML when absent).
	- Area packages: UML3CoreRequirements (CORE), UML3StructureRequirements (STR), UML3DataTypeRequirements (DT),
	  UML3BehaviorRequirements (BHV), UML3ExtensibilityRequirements (EXT), UML3VerificationRequirements (VER),
	  UML3ValidationRequirements (VAL), UML3ViewRequirements (VIEW), UML3ArchitectureRequirements (ARCH),
	  UML3DataModelingRequirements (DATA), UML3MessagingRequirements (MSG), UML3SecurityRequirements (SEC),
	  UML3TestingRequirements (TEST), UML3DevOpsRequirements (OPS), UML3GenerationRequirements (GEN),
	  UML3ReportRequirements (RPT), UML3LanguageRequirements (LANG), UML3AIRequirements (AI),
	  UML3SysMLInteropRequirements (SYS), UML3RequirementModelingRequirements (REQ), UML3PatternRequirements
	  (PAT), UML3ImplementationRequirements (IMPL), each in its own file of requirements/.
	- UML3Actors (00-Actors.sysml): the roles and the use case subject; each area package has a nested UseCases package
	  whose use cases trace the requirements they need.
	References: SysML 7.21; SysML 7.25; SysML 7.27; docs/REQUIREMENTS-GUIDE.md.
	*/

	private import ScalarValues::*;

	enum def PriorityKind {
		doc
		/*
		The priority of a requirement, following the mandatory and optional requirements of the SysML v2 request for
		proposals.
		*/
		enum mandatory {
			doc /* A conforming implementation of the requirement's AppliesTo shall satisfy the requirement. */
		}
		enum optional {
			doc /* A conforming implementation may satisfy the requirement; it describes a recommended capability. */
		}
	}

	metadata def Priority {
		doc
		/*
		The priority of a requirement.

		Usage: @Priority { level = PriorityKind::mandatory; }
		Rationale: SysML v2 ModelingMetadata has status, rationale and risk, but no priority.
		References: SysML 7.27.
		*/
		attribute level : PriorityKind {
			doc /* Mandatory or optional. */
		}
	}

	enum def ImplementationKind {
		doc /* The two implementations of UML-level software modeling that a requirement can apply to. */
		enum sysUML {
			doc /* SysUML: software modeled in SysML v2 with SysML v2 libraries and semantic keywords; the implementation in use. */
		}
		enum uml3 {
			doc /* UML3: a language that extends and subsets KerML with its own textual syntax and grammar; the next step. */
		}
	}

	metadata def AppliesTo {
		doc
		/*
		The implementations a requirement applies to. A requirement without it applies to SysUML, which is what the
		requirements describe unless they say otherwise.

		Usage: @AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
		Rationale: SysUML and UML3 share their concepts but differ in syntax, library base and tooling; saying which
		implementation a requirement binds keeps a UML3 requirement from being read as a promise about SysUML today.
		References: SysML 7.27.
		*/
		attribute implementations : ImplementationKind[1..2] {
			doc /* One or both implementations. */
		}
	}
}
