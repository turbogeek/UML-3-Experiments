package FixtureRefinementsWrongGroup {
	doc
	/*
	FixtureRefinementsWrongGroup: UML3-STR-001 applies to SysUML but also refines EXT-1 from the UML3 package. Expected: GROUP.
	*/
	private import FixtureExternalRequirements::*;

	package SysUMLAnswers {
		doc /* Answers by requirements that apply to SysUML. */
		@AppliesTo { implementations = ImplementationKind::sysUML; }
		#refinement dependency from UML3StructureRequirements::'UML3-STR-001' to 'EXT-1';
		#refinement dependency from UML3BehaviorRequirements::'UML3-BHV-001' to 'EXT-4';
	}

	package UML3Answers {
		doc /* Answers by requirements that apply to UML3. */
		@AppliesTo { implementations = ImplementationKind::uml3; }
		#refinement dependency from UML3ImplementationRequirements::'UML3-IMPL-002' to 'EXT-2';
		#refinement dependency from UML3StructureRequirements::'UML3-STR-001' to 'EXT-1';
	}

	package CompatibilityAnswers {
		doc /* Answers by requirements that apply to both implementations. */
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
		#refinement dependency from UML3ImplementationRequirements::'UML3-IMPL-005' to 'EXT-3';
	}

	comment QuestionPosition about 'EXT-4' /* The native behaviors are enough. */
}
