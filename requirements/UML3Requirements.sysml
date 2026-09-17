package UML3Requirements {
	doc
	/*
	UML3Requirements: the requirements for UML3, the UML-level software modeling language built on SysML v2.

	The requirements are numbered "shall" statements grouped by area, in the style used to state the requirements
	for KerML and SysML v2. Each requirement carries its rationale, status, priority and verification method as
	standard SysML v2 metadata, and done requirements name their verification evidence and the library elements
	that realize them. Use cases (UML3UseCases) describe how practitioners use UML3 and trace the requirements
	they need. docs/REQUIREMENTS-GUIDE.md defines the rules; tools/check_requirements.py checks them and
	generates docs/UML3-Requirements.md.

	Contents:
	- Priority, PriorityKind: requirement priority (mandatory or optional).
	- Area packages: UML3CoreRequirements (CORE), UML3StructureRequirements (STR), UML3DataTypeRequirements (DT),
	  UML3BehaviorRequirements (BHV), UML3ExtensibilityRequirements (EXT), UML3VerificationRequirements (VER),
	  UML3ValidationRequirements (VAL), UML3ViewRequirements (VIEW), UML3ArchitectureRequirements (ARCH),
	  UML3DataModelingRequirements (DATA), UML3MessagingRequirements (MSG), UML3SecurityRequirements (SEC),
	  UML3TestingRequirements (TEST), UML3DevOpsRequirements (OPS), UML3GenerationRequirements (GEN),
	  UML3ReportRequirements (RPT), UML3LanguageRequirements (LANG), UML3AIRequirements (AI),
	  UML3SysMLInteropRequirements (SYS), each in its own file of requirements/.
	- UML3Actors (00-Actors.sysml): the roles and the use case subject; each area package has a nested UseCases package
	  whose use cases trace the requirements they need.
	References: SysML 7.21; SysML 7.25; SysML 7.27; docs/REQUIREMENTS-GUIDE.md.
	*/

	private import ScalarValues::*;

	enum def PriorityKind {
		doc
		/*
		The priority of a UML3 requirement, following the mandatory and optional requirements of the SysML v2
		request for proposals.
		*/
		enum mandatory {
			doc /* A conforming UML3 language definition and its libraries shall satisfy the requirement. */
		}
		enum optional {
			doc /* A conforming UML3 language definition may satisfy the requirement; it describes a recommended capability. */
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
}
