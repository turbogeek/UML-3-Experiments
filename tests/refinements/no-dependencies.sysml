package FixtureRefinementsNone {
	doc
	/*
	FixtureRefinementsNone: no refinement or deviation dependencies at all. Expected: tool error (exit code 2), since
	an empty set of answers means the parse failed, not that everything is covered.
	*/
	private import FixtureExternalRequirements::*;

	package SysUMLAnswers {
		doc /* Answers by requirements that apply to SysUML. */
		@AppliesTo { implementations = ImplementationKind::sysUML; }
	}
}
